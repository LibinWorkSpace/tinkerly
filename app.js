require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const admin = require('./firebase');
const { parser, cloudinary } = require('./cloudinary');
const Post = require('./models/Post'); // Add this after other model imports
const User = require('./models/user.model'); // Add User model
const nodemailer = require('nodemailer');
const crypto = require('crypto');
const Portfolio = require('./models/portfolio');

// In-memory OTP store: { email: { otp, expires } }
const otpStore = {};

// In-memory OTP store for registration: { email: { otp, expires } }
const registrationOtpStore = {};

// Configure nodemailer (use your SMTP credentials)
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

const app = express();
app.use(cors());
app.use(express.json({ limit: '100mb' }));
app.use(express.urlencoded({ limit: '100mb', extended: true }));

// Import OTP routes
const otpRoutes = require('./routes/otp.routes');

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

// User schema is now imported from models/user.model.js

// Helper function to send SMS (placeholder, replace with real SMS API like Twilio)
async function sendSms(phone, message) {
  // TODO: Integrate with SMS provider (e.g., Twilio)
  console.log(`Sending SMS to ${phone}: ${message}`);
  return true;
}

// Update send OTP endpoint to support email or phone
app.post('/auth/send-otp', async (req, res) => {
  const { email, method } = req.body;
  let user;
  if (method === 'phone') {
    // Find user by email to get phone
    if (!email || !email.includes('@')) return res.status(400).json({ error: 'Invalid email' });
    user = await User.findOne({ email });
    if (!user || !user.phone) return res.status(404).json({ error: 'No user with this email or phone' });
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    otpStore[user.phone] = { otp, expires: Date.now() + 10 * 60 * 1000 };
    try {
      await sendSms(user.phone, `Your OTP for password reset is: ${otp}`);
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ error: 'Failed to send SMS' });
    }
  } else {
    // Default: send to email
    if (!email || !email.includes('@')) return res.status(400).json({ error: 'Invalid email' });
    user = await User.findOne({ email });
    if (!user) return res.status(404).json({ error: 'No user with this email' });
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    otpStore[email] = { otp, expires: Date.now() + 10 * 60 * 1000 };
    try {
      await transporter.sendMail({
        from: process.env.SMTP_USER,
        to: email,
        subject: 'Tinkerly Password Reset OTP',
        text: `Your OTP for password reset is: ${otp}`,
      });
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ error: 'Failed to send email' });
    }
  }
});

app.post('/auth/reset-password', async (req, res) => {
  const { email, otp, newPassword } = req.body;
  if (!email || !otp || !newPassword) return res.status(400).json({ error: 'Missing fields' });
  const record = otpStore[email];
  if (!record || record.otp !== otp || Date.now() > record.expires) {
    return res.status(400).json({ error: 'Invalid or expired OTP' });
  }
  try {
    // Find user in Firebase Auth and update password
    const userRecord = await admin.auth().getUserByEmail(email);
    await admin.auth().updateUser(userRecord.uid, { password: newPassword });
    delete otpStore[email];
    res.json({ success: true });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to update password in Firebase' });
  }
});

// Send registration OTP endpoint
app.post('/auth/send-registration-otp', async (req, res) => {
  const { email } = req.body;
  if (!email || !email.includes('@')) return res.status(400).json({ error: 'Invalid email' });
  const user = await User.findOne({ email });
  if (user) return res.status(409).json({ error: 'Email already registered' });
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  registrationOtpStore[email] = { otp, expires: Date.now() + 10 * 60 * 1000 };
  try {
    await transporter.sendMail({
      from: process.env.SMTP_USER,
      to: email,
      subject: 'Tinkerly Registration OTP',
      text: `Your OTP for registration is: ${otp}`,
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Failed to send email' });
  }
});

// Verify registration OTP endpoint to verify email during registration
app.post('/auth/verify-registration-otp', async (req, res) => {
  const { email, otp } = req.body;
  if (!email || !otp) return res.status(400).json({ error: 'Missing fields' });
  const record = registrationOtpStore[email];
  if (!record || record.otp !== otp || Date.now() > record.expires) {
    return res.status(400).json({ error: 'Invalid or expired OTP' });
  }
  delete registrationOtpStore[email];
  res.json({ success: true });
});

// Public endpoint to check if email exists
app.get('/user/exists', async (req, res) => {
  const { email } = req.query;
  if (!email || typeof email !== 'string' || !email.includes('@')) {
    return res.status(400).json({ exists: false });
  }
  const user = await User.findOne({ email });
  res.json({ exists: !!user });
});

// OTP routes
app.use('/otp', otpRoutes);

// Firebase Auth middleware (keep this after the public routes)
app.use(async (req, res, next) => {
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
    const idToken = req.headers.authorization.split('Bearer ')[1];
    try {
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      req.user = decodedToken;
      next();
    } catch (err) {
      console.error('Firebase token verification failed:', err);
      return res.status(401).json({ error: 'Unauthorized' });
    }
  } else {
    console.error('No token provided in Authorization header');
    return res.status(401).json({ error: 'No token provided' });
  }
});

// Register new portfolio and product routes
const portfolioRoutes = require('./routes/portfolio.routes');
const productRoutes = require('./routes/product.routes');
app.use('/portfolios', portfolioRoutes);
app.use('/products', productRoutes);

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
  try {
    // Log incoming request for debugging
    console.log('POST /user body:', req.body);
    console.log('POST /user req.user:', req.user);
    const { name, email, phone, profileImageUrl, categories, username, bio } = req.body;
    const uid = req.user && req.user.uid;
    if (!uid) {
      console.error('POST /user error: Missing uid in req.user');
      return res.status(400).json({ error: 'Missing uid in token' });
    }
    // Check if a user with this email already exists
    let user = await User.findOne({ email });
    if (user) {
      // User exists, return existing user data (do not update)
      return res.status(200).json(user);
    }
    // Only include fields that are not null or undefined
    const newUserFields = { uid, name, email, profileImageUrl, categories, username, bio };
    if (phone !== undefined && phone !== null && phone !== '') {
      newUserFields.phone = phone;
    }
    user = new User(newUserFields);
    await user.save();
    res.status(201).json(user);
  } catch (err) {
    if (err.name === 'MongoServerError' && err.code === 11000) {
      console.error('POST /user duplicate key error:', err);
      return res.status(409).json({ error: 'Duplicate key error', details: err.message });
    }
    console.error('POST /user error:', err);
    res.status(500).json({ error: 'Failed to save user profile', details: err.message });
  }
});

// Edit user profile (update allowed fields)
app.put('/user', async (req, res) => {
  try {
    const uid = req.user && req.user.uid;
    if (!uid) {
      return res.status(400).json({ error: 'Missing uid in token' });
    }
    const { name, phone, profileImageUrl, categories, username, bio } = req.body;
    // Only allow updating these fields if they are not null or undefined
    const updateFields = {};
    if (name !== undefined && name !== null) updateFields.name = name;
    if (phone !== undefined && phone !== null && phone !== '') updateFields.phone = phone;
    if (profileImageUrl !== undefined && profileImageUrl !== null) updateFields.profileImageUrl = profileImageUrl;
    if (categories !== undefined && categories !== null) updateFields.categories = categories;
    if (username !== undefined && username !== null) updateFields.username = username;
    if (bio !== undefined && bio !== null) updateFields.bio = bio;
    const user = await User.findOneAndUpdate(
      { uid },
      updateFields,
      { new: true }
    );
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
  } catch (err) {
    console.error('PUT /user error:', err);
    res.status(500).json({ error: 'Failed to update user profile', details: err.message });
  }
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

    console.log('Follow request - Target UID:', targetUid, 'Current UID:', currentUid);

    if (targetUid === currentUid) {
      return res.status(400).json({ error: 'Cannot follow yourself' });
    }

    const targetUser = await User.findOne({ uid: targetUid });
    const currentUser = await User.findOne({ uid: currentUid });

    console.log('Target user found:', !!targetUser, 'Current user found:', !!currentUser);

    if (!targetUser || !currentUser) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Initialize arrays if they don't exist
    if (!targetUser.followers) targetUser.followers = [];
    if (!currentUser.following) currentUser.following = [];

    // Check if already following (using ObjectId comparison)
    const isAlreadyFollowing = currentUser.following.some(id => id.equals(targetUser._id));
    if (isAlreadyFollowing) {
      return res.status(400).json({ error: 'Already following this user' });
    }

    // Add to following/followers lists using ObjectIds
    currentUser.following.push(targetUser._id);
    targetUser.followers.push(currentUser._id);

    await currentUser.save();
    await targetUser.save();

    console.log('Follow successful');
    res.json({ success: true, message: 'User followed successfully' });
  } catch (err) {
    console.error('Follow error:', err);
    res.status(500).json({ error: 'Failed to follow user', details: err.message });
  }
});

// Unfollow a user
app.post('/user/:uid/unfollow', async (req, res) => {
  try {
    const targetUid = req.params.uid;
    const currentUid = req.user.uid;

    if (targetUid === currentUid) {
      return res.status(400).json({ error: 'Cannot unfollow yourself' });
    }

    const targetUser = await User.findOne({ uid: targetUid });
    const currentUser = await User.findOne({ uid: currentUid });

    if (!targetUser || !currentUser) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Remove from following/followers lists using ObjectId comparison
    if (currentUser.following) {
      currentUser.following = currentUser.following.filter(id => !id.equals(targetUser._id));
    }
    if (targetUser.followers) {
      targetUser.followers = targetUser.followers.filter(id => !id.equals(currentUser._id));
    }

    await currentUser.save();
    await targetUser.save();

    res.json({ success: true, message: 'User unfollowed successfully' });
  } catch (err) {
    console.error('Unfollow error:', err);
    res.status(500).json({ error: 'Failed to unfollow user', details: err.message });
  }
});

// Create a new post
app.post('/post', async (req, res) => {
  try {
    const { url, description, category, mediaType, subCategory, portfolioId } = req.body;
    const userId = req.user.uid;
    if (!url || !description || !category || !mediaType || !userId) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    
    console.log('Creating post with portfolioId:', portfolioId); // Debug log
    
    const newPost = new Post({
      url,
      description,
      category,
      mediaType,
      userId,
      subCategory,
      portfolioId: portfolioId || null, // Add portfolioId to the post
    });
    await newPost.save();
    
    console.log('Post created successfully with ID:', newPost._id); // Debug log
    
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
      likedBy: post.likedBy || [],
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
      likedBy: post.likedBy || [],
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
      likedBy: post.likedBy || [],
    }));
    res.json(postsWithUser);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch all posts' });
  }
});

// Get feed with portfolio information
app.get('/feed', async (req, res) => {
  try {
    const posts = await Post.find({}).sort({ createdAt: -1 }).lean();
    
    // Fetch all users and portfolios in one go for efficiency
    const users = await User.find({});
    const portfolios = await Portfolio.find({});
    
    const userMap = {};
    const portfolioMap = {};
    
    users.forEach(user => {
      userMap[user.uid] = user;
    });
    
    portfolios.forEach(portfolio => {
      portfolioMap[portfolio._id.toString()] = portfolio;
    });
    
    // Attach user and portfolio info to each post
    const postsWithInfo = posts.map(post => ({
      ...post,
      name: userMap[post.userId]?.name || '',
      username: userMap[post.userId]?.username || '',
      profileImageUrl: userMap[post.userId]?.profileImageUrl || '',
      likedBy: post.likedBy || [],
      portfolio: post.portfolioId ? portfolioMap[post.portfolioId.toString()] : null,
    }));
    
    console.log(`Fetched ${postsWithInfo.length} posts with portfolio info`); // Debug log
    
    res.json(postsWithInfo);
  } catch (err) {
    console.error('Error fetching feed:', err);
    res.status(500).json({ error: 'Failed to fetch feed' });
  }
});



// Like a post
app.post('/post/:id/like', async (req, res) => {
  try {
    const postId = req.params.id;
    const userId = req.user.uid;
    const post = await Post.findById(postId);
    if (!post) return res.status(404).json({ error: 'Post not found' });
    // Add a likedBy array if not present
    if (!post.likedBy) post.likedBy = [];
    if (post.likedBy.includes(userId)) {
      return res.status(400).json({ error: 'Already liked' });
    }
    post.likedBy.push(userId);
    post.likes = post.likedBy.length;
    await post.save();
    res.json({ success: true, likes: post.likes });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to like post' });
  }
});

// Unlike a post
app.post('/post/:id/unlike', async (req, res) => {
  try {
    const postId = req.params.id;
    const userId = req.user.uid;
    const post = await Post.findById(postId);
    if (!post) return res.status(404).json({ error: 'Post not found' });
    if (!post.likedBy) post.likedBy = [];
    if (!post.likedBy.includes(userId)) {
      return res.status(400).json({ error: 'Not liked yet' });
    }
    post.likedBy = post.likedBy.filter(uid => uid !== userId);
    post.likes = post.likedBy.length;
    await post.save();
    res.json({ success: true, likes: post.likes });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to unlike post' });
  }
});

// Get users who liked a post (only for post owner)
app.get('/post/:id/likes', async (req, res) => {
  try {
    const postId = req.params.id;
    const currentUserId = req.user.uid;
    const post = await Post.findById(postId);
    if (!post) return res.status(404).json({ error: 'Post not found' });

    // Only allow post owner to see who liked their post
    if (post.userId !== currentUserId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    if (!post.likedBy || post.likedBy.length === 0) {
      return res.json([]);
    }

    // Fetch user details for each user who liked the post
    const users = await User.find({ uid: { $in: post.likedBy } }).select('uid name username profileImageUrl');
    res.json(users);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch liked by users' });
  }
});

// Add a comment to a post
app.post('/post/:id/comment', async (req, res) => {
  try {
    const postId = req.params.id;
    const userId = req.user.uid;
    const { comment } = req.body;

    if (!comment || comment.trim().length === 0) {
      return res.status(400).json({ error: 'Comment cannot be empty' });
    }

    const post = await Post.findById(postId);
    if (!post) return res.status(404).json({ error: 'Post not found' });

    // Get user details
    const user = await User.findOne({ uid: userId });
    if (!user) return res.status(404).json({ error: 'User not found' });

    // Add comment to post
    const newComment = {
      userId: user._id,
      comment: comment.trim(),
      commentedAt: new Date()
    };

    if (!post.comments) post.comments = [];
    post.comments.push(newComment);
    await post.save();

    res.json({ success: true, comment: newComment });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to add comment' });
  }
});

// Get comments for a post
app.get('/post/:id/comments', async (req, res) => {
  try {
    const postId = req.params.id;
    const post = await Post.findById(postId).populate({
      path: 'comments.userId',
      select: 'uid name username profileImageUrl'
    });

    if (!post) return res.status(404).json({ error: 'Post not found' });

    // Format comments with user data
    const formattedComments = (post.comments || []).map(comment => ({
      _id: comment._id,
      comment: comment.comment,
      commentedAt: comment.commentedAt,
      user: {
        uid: comment.userId?.uid,
        name: comment.userId?.name,
        username: comment.userId?.username,
        profileImageUrl: comment.userId?.profileImageUrl
      }
    }));

    res.json(formattedComments);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch comments' });
  }
});

// Get all posts for a user (across all portfolios)
app.get('/user/:userId/posts', async (req, res) => {
  try {
    const portfolios = await Portfolio.find({ userId: req.params.userId });
    const portfolioIds = portfolios.map(p => p._id);
    const posts = await Post.find({ portfolioId: { $in: portfolioIds } }).sort({ createdAt: -1 });
    res.json(posts);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch user posts' });
  }
});

// Get all portfolios for a user
app.get('/user/:userId/portfolios', async (req, res) => {
  try {
    const portfolios = await Portfolio.find({ userId: req.params.userId });
    res.json(portfolios);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch user portfolios' });
  }
});

// Check if following a user
app.get('/user/:uid/follow-status', async (req, res) => {
  try {
    const targetUid = req.params.uid;
    const currentUid = req.user.uid;

    const currentUser = await User.findOne({ uid: currentUid });
    const targetUser = await User.findOne({ uid: targetUid });

    if (!currentUser || !targetUser) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if following using ObjectId comparison
    const isFollowing = currentUser.following &&
      currentUser.following.some(id => id.equals(targetUser._id));

    res.json({
      isFollowing,
      followersCount: targetUser.followers ? targetUser.followers.length : 0,
      followingCount: targetUser.following ? targetUser.following.length : 0
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to check follow status' });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));