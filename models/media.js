const mongoose = require('mongoose');

const MediaSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true, required: true },
  public_id: { type: String, required: true },
  url: { type: String, required: true },
  type: { type: String, index: true, required: true },
  createdAt: { type: Date, default: Date.now },
  __v: Number
});

module.exports = mongoose.model('Media', MediaSchema); 