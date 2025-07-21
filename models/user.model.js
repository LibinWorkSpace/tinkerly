const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  uid: { type: String, unique: true },
  name: String,
  email: String,
  phone: String,
  profileImageUrl: String,
  categories: [String],
  username: String,
  bio: String,
  followers: { type: [String], default: [] },
  following: { type: [String], default: [] },
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