require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const admin = require('./firebase');
const { parser, cloudinary } = require('./cloudinary');
const Post = require('./models/Post'); // Add this after other model imports

const app = express();
app.use(cors());
app.use(express.json());

mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('MongoDB connected'))
  .catch(err => console.error(err));

// Media schema
const mediaSchema = new mongoose.Schema({
  userId: String,
  url: String,
  type: String,
  public_id: String,
  createdAt: { type: Date, default: Date.now },
});
const Media = mongoose.model('Media', mediaSchema);

// User schema
const userSchema = new mongoose.Schema({
  uid: { type: String, unique: true },
  name: String,
  email: String,
  profileImageUrl: String,
  categories: [String],
  username: String,
  bio: String,
});
const User = mongoose.model('User', userSchema);

// Firebase Auth middleware
app.use(async (req, res, next) => {
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
    const idToken = req.headers.authorization.split('Bearer ')[1];
    try {
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      req.user = decodedToken;
      next();
    } catch (err) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
  } else {
    return res.status(401).json({ error: 'No token provided' });
  }
});

// Upload endpoint
app.post('/upload', parser.single('file'), async (req, res) => {
  try {
    const file = req.file;
    const media = new Media({
      userId: req.user.uid,
      url: file.path,
      type: file.mimetype.startsWith('image') ? 'image' :
            file.mimetype.startsWith('video') ? 'video' : 'other',
      public_id: file.filename,
    });
    await media.save();
    res.json(media);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get all media for user
app.get('/media', async (req, res) => {
  const media = await Media.find({ userId: req.user.uid });
  res.json(media);
});

// Delete media
app.delete('/media/:id', async (req, res) => {
  const media = await Media.findById(req.params.id);
  if (!media) return res.status(404).json({ error: 'Not found' });
  if (media.userId !== req.user.uid) return res.status(403).json({ error: 'Forbidden' });
  await cloudinary.uploader.destroy(media.public_id, { resource_type: 'auto' });
  await media.remove();
  res.json({ success: true });
});

// Create or update user profile
app.post('/user', async (req, res) => {
  const { name, email, profileImageUrl, categories, username, bio } = req.body;
  const uid = req.user.uid;
  const user = await User.findOneAndUpdate(
    { uid },
    { name, email, profileImageUrl, categories, username, bio },
    { upsert: true, new: true }
  );
  res.json(user);
});

// Get user profile
app.get('/user', async (req, res) => {
  const uid = req.user.uid;
  const user = await User.findOne({ uid });
  res.json(user);
});

// Create a new post
app.post('/post', async (req, res) => {
  try {
    const { url, description, category, mediaType, subCategory } = req.body;
    const userId = req.user.uid;
    if (!url || !description || !category || !mediaType || !userId) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    const newPost = new Post({
      url,
      description,
      category,
      mediaType,
      userId,
      subCategory,
    });
    await newPost.save();
    res.status(200).json({ message: 'Post created successfully', post: newPost });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to create post' });
  }
});

// Fetch all posts for the current user, or by category if provided
app.get('/posts', async (req, res) => {
  try {
    const userId = req.user.uid;
    const { category } = req.query;
    let query = { userId };
    if (category) {
      query.category = category;
    }
    const posts = await Post.find(query).sort({ createdAt: -1 });
    res.json(posts);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch posts' });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`)); 