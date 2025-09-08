const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    chatId: {
        type: Number,
        required: true,
        unique: true
    },
    language: {
        type: String,
        enum: ['english', 'khmer'],
        default: 'english'
    },
    lastInteractionDate: {
        type: Date,
        default: Date.now
    },
    nextReminderDate: {
        type: Date
    },
    isActive: {
        type: Boolean,
        default: true
    }
});

module.exports = mongoose.model('User', userSchema);