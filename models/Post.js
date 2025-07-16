const mongoose = require('mongoose');

const PostSchema = new mongoose.Schema({
  url: { type: String, required: true }, // Cloudinary/media URL
  description: { type: String, required: true },
  category: { type: String, required: true }, // Must match user's registered categories
  subCategory: { type: String }, // Optional subcategory
  mediaType: { type: String, enum: ['image', 'video'], required: true },
  userId: { type: String, required: true }, // Firebase UID or your user ID
  createdAt: { type: Date, default: Date.now },
  likes: { type: Number, default: 0 },
  likedBy: { type: [String], default: [] }, // Array of user UIDs who liked this post
  views: { type: Number, default: 0 },
  comments: [
    {
      userId: String,
      comment: String,
      createdAt: { type: Date, default: Date.now }
    }
  ]
});

module.exports = mongoose.model('Post', PostSchema); 