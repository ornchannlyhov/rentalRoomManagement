const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const TelegramBot = require('node-telegram-bot-api');
const mongoose = require('mongoose');
const cron = require('node-cron');
const express = require('express');
const cors = require('cors');

// --- Mongoose Model ---
const usageSchema = new mongoose.Schema({
    chatId: { type: Number, required: true },
    phoneNumber: { type: String, required: true },
    language: { type: String, required: true },
    electricityUsage: { type: Number, required: true },
    waterUsage: { type: Number, required: true },
    date: { type: Date, default: Date.now }
});

const Usage = mongoose.model('Usage', usageSchema);

// --- Connect to MongoDB ---
mongoose.connect(process.env.MONGODB_URI)
    .then(() => console.log('Connected to MongoDB'))
    .catch(err => console.error('MongoDB connection error:', err));

// --- Telegram Bot ---
const bot = new TelegramBot(process.env.BOT_TOKEN, { polling: true });
const userSessions = new Map();
const usersToRemind = new Set();


// --- Phone Number Conversion Function ---
function convertToLocalFormat(phoneNumber) {
    // Remove any spaces, dashes, or other formatting
    let cleaned = phoneNumber.replace(/[\s\-\(\)]/g, '');

    // Convert Cambodia international format (+855) to local format (0)
    if (cleaned.startsWith('+855')) {
        return '0' + cleaned.substring(4);
    }

    // Convert other common formats
    if (cleaned.startsWith('855')) {
        return '0' + cleaned.substring(3);
    }

    // If it already starts with 0, return as is
    if (cleaned.startsWith('0')) {
        return cleaned;
    }

    // For other formats, assume it needs 0 prefix if it's 8-9 digits
    if (/^\d{8,9}$/.test(cleaned)) {
        return '0' + cleaned;
    }

    // Return original if no conversion needed
    return cleaned;
}

// --- Texts ---
const texts = {
    english: {
        welcome: 'Welcome! Please send /start to begin.',
        start: 'Hello! Welcome to Utility Tracker Bot. I will remind you monthly to submit your utility usage.',
        language: 'Please choose your preferred language:',
        phone: 'Please share your phone number by clicking the button below:',
        phoneManual: 'Or you can type your phone number manually:',
        electricity: 'Please enter this month\'s electricity usage (numbers only). Example: 150',
        water: 'Please enter this month\'s water usage (numbers only). Example: 25',
        invalidNumber: 'Please enter a valid number.',
        invalidPhone: 'Please enter a valid phone number.',
        success: 'Thank you! Your usage data has been saved successfully.',
        error: 'An error occurred. Please try again.',
        reminder: '🔔 Reminder: Rent is due! Please submit your utility usage for this month.',
        phoneReceived: 'Great! I received your phone number. Now let\'s set your language preference.',
        skipPhone: 'Skip phone sharing'
    },
    khmer: {
        welcome: 'សូមស្វាគមន៍! សូមផ្ញើ /start ដើម្បីចាប់ផ្តើម។',
        start: 'សួស្តី! សូមស្វាគមន៍មកកាន់ប្រព័ន្ធតាមដានការប្រើប្រាស់ឧបករណ៍។ ខ្ញុំនឹងរំលឹកអ្នករាល់ខែដើម្បីបញ្ជូនការប្រើប្រាស់របស់អ្នក។',
        language: 'សូមជ្រើសរើសភាសាដែលអ្នកចូលចិត្ត:',
        phone: 'សូមចែករំលែកលេខទូរស័ព្ទរបស់អ្នកដោយចុចលើប៊ូតុងខាងក្រោម:',
        phoneManual: 'ឬអ្នកអាចវាយលេខទូរស័ព្ទរបស់អ្នកដោយផ្ទាល់:',
        electricity: 'សូមបញ្ចូលការប្រើប្រាស់ភ្លើងរបស់ខែនេះ (តួលេខតែប៉ុណ្ណោះ)។ ឧទាហរណ៍: 150',
        water: 'សូមបញ្ចូលការប្រើប្រាស់ទឹករបស់ខែនេះ (តួលេខតែប៉ុណ្ណោះ)។ ឧទាហរណ៍: 25',
        invalidNumber: 'សូមបញ្ចូលលេខដែលត្រឹមត្រូវ។',
        invalidPhone: 'សូមបញ្ចូលលេខទូរស័ព្ទដែលត្រឹមត្រូវ។',
        success: 'សូមអរគុណ! ទិន្នន័យការប្រើប្រាស់របស់អ្នកត្រូវបានរក្សាទុកដោយជោគជ័យ។',
        error: 'មានកំហុសកើតឡើង។ សូមព្យាយាមម្តងទៀត។',
        reminder: '🔔 ការរំលឹក: ថ្ងៃបង់ថ្លៃខ្ចីដល់ហើយ! សូមបញ្ជូនការប្រើប្រាស់ឧបករណ៍របស់អ្នកសម្រាប់ខែនេះ។',
        phoneReceived: 'ល្អណាស់! ខ្ញុំបានទទួលលេខទូរស័ព្ទរបស់អ្នក។ ឥឡូវសូមកំណត់ការចូលចិត្តភាសារបស់អ្នក។',
        skipPhone: 'រំលងការចែករំលែកទូរស័ព្ទ'
    }
};

// --- Keyboards ---
const languageKeyboard = {
    reply_markup: {
        keyboard: [[{ text: '🇰🇭 ខ្មែរ (Khmer)' }, { text: '🇺🇸 English' }]],
        resize_keyboard: true,
        one_time_keyboard: true
    }
};

// Phone sharing keyboard
const phoneKeyboard = {
    reply_markup: {
        keyboard: [
            [{ text: '📱 Share Phone Number', request_contact: true }],
            [{ text: 'Skip phone sharing' }]
        ],
        resize_keyboard: true,
        one_time_keyboard: true
    }
};

// --- Cron job for monthly reminder ---
cron.schedule('0 0 1 * *', () => {
    console.log('Sending monthly reminders...');
    usersToRemind.forEach(chatId => {
        const session = userSessions.get(chatId);
        if (session) {
            const t = texts[session.language];
            bot.sendMessage(chatId, t.reminder);
            session.state = 'electricity';
            bot.sendMessage(chatId, t.electricity);
        }
    });
});

// --- Telegram Handlers ---
bot.onText(/\/start/, (msg) => {
    const chatId = msg.chat.id;
    const session = { state: 'phone', language: 'english', data: {} };
    userSessions.set(chatId, session);
    usersToRemind.add(chatId);

    const t = texts[session.language];
    bot.sendMessage(chatId, t.start);

    // Always start by asking for phone number
    bot.sendMessage(chatId, t.phone, phoneKeyboard);
});

// Handle contact sharing
bot.on('contact', async (msg) => {
    const chatId = msg.chat.id;
    const session = userSessions.get(chatId);

    if (!session) {
        bot.sendMessage(chatId, texts.english.welcome);
        return;
    }

    if (session.state === 'phone') {
        const phoneNumber = msg.contact.phone_number;
        // Convert to local format (e.g., +855 -> 0)
        const localPhoneNumber = convertToLocalFormat(phoneNumber);
        session.data.phoneNumber = localPhoneNumber;

        const t = texts[session.language];
        bot.sendMessage(chatId, `${t.phoneReceived}`, { reply_markup: { remove_keyboard: true } });

        // After getting phone, always ask for language
        session.state = 'language';
        bot.sendMessage(chatId, t.language, languageKeyboard);
    }
});

bot.on('message', async (msg) => {
    const chatId = msg.chat.id;
    const text = msg.text;

    // Skip if it's a contact message (handled separately)
    if (msg.contact) return;

    const session = userSessions.get(chatId);
    if (!session) {
        if (text !== '/start') bot.sendMessage(chatId, texts.english.welcome);
        return;
    }

    const t = texts[session.language];

    switch (session.state) {
        case 'phone': return handlePhoneInput(chatId, text, session, t);
        case 'language': return handleLanguageSelection(chatId, text, session, t);
        case 'electricity': return handleElectricityInput(chatId, text, session, t);
        case 'water': return handleWaterInput(chatId, text, session, t);
    }
});

// --- Helper Functions ---
function handlePhoneInput(chatId, text, session, t) {
    // Handle skip phone sharing
    if (text === 'Skip phone sharing' || text === 'រំលងការចែករំលែកទូរស័ព្ទ') {
        session.data.phoneNumber = 'Not provided';
        session.state = 'language';
        bot.sendMessage(chatId, t.language, languageKeyboard);
        return;
    }

    // Convert to local format and validate
    const localPhoneNumber = convertToLocalFormat(text);

    // Updated regex for Cambodian phone numbers (starting with 0)
    const phoneRegex = /^0\d{8,9}$/;
    if (!phoneRegex.test(localPhoneNumber)) {
        bot.sendMessage(chatId, t.invalidPhone);
        bot.sendMessage(chatId, t.phoneManual);
        return;
    }

    session.data.phoneNumber = localPhoneNumber;
    session.state = 'language';
    bot.sendMessage(chatId, t.phoneReceived, { reply_markup: { remove_keyboard: true } });
    bot.sendMessage(chatId, t.language, languageKeyboard);
}

function handleLanguageSelection(chatId, text, session, t) {
    let languageChanged = false;

    if (text.includes('English')) {
        session.language = 'english';
        languageChanged = true;
    } else if (text.includes('ខ្មែរ') || text.includes('Khmer')) {
        session.language = 'khmer';
        languageChanged = true;
    } else {
        // Invalid selection, ask again
        return bot.sendMessage(chatId, t.language, languageKeyboard);
    }

    // Use the new language for subsequent messages
    const tNew = texts[session.language];
    session.state = 'electricity';
    bot.sendMessage(chatId, tNew.electricity, { reply_markup: { remove_keyboard: true } });
}

function handleElectricityInput(chatId, text, session, t) {
    const electricity = parseFloat(text);
    if (isNaN(electricity) || electricity < 0) {
        return bot.sendMessage(chatId, t.invalidNumber);
    }
    session.data.electricityUsage = electricity;
    session.state = 'water';
    bot.sendMessage(chatId, t.water);
}

async function handleWaterInput(chatId, text, session, t) {
    const water = parseFloat(text);
    if (isNaN(water) || water < 0) {
        return bot.sendMessage(chatId, t.invalidNumber);
    }
    session.data.waterUsage = water;

    try {
        const usage = new Usage({
            chatId,
            phoneNumber: session.data.phoneNumber,
            language: session.language,
            electricityUsage: session.data.electricityUsage,
            waterUsage: session.data.waterUsage,
            date: new Date()
        });
        await usage.save();
        bot.sendMessage(chatId, t.success);

        // Reset session for next month
        session.state = 'completed';
        session.data.electricityUsage = null;
        session.data.waterUsage = null;

    } catch (error) {
        console.error('Error saving data:', error);
        bot.sendMessage(chatId, t.error);
    }
}

// --- Polling error handling ---
bot.on('polling_error', console.error);

/// --- Express Server ---
const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// API Key Middleware
const apiKeyAuth = (req, res, next) => {
    const apiKey = req.headers['x-api-key'] || req.query.apiKey;

    if (!apiKey) {
        return res.status(401).json({
            success: false,
            message: 'API key is required'
        });
    }

    if (apiKey !== process.env.API_KEY) {
        return res.status(403).json({
            success: false,
            message: 'Invalid API key'
        });
    }

    next();
};

// Apply API key authentication to all usage routes
app.use('/api/usage', apiKeyAuth);

// Get usage for current month
app.get('/api/usage/current-month', async (req, res) => {
    try {
        const now = new Date();
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
        const usageData = await Usage.find({ date: { $gte: startOfMonth, $lte: endOfMonth } }).sort({ date: -1 });
        res.json({
            success: true,
            data: usageData,
            period: {
                start: startOfMonth,
                end: endOfMonth,
                month: now.toLocaleString('default', { month: 'long' }),
                year: now.getFullYear()
            },
            count: usageData.length
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, message: 'Failed to fetch usage data', error: error.message });
    }
});

// Get usage for a specific month
app.get('/api/usage/:year/:month', async (req, res) => {
    try {
        const year = parseInt(req.params.year);
        const month = parseInt(req.params.month) - 1;
        if (isNaN(year) || isNaN(month) || month < 0 || month > 11) {
            return res.status(400).json({ success: false, message: 'Invalid year or month parameter' });
        }

        const startOfMonth = new Date(year, month, 1);
        const endOfMonth = new Date(year, month + 1, 0, 23, 59, 59, 999);
        const usageData = await Usage.find({ date: { $gte: startOfMonth, $lte: endOfMonth } }).sort({ date: -1 });

        res.json({
            success: true,
            data: usageData,
            period: {
                start: startOfMonth,
                end: endOfMonth,
                month: startOfMonth.toLocaleString('default', { month: 'long' }),
                year
            },
            count: usageData.length
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, message: 'Failed to fetch usage data', error: error.message });
    }
});

// Health check endpoint (no API key required)
app.get('/health', (req, res) => {
    res.json({
        success: true,
        message: 'Server is running',
        timestamp: new Date().toISOString()
    });
});

app.listen(PORT, () => console.log(`Server is running on port ${PORT}`));
console.log('Bot is running...');