// api.js
const express = require('express');
const cors = require('cors');
const multer = require('multer'); // For handling file uploads
const connectDB = require('./db'); // Import the DB connection function

// Import Mongoose Models
const Usage = require('./models/Usage');
const Receipt = require('./models/Receipt');

// Load environment variables
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

// Connect to MongoDB
connectDB();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json()); // For parsing application/json

// --- Multer for file uploads ---
const upload = multer({
    limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit for image uploads
});

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

// Apply API key authentication to all usage and receipt routes
app.use('/api/usage', apiKeyAuth);
app.use('/api/receipt', apiKeyAuth);


// --- Usage API Endpoints ---
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
        const month = parseInt(req.params.month) - 1; // Months are 0-indexed in Date object
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

// --- API Endpoint to Save/Update Receipt Image ---
app.post('/api/receipt', upload.single('receiptImage'), async (req, res) => {
    try {
        const { roomNumber, chatId } = req.body;

        if (!roomNumber || !chatId) {
            return res.status(400).json({ success: false, message: 'roomNumber and chatId are required' });
        }
        if (!req.file) {
            return res.status(400).json({ success: false, message: 'No receipt image file uploaded' });
        }

        const numericChatId = parseInt(chatId);
        if (isNaN(numericChatId)) {
            return res.status(400).json({ success: false, message: 'Invalid chatId provided' });
        }

        let receipt = await Receipt.findOne({ roomNumber });

        if (receipt) {
            receipt.receiptImage = req.file.buffer;
            receipt.dateUploaded = new Date();
            receipt.chatId = numericChatId; // Update chatId in case it changed
            await receipt.save();
            res.status(200).json({ success: true, message: 'Receipt image updated successfully.', receipt: { roomNumber: receipt.roomNumber, chatId: receipt.chatId, dateUploaded: receipt.dateUploaded } });
        } else {
            receipt = new Receipt({
                roomNumber,
                chatId: numericChatId,
                receiptImage: req.file.buffer,
                dateUploaded: new Date()
            });
            await receipt.save();
            res.status(201).json({ success: true, message: 'Receipt image saved successfully.', receipt: { roomNumber: receipt.roomNumber, chatId: receipt.chatId, dateUploaded: receipt.dateUploaded } });
        }
    } catch (error) {
        console.error('Error saving receipt image:', error);
        res.status(500).json({ success: false, message: 'Failed to save receipt image', error: error.message });
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

app.listen(PORT, () => console.log(`API server is running on port ${PORT}`));