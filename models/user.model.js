const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  uid: { type: String, unique: true },
  name: String,
  username: String,
  email: String,
  bio: { type: String, default: null },
  profileImageUrl: { type: String, default: null },
  followers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User', default: [] }],
  following: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User', default: [] }],
  portfolioIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Portfolio', default: [] }],
  __v: Number,
  // Legacy fields for backward compatibility
  phone: String,
  categories: [String],
  isPhoneVerified: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

// Update the updatedAt field on save
userSchema.pre('save', function(next) {
  this.updatedAt = new Date();
  next();
});

// Add a sparse unique index to phone to allow multiple nulls
userSchema.index({ phone: 1 }, { unique: true, sparse: true });

module.exports = mongoose.model('User', userSchema); 