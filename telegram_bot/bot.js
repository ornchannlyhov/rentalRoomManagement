const TelegramBot = require('node-telegram-bot-api');
const cron = require('node-cron');
const connectDB = require('./db');
const path = require('path');

// Load environment variables as early as possible
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

// Import Mongoose Models
const Usage = require('./models/Usage');
const Receipt = require('./models/Receipt');
const User = require('./models/User');

// Connect to MongoDB once
connectDB();

const bot = new TelegramBot(process.env.BOT_TOKEN, { polling: true });

const userSessions = new Map();
const pendingReceipts = new Map();

const botCommands = [
    { command: 'start', description: 'Start or restart the bot' },
    { command: 'clear', description: 'Clear all your data and stop reminders' },
];

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
        clearYes: 'Yes, clear my data', 
        clearNo: 'No, cancel',         
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
        clearYes: 'បាទ/ចាស លុបទិន្នន័យរបស់ខ្ញុំ', 
        clearNo: 'ទេ កុំលុបចោល',            
        dataCleared: 'ទិន្នន័យវគ្គរបស់អ្នកទាំងអស់ត្រូវបានលុប។ អ្នកនឹងលែងទទួលបានការរំលឹកទៀតហើយ។ អ្នកអាចវាយ /start គ្រប់ពេលដើម្បីចាប់ផ្តើមម្តងទៀត។',
        cancel: 'ប្រតិបត្តិការត្រូវបានលុបចោល។ ទិន្នន័យរបស់អ្នកមិនត្រូវបានលុបទេ។'
    }
};

const languageKeyboard = {
    reply_markup: {
        keyboard: [[{ text: '🇰🇭 ខ្មែរ (Khmer)' }, { text: '🇺🇸 English' }]],
        resize_keyboard: true,
        one_time_keyboard: true
    }
};

const removeKeyboard = {
    reply_markup: {
        remove_keyboard: true
    }
};

const getClearConfirmationKeyboard = (language) => {
    const t = texts[language];
    return {
        reply_markup: {
            keyboard: [[{ text: t.clearYes }, { text: t.clearNo }]],
            resize_keyboard: true,
            one_time_keyboard: true
        }
    };
};

/**
 * Calculates the next reminder date for a user.
 * @param {Date} startDate The date from which to calculate the next reminder.
 * @returns {Date} The calculated next reminder date.
 */
function getNextReminderDate(startDate) {
    const nextDate = new Date(startDate);
    nextDate.setMonth(nextDate.getMonth() + 1);
    nextDate.setHours(9, 0, 0, 0);
    return nextDate;
}

/**
 * Sends a message to a chat, handling potential errors.
 * @param {number} chatId The chat ID.
 * @param {string} message The message to send.
 * @param {object} [options={}] Additional message options.
 */
async function sendBotMessage(chatId, message, options = {}) {
    try {
        await bot.sendMessage(chatId, message, options);
    } catch (error) {
        console.error(`Error sending message to ${chatId}:`, error.message);
        if (error.response && error.response.error_code === 403) {
            console.log(`User ${chatId} blocked the bot. Deactivating user.`);
            await User.findOneAndUpdate({ chatId }, { isActive: false });
        }
    }
}

/**
 * Sends a photo to a chat, handling potential errors.
 * @param {number} chatId The chat ID.
 * @param {string} photo The photo to send.
 * @param {object} [options={}] Additional photo options.
 */
async function sendBotPhoto(chatId, photo, options = {}) {
    try {
        await bot.sendPhoto(chatId, photo, options);
    } catch (error) {
        console.error(`Error sending photo to ${chatId}:`, error.message);
        if (error.response && error.response.error_code === 403) {
            console.log(`User ${chatId} blocked the bot. Deactivating user.`);
            await User.findOneAndUpdate({ chatId }, { isActive: false });
        }
    }
}

cron.schedule('0 9 * * *', async () => {
    console.log('Running daily reminder check...');
    const now = new Date();
    const usersToRemind = await User.find({
        nextReminderDate: { $lte: now },
        isActive: true
    }).lean();

    for (const user of usersToRemind) {
        try {
            const t = texts[user.language || 'english'];
            await sendBotMessage(user.chatId, t.reminder);

            await User.findByIdAndUpdate(user._id, {
                nextReminderDate: getNextReminderDate(user.nextReminderDate || user.lastInteractionDate)
            });
            console.log(`Reminder sent to chat ${user.chatId}. Next reminder: ${user.nextReminderDate}`);
        } catch (error) {
            console.error(`Error processing reminder for ${user.chatId}:`, error);
        }
    }
});

cron.schedule('* * * * *', async () => {
    if (pendingReceipts.size > 0) {
        console.log(`Checking for ${pendingReceipts.size} pending receipts...`);
        for (let [chatId, { roomNumber, language }] of Array.from(pendingReceipts.entries())) {
            try {
                const receipt = await Receipt.findOne({ roomNumber }).select('receiptImage').lean();
                if (receipt && receipt.receiptImage) {
                    const t = texts[language];
                    await sendBotMessage(chatId, t.receiptSent);
                    await sendBotPhoto(chatId, receipt.receiptImage, { caption: `Receipt for Room: ${roomNumber}` });
                    pendingReceipts.delete(chatId);
                    console.log(`Receipt sent to chat ${chatId} for room ${roomNumber}.`);
                }
            } catch (error) {
                console.error(`Error sending delayed receipt to ${chatId} for room ${roomNumber}:`, error);
                const t = texts[language];
                await sendBotMessage(chatId, `${t.error} (Receipt sending failed). Please contact support.`);
                pendingReceipts.delete(chatId);
            }
        }
    }
});


/**
 * Handles the /start command.
 * @param {object} msg The Telegram message object.
 */
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
        if (!user.isActive || user.language === undefined || user.lastInteractionDate.getTime() !== now.getTime()) {
            user.lastInteractionDate = now;
            user.isActive = true;
            await user.save();
        }
    }

    userSessions.set(chatId, { state: 'language', language: user.language, data: {} });

    const t = texts[user.language];
    await sendBotMessage(chatId, t.start);
    await sendBotMessage(chatId, t.language, languageKeyboard);
});

/**
 * Handles the /clear command.
 * @param {object} msg The Telegram message object.
 */
bot.onText(/\/clear/, async (msg) => {
    const chatId = msg.chat.id;
    let user = await User.findOne({ chatId }).select('language');
    const session = userSessions.get(chatId);

    const language = (user && user.language) || (session && session.language) || 'english';
    const t = texts[language];

    userSessions.set(chatId, { state: 'confirm_clear', language: language, data: {} });

    await sendBotMessage(chatId, t.clearDataConfirmation, getClearConfirmationKeyboard(language));
});


bot.on('message', async (msg) => {
    const chatId = msg.chat.id;
    const text = msg.text;

    if (text && text.startsWith('/')) return;

    const session = userSessions.get(chatId);

    if (!session) {
        await sendBotMessage(chatId, texts.english.welcome);
        return;
    }

    const t = texts[session.language];

    try {
        switch (session.state) {
            case 'language':
                await handleLanguageSelection(chatId, text, session, t);
                break;
            case 'roomNumber':
                await handleRoomNumberInput(chatId, text, session, t);
                break;
            case 'electricity':
                await handleElectricityInput(chatId, text, session, t);
                break;
            case 'water':
                await handleWaterInput(chatId, text, session, t);
                break;
            case 'confirm_clear':
                await handleClearConfirmation(chatId, text, session, t);
                break;
            default:
                await sendBotMessage(chatId, `I'm not sure how to respond to "${text}".`);
                session.state = 'language';
                userSessions.set(chatId, session);
                await sendBotMessage(chatId, t.start);
                await sendBotMessage(chatId, t.language, languageKeyboard);
                break;
        }
    } catch (error) {
        console.error(`Error in message handler for chat ${chatId}, state ${session.state}:`, error);
        await sendBotMessage(chatId, t.error);
        userSessions.delete(chatId);
    }
});

async function handleLanguageSelection(chatId, text, session, t) {
    let selectedLanguage = 'english';
    if (text.includes('English')) {
        selectedLanguage = 'english';
    } else if (text.includes('ខ្មែរ') || text.includes('Khmer')) {
        selectedLanguage = 'khmer';
    } else {
        return sendBotMessage(chatId, t.selectLang, languageKeyboard);
    }

    session.language = selectedLanguage;
    const tNew = texts[session.language]; 

    try {
        await User.findOneAndUpdate({ chatId }, { language: selectedLanguage, isActive: true }, { upsert: true });
    } catch (error) {
        console.error(`Error updating user language for ${chatId}:`, error);
    }

    session.state = 'roomNumber';
    await sendBotMessage(chatId, tNew.roomNumber, removeKeyboard);
}

async function handleRoomNumberInput(chatId, text, session, t) {
    const roomNumber = text.trim();
    if (!roomNumber || !/^[a-zA-Z0-9\-\s]+$/.test(roomNumber)) {
        return sendBotMessage(chatId, t.invalidRoom);
    }
    session.data.roomNumber = roomNumber;
    session.state = 'electricity';
    await sendBotMessage(chatId, t.electricity);
}

async function handleElectricityInput(chatId, text, session, t) {
    const electricity = parseFloat(text);
    if (isNaN(electricity) || electricity < 0) { 
        return sendBotMessage(chatId, t.invalidNumber);
    }
    session.data.electricityUsage = electricity;
    session.state = 'water';
    await sendBotMessage(chatId, t.water);
}

async function handleWaterInput(chatId, text, session, t) {
    const water = parseFloat(text);
    if (isNaN(water) || water < 0) { 
        return sendBotMessage(chatId, t.invalidNumber);
    }
    session.data.waterUsage = water;

    try {
        const now = new Date();
        const usage = new Usage({
            chatId,
            roomNumber: session.data.roomNumber,
            language: session.language,
            electricityUsage: session.data.electricityUsage,
            waterUsage: session.data.waterUsage,
            date: now
        });
        await usage.save();
        await sendBotMessage(chatId, t.dataSaved);

        await User.findOneAndUpdate(
            { chatId },
            {
                lastInteractionDate: now,
                nextReminderDate: getNextReminderDate(now),
                isActive: true 
            },
            { new: true, upsert: true }
        );
        console.log(`User ${chatId} submitted data. Next reminder: ${getNextReminderDate(now)}`);


        await sendBotMessage(chatId, t.noReceiptYet);
        pendingReceipts.set(chatId, { roomNumber: session.data.roomNumber, language: session.language });
        await sendBotMessage(chatId, t.thankYou, removeKeyboard);

        userSessions.delete(chatId); 
        console.log(`Session cleared for ${chatId} after submission.`);

    } catch (error) {
        console.error('Error saving data:', error);
        await sendBotMessage(chatId, t.error);
        userSessions.delete(chatId); 
    }
}

async function handleClearConfirmation(chatId, text, session, t) {
    if (text === t.clearYes) {
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
                },
                { new: true } 
            );
            console.log(`User ${chatId} data cleared and marked inactive.`);
            await sendBotMessage(chatId, t.dataCleared, removeKeyboard);
        } catch (error) {
            console.error(`Error clearing user data for ${chatId}:`, error);
            await sendBotMessage(chatId, t.error);
        }
    } else if (text === t.clearNo) {
        userSessions.delete(chatId); 
        await sendBotMessage(chatId, t.cancel, removeKeyboard);
    } else {
        await sendBotMessage(chatId, t.clearDataConfirmation, getClearConfirmationKeyboard(session.language));
    }
}


bot.on('polling_error', (error) => {
    console.error('Polling Error:', error.code, error.message);
});

async function setBotCommands() {
    try {
        await bot.setMyCommands(botCommands);
        console.log('Bot commands set successfully!');
    } catch (error) {
        console.error('Error setting bot commands:', error);
    }
}

setBotCommands();

console.log('Bot is running...');