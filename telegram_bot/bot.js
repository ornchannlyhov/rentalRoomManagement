const TelegramBot = require('node-telegram-bot-api');
const cron = require('node-cron');
const connectDB = require('./db');

// Import Mongoose Models
const Usage = require('./models/Usage');
const Receipt = require('./models/Receipt');
const User = require('./models/User');

// Load environment variables
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

// Connect to MongoDB
connectDB();

// --- Telegram Bot ---
const bot = new TelegramBot(process.env.BOT_TOKEN, { polling: true });
const userSessions = new Map();
const pendingReceipts = new Map();

// --- Define Bot Commands ---
const botCommands = [
    { command: 'start', description: 'Start or restart the bot' },
    { command: 'clear', description: 'Clear all your data and stop reminders' },
];


// --- Texts ---
const texts = {
    english: {
        welcome: 'Welcome! Please send /start to begin.',
        start: 'Hello! Welcome to Utility Tracker Bot. I will remind you monthly to submit your utility usage.',
        language: 'Please choose your preferred language:',
        roomNumber: 'Please enter your room number. Example: A101',
        electricity: 'Please enter this month\'s electricity usage (numbers only). Example: 150',
        water: 'Please enter this month\'s water usage (numbers only). Example: 25',
        invalidNumber: 'Please enter a valid number.',
        invalidRoom: 'Please enter a valid room number.',
        success: 'Thank you! Your usage data has been saved successfully.',
        error: 'An error occurred. Please try again.',
        reminder: '🔔 Reminder: Rent is due! Please submit your utility usage for this month.',
        noReceiptYet: 'No receipt image found for your room number yet. Please wait a moment, and I will send it once it\'s available.',
        receiptSent: 'Here is your receipt for this month:',
        dataSaved: 'Your utility data has been saved.',
        thankYou: 'Thank you for submitting your utility usage!',
        selectLang: 'Please select a language from the options below.',
        clearDataConfirmation: 'Are you sure you want to clear all your data and stop using the bot? This will remove your language preference, room number, and stop reminders. You can always /start again.',
        dataCleared: 'All your session data has been cleared. You will no longer receive reminders. You can type /start anytime to begin again.',
        cancel: 'Operation cancelled. Your data has not been cleared.'
    },
    khmer: {
        welcome: 'សូមស្វាគមន៍! សូមផ្ញើ /start ដើម្បីចាប់ផ្តើម។',
        start: 'សួស្តី! សូមស្វាគមន៍មកកាន់ប្រព័ន្ធតាមដានការប្រើប្រាស់ឧបករណ៍។ ខ្ញុំនឹងរំលឹកអ្នករាល់ខែដើម្បីបញ្ជូនការប្រើប្រាស់របស់អ្នក។',
        language: 'សូមជ្រើសរើសភាសាដែលអ្នកចូលចិត្ត:',
        roomNumber: 'សូមបញ្ចូលលេខបន្ទប់របស់អ្នក។ ឧទាហរណ៍: A101',
        electricity: 'សូមបញ្ចូលការប្រើប្រាស់ភ្លើងរបស់ខែនេះ (តួលេខតែប៉ុណ្ណោះ)។ ឧទុហរណ៍: 150',
        water: 'សូមបញ្ចូលការប្រើប្រាស់ទឹករបស់ខែនេះ (តួលេខតែប៉ុណ្ណោះ)។ ឧទុហរណ៍: 25',
        invalidNumber: 'សូមបញ្ចូលលេខដែលត្រឹមត្រូវ។',
        invalidRoom: 'សូមបញ្ចូលលេខបន្ទប់ដែលត្រឹមត្រូវ។',
        success: 'សូមអរគុណ! ទិន្នន័យការប្រើប្រាស់របស់អ្នកត្រូវបានរក្សាទុកដោយជោគជ័យ។',
        error: 'មានកំហុសកើតឡើង។ សូមព្យាយាមម្តងទៀត។',
        reminder: '🔔 ការរំលឹក: ថ្ងៃបង់ថ្លៃជួលបន្ទប់ដល់ហើយ! សូមបញ្ជូនការប្រើប្រាស់ឧបករណ៍របស់អ្នកសម្រាប់ខែនេះ។',
        noReceiptYet: 'រកមិនទាន់ឃើញបង្កាន់ដៃសម្រាប់លេខបន្ទប់របស់អ្នកទេ។ សូមរង់ចាំបន្តិច ខ្ញុំនឹងផ្ញើវាពេលវាមាន។',
        receiptSent: 'នេះជាបង្កាន់ដៃសម្រាប់ខែនេៈ:',
        dataSaved: 'ទិន្នន័យប្រើប្រាស់របស់អ្នកត្រូវបានរក្សាទុក។',
        thankYou: 'សូមអរគុណសម្រាប់ការដាក់បញ្ចូលការប្រើប្រាស់ឧបករណ៍របស់អ្នក!',
        selectLang: 'សូមជ្រើសរើសភាសាមួយពីជម្រើសខាងក្រោម។',
        clearDataConfirmation: 'តើអ្នកប្រាកដជាចង់លុបទិន្នន័យរបស់អ្នកទាំងអស់ ហើយឈប់ប្រើបូតនេះមែនទេ? វានឹងលុបចំណូលចិត្តភាសារបស់អ្នក លេខបន្ទប់ និងបញ្ឈប់ការរំលឹក។ អ្នកអាច /start ឡើងវិញបានគ្រប់ពេល។',
        dataCleared: 'ទិន្នន័យវគ្គរបស់អ្នកទាំងអស់ត្រូវបានលុប។ អ្នកនឹងលែងទទួលបានការរំលឹកទៀតហើយ។ អ្នកអាចវាយ /start គ្រប់ពេលដើម្បីចាប់ផ្តើមម្តងទៀត។',
        cancel: 'ប្រតិបត្តិការត្រូវបានលុបចោល។ ទិន្នន័យរបស់អ្នកមិនត្រូវបានលុបទេ។'
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

const clearConfirmationKeyboard = (language) => {
    const t = texts[language];
    return {
        reply_markup: {
            keyboard: [[{ text: 'Yes, clear my data' }, { text: 'No, keep my data' }]],
            resize_keyboard: true,
            one_time_keyboard: true
        }
    };
};

function getNextReminderDate(startDate) {
    const nextDate = new Date(startDate);
    nextDate.setMonth(nextDate.getMonth() + 1);
    nextDate.setHours(9, 0, 0, 0);
    return nextDate;
}

cron.schedule('0 * * * *', async () => {
    console.log('Checking for personalized reminders...');
    const now = new Date();
    const usersToRemind = await User.find({
        nextReminderDate: { $lte: now },
        isActive: true
    });

    for (const user of usersToRemind) {
        try {
            const t = texts[user.language || 'english'];
            await bot.sendMessage(user.chatId, t.reminder);

            user.nextReminderDate = getNextReminderDate(user.nextReminderDate || user.lastInteractionDate);
            await user.save();
            console.log(`Reminder sent to chat ${user.chatId}. Next reminder: ${user.nextReminderDate}`);
        } catch (error) {
            console.error(`Error sending reminder to ${user.chatId}:`, error);
        }
    }
});

cron.schedule('* * * * *', async () => {
    if (pendingReceipts.size > 0) {
        console.log(`Checking for ${pendingReceipts.size} pending receipts...`);
        for (let [chatId, { roomNumber, language }] of pendingReceipts) {
            try {
                const receipt = await Receipt.findOne({ roomNumber });
                if (receipt && receipt.receiptImage) {
                    const t = texts[language];
                    bot.sendMessage(chatId, t.receiptSent);
                    bot.sendPhoto(chatId, receipt.receiptImage, { caption: `Receipt for Room: ${roomNumber}` });
                    pendingReceipts.delete(chatId);
                    console.log(`Receipt sent to chat ${chatId} for room ${roomNumber}.`);
                }
            } catch (error) {
                console.error(`Error sending delayed receipt to ${chatId} for room ${roomNumber}:`, error);
                const t = texts[language];
                bot.sendMessage(chatId, `${t.error} (Receipt sending failed). Please contact support.`);
                pendingReceipts.delete(chatId);
            }
        }
    }
});

// --- Telegram Handlers ---
bot.onText(/\/start/, async (msg) => {
    const chatId = msg.chat.id;
    const now = new Date();

    let user = await User.findOne({ chatId });
    if (!user) {
        user = new User({
            chatId,
            lastInteractionDate: now,
            nextReminderDate: getNextReminderDate(now),
            language: 'english',
            isActive: true
        });
        await user.save();
        console.log(`New user ${chatId} registered. First reminder: ${user.nextReminderDate}`);
    } else {
        user.lastInteractionDate = now;
        user.isActive = true;
        await user.save();
    }

    const session = { state: 'language', language: user.language, data: {} };
    userSessions.set(chatId, session);

    const t = texts[session.language];
    bot.sendMessage(chatId, t.start);
    bot.sendMessage(chatId, t.language, languageKeyboard);
});

bot.onText(/\/clear/, async (msg) => {
    const chatId = msg.chat.id;
    let user = await User.findOne({ chatId });
    const session = userSessions.get(chatId);

    let language = 'english';
    if (user && user.language) {
        language = user.language;
    } else if (session && session.language) {
        language = session.language;
    }
    const t = texts[language];

    userSessions.set(chatId, { state: 'confirm_clear', language: language, data: {} });

    bot.sendMessage(chatId, t.clearDataConfirmation, clearConfirmationKeyboard(language));
});


bot.on('message', async (msg) => {
    const chatId = msg.chat.id;
    const text = msg.text;

    const session = userSessions.get(chatId);
    if (!session) {
        if (!text.startsWith('/start') && !text.startsWith('/clear')) {
            bot.sendMessage(chatId, texts.english.welcome);
        }
        return;
    }

    const t = texts[session.language];

    switch (session.state) {
        case 'language': return handleLanguageSelection(chatId, text, session, t);
        case 'roomNumber': return handleRoomNumberInput(chatId, text, session, t);
        case 'electricity': return handleElectricityInput(chatId, text, session, t);
        case 'water': return handleWaterInput(chatId, text, session, t);
        case 'confirm_clear': return handleClearConfirmation(chatId, text, session, t);
        default:
            if (!text.startsWith('/start') && !text.startsWith('/clear')) {
                bot.sendMessage(chatId, `I'm not sure how to respond to "${text}".`);
                session.state = 'completed';
                userSessions.set(chatId, session);
                bot.sendMessage(chatId, t.start);
                bot.sendMessage(chatId, t.language, languageKeyboard);
            }
            break;
    }
});

// --- Helper Functions ---
async function handleLanguageSelection(chatId, text, session, t) {
    let selectedLanguage = 'english';
    if (text.includes('English')) {
        selectedLanguage = 'english';
    } else if (text.includes('ខ្មែរ') || text.includes('Khmer')) {
        selectedLanguage = 'khmer';
    } else {
        return bot.sendMessage(chatId, t.selectLang, languageKeyboard);
    }

    session.language = selectedLanguage;
    const tNew = texts[session.language];

    try {
        await User.findOneAndUpdate({ chatId }, { language: selectedLanguage, isActive: true });
    } catch (error) {
        console.error(`Error updating user language for ${chatId}:`, error);
    }

    session.state = 'roomNumber';
    bot.sendMessage(chatId, tNew.roomNumber, { reply_markup: { remove_keyboard: true } });
}

function handleRoomNumberInput(chatId, text, session, t) {
    const roomNumber = text.trim();
    if (!roomNumber || !/^[a-zA-Z0-9\-\s]+$/.test(roomNumber)) {
        return bot.sendMessage(chatId, t.invalidRoom);
    }
    session.data.roomNumber = roomNumber;
    session.state = 'electricity';
    bot.sendMessage(chatId, t.electricity);
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
            roomNumber: session.data.roomNumber,
            language: session.language,
            electricityUsage: session.data.electricityUsage,
            waterUsage: session.data.waterUsage,
            date: new Date()
        });
        await usage.save();
        bot.sendMessage(chatId, t.dataSaved);

        const user = await User.findOne({ chatId });
        if (user) {
            user.lastInteractionDate = new Date();
            user.nextReminderDate = getNextReminderDate(user.lastInteractionDate);
            user.isActive = true;
            await user.save();
            console.log(`User ${chatId} submitted data. Next reminder: ${user.nextReminderDate}`);
        }

        bot.sendMessage(chatId, t.noReceiptYet);

        pendingReceipts.set(chatId, { roomNumber: session.data.roomNumber, language: session.language });

        bot.sendMessage(chatId, t.thankYou, { reply_markup: { remove_keyboard: true } });

        userSessions.delete(chatId);
        console.log(`Session cleared for ${chatId} after submission.`);

    } catch (error) {
        console.error('Error saving data:', error);
        bot.sendMessage(chatId, t.error);
    }
}

async function handleClearConfirmation(chatId, text, session, t) {
    if (text.toLowerCase().includes('yes')) {
        userSessions.delete(chatId);
        pendingReceipts.delete(chatId);

        try {
            await User.findOneAndUpdate(
                { chatId },
                {
                    language: 'english',
                    roomNumber: null,
                    nextReminderDate: null,
                    isActive: false
                }
            );
            console.log(`User ${chatId} data cleared and marked inactive.`);
            bot.sendMessage(chatId, t.dataCleared, { reply_markup: { remove_keyboard: true } });
        } catch (error) {
            console.error(`Error clearing user data for ${chatId}:`, error);
            bot.sendMessage(chatId, t.error);
        }
    } else if (text.toLowerCase().includes('no')) {
        userSessions.delete(chatId);
        bot.sendMessage(chatId, t.cancel, { reply_markup: { remove_keyboard: true } });
    } else {
        bot.sendMessage(chatId, t.clearDataConfirmation, clearConfirmationKeyboard(session.language));
    }
}


// --- Polling error handling ---
bot.on('polling_error', console.error);

// --- Set bot commands on startup ---
async function setBotCommands() {
    try {
        await bot.setMyCommands(botCommands);
        console.log('Bot commands set successfully!');
    } catch (error) {
        console.error('Error setting bot commands:', error);
    }
}

// Call this function when your bot starts
setBotCommands();

console.log('Bot is running...');