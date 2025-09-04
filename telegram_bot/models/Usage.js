const mongoose = require('mongoose');

const usageSchema = new mongoose.Schema({
  chatId: {
    type: Number,
    required: true
  },
  phoneNumber: {
    type: String,
    required: true
  },
  language: {
    type: String,
    enum: ['khmer', 'english'],
    required: true
  },
  electricityUsage: {
    type: Number,
    required: true
  },
  waterUsage: {
    type: Number,
    required: true
  },
  date: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Usage', usageSchema);