const mongoose = require('mongoose');

const receiptSchema = new mongoose.Schema({
    roomNumber: {
        type: String,
        required: true,
        unique: true 
    },
    chatId: {
        type: Number,
        required: true,
        index: true 
    },
    receiptImage: {
        type: Buffer, 
        required: true
    },
    dateUploaded: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Receipt', receiptSchema);