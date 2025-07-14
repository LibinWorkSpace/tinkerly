require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const admin = require('./firebase');
const { parser, cloudinary } = require('./cloudinary');
const Post = require('./models/Post'); // Add this after other model imports

const app = express();
app.use(cors());
app.use(express.json({ limit: '100mb' }));
app.use(express.urlencoded({ limit: '100mb', extended: true }));

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
  followers: { type: [String], default: [] }, // Array of UIDs
  following: { type: [String], default: [] }, // Array of UIDs
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
    console.error('Upload error:', err); // Improved error logging
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
  if (!user) return res.status(404).json({ error: 'User not found' });
  const userObj = user.toObject();
  userObj.followerCount = userObj.followers ? userObj.followers.length : 0;
  userObj.followingCount = userObj.following ? userObj.following.length : 0;
  res.json(userObj);
});

// Get user profile by UID
app.get('/user/:uid', async (req, res) => {
  try {
    const { uid } = req.params;
    const user = await User.findOne({ uid }).select('uid name username profileImageUrl bio categories followers following');
    if (!user) return res.status(404).json({ error: 'User not found' });
    // Return follower/following counts, not full arrays
    const userObj = user.toObject();
    userObj.followerCount = userObj.followers ? userObj.followers.length : 0;
    userObj.followingCount = userObj.following ? userObj.following.length : 0;
    delete userObj.followers;
    delete userObj.following;
    res.json(userObj);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch user profile' });
  }
});

// Search users by name or username
app.get('/users/search', async (req, res) => {
  try {
    const { query } = req.query;
    if (!query || query.trim() === '') {
      return res.json([]);
    }
    // Case-insensitive, partial match on name or username
    const users = await User.find({
      $or: [
        { name: { $regex: query, $options: 'i' } },
        { username: { $regex: query, $options: 'i' } },
      ],
    }).select('uid name username profileImageUrl bio'); // Only public fields
    res.json(users);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to search users' });
  }
});

// Follow a user
app.post('/user/:uid/follow', async (req, res) => {
  try {
    const targetUid = req.params.uid;
    const currentUid = req.user.uid;
    if (targetUid === currentUid) return res.status(400).json({ error: 'Cannot follow yourself' });
    const targetUser = await User.findOne({ uid: targetUid });
    const currentUser = await User.findOne({ uid: currentUid });
    if (!targetUser || !currentUser) return res.status(404).json({ error: 'User not found' });
    if (targetUser.followers.includes(currentUid)) return res.status(400).json({ error: 'Already following' });
    targetUser.followers.push(currentUid);
    currentUser.following.push(targetUid);
    await targetUser.save();
    await currentUser.save();
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to follow user' });
  }
});

// Unfollow a user
app.post('/user/:uid/unfollow', async (req, res) => {
  try {
    const targetUid = req.params.uid;
    const currentUid = req.user.uid;
    if (targetUid === currentUid) return res.status(400).json({ error: 'Cannot unfollow yourself' });
    const targetUser = await User.findOne({ uid: targetUid });
    const currentUser = await User.findOne({ uid: currentUid });
    if (!targetUser || !currentUser) return res.status(404).json({ error: 'User not found' });
    targetUser.followers = targetUser.followers.filter(uid => uid !== currentUid);
    currentUser.following = currentUser.following.filter(uid => uid !== targetUid);
    await targetUser.save();
    await currentUser.save();
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to unfollow user' });
  }
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

// DELETE post by ID
app.delete('/post/:id', async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) {
      console.error('Post not found:', req.params.id);
      return res.status(404).json({ error: 'Post not found' });
    }
    if (post.userId !== req.user.uid) {
      console.error('Forbidden: user', req.user.uid, 'tried to delete post owned by', post.userId);
      return res.status(403).json({ error: 'Forbidden' });
    }
    // Try to find and delete associated media
    try {
      const Media = mongoose.model('Media');
      const media = await Media.findOne({ url: post.url });
      if (media) {
        // Use correct resource type for Cloudinary deletion
        const resourceType = (media.type === 'image' || media.type === 'video') ? media.type : 'raw';
        console.log('Deleting associated media from Cloudinary:', media.public_id, 'type:', resourceType);
        await cloudinary.uploader.destroy(media.public_id, { resource_type: resourceType });
        await media.deleteOne();
        console.log('Associated media deleted from DB and Cloudinary.');
      } else {
        console.log('No associated media found for post URL:', post.url);
      }
    } catch (mediaErr) {
      console.error('Error deleting associated media:', mediaErr);
    }
    await post.deleteOne();
    console.log('Post deleted:', req.params.id);
    res.json({ success: true });
  } catch (err) {
    console.error('Delete post error:', err);
    res.status(500).json({ error: 'Failed to delete post' });
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
    // Fetch user profile once
    const user = await User.findOne({ uid: userId });
    // Attach user info to each post
    const postsWithUser = posts.map(post => ({
      ...post.toObject(),
      name: user ? user.name : '',
      username: user ? user.username : '',
      profileImageUrl: user ? user.profileImageUrl : '',
    }));
    res.json(postsWithUser);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch posts' });
  }
});

// Fetch posts for any user by UID
app.get('/posts/user/:uid', async (req, res) => {
  try {
    const { uid } = req.params;
    const posts = await Post.find({ userId: uid }).sort({ createdAt: -1 });
    // Attach user info to each post
    const user = await User.findOne({ uid });
    const postsWithUser = posts.map(post => ({
      ...post.toObject(),
      name: user ? user.name : '',
      username: user ? user.username : '',
      profileImageUrl: user ? user.profileImageUrl : '',
    }));
    res.json(postsWithUser);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch user posts' });
  }
});

// Fetch all posts from all users (for home feed)
app.get('/posts/all', async (req, res) => {
  try {
    const posts = await Post.find({}).sort({ createdAt: -1 });
    // Fetch all users in one go
    const users = await User.find({});
    const userMap = {};
    users.forEach(user => {
      userMap[user.uid] = user;
    });
    // Attach user info to each post
    const postsWithUser = posts.map(post => ({
      ...post.toObject(),
      name: userMap[post.userId]?.name || '',
      username: userMap[post.userId]?.username || '',
      profileImageUrl: userMap[post.userId]?.profileImageUrl || '',
    }));
    res.json(postsWithUser);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch all posts' });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`)); 