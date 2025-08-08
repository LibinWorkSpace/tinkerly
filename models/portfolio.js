const mongoose = require('mongoose');

const PortfolioSchema = new mongoose.Schema({
  userId: { type: String, required: true }, // Changed to String to match Firebase UID
  profilename: { type: String, required: true },
  profileImageUrl: { type: String, default: null },
  category: { type: String, required: true },
  description: { type: String },
  followers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User', default: [] }],
  posts: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Post', default: [] }],
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

// Create compound index to prevent same user from having duplicate portfolio names
// (Removed global unique index to allow default category names for multiple users)
PortfolioSchema.index({ userId: 1, profilename: 1 }, { unique: true });

module.exports = mongoose.model('Portfolio', PortfolioSchema); 