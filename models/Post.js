const mongoose = require('mongoose');

const PostSchema = new mongoose.Schema({
  creatorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: false }, // new
  portfolioId: { type: mongoose.Schema.Types.ObjectId, ref: 'Portfolio', required: false }, // new
  category: { type: String, required: true },
  subCategory: { type: String },
  description: { type: String, required: true },
  url: { type: String, required: true },
  mediaType: { type: String, enum: ['image', 'video', 'audio'], required: true },
  likes: { type: Number, default: 0 },
  comments: [
    {
      userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
      comment: String,
      commentedAt: { type: Date, default: Date.now }
    }
  ],
  views: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now },
  __v: Number,
  // Legacy fields for backward compatibility
  userId: { type: String },
  likedBy: { type: [String], default: [] }
});

module.exports = mongoose.model('Post', PostSchema); 