require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const admin = require('./firebase');
const { parser, cloudinary } = require('./cloudinary');
const Post = require('./models/Post');
const User = require('./models/user.model');
const Otp = require('./models/otp.model');
const nodemailer = require('nodemailer');
const crypto = require('crypto');
const Portfolio = require('./models/portfolio');

// Import security middleware
const { securityHeaders, corsOptions, requestLogger, requestSizeLimiter } = require('./middleware/security');
const { apiLimiter, authLimiter, otpLimiter, passwordResetLimiter } = require('./middleware/rateLimiter');
const {
  sanitizeInput,
  validateEmail,
  validatePassword,
  validateOtp,
  validateUsername,
  validatePortfolioName,
  checkEmailUnique,
  checkUsernameUnique,
  checkPortfolioNameUnique,
  createValidationMiddleware,
  createAsyncValidationMiddleware
} = require('./middleware/validation');

// Deprecated: In-memory OTP stores (will be removed)
const otpStore = {};
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
const PORT = process.env.PORT || 5000;

// Apply security middleware
app.use(securityHeaders);
app.use(cors(corsOptions));
app.use(requestLogger);
// Skip request size limiter for upload endpoints
app.use((req, res, next) => {
  if (req.path === '/upload' || req.path.startsWith('/posts')) {
    return next(); // Skip size limiter for upload routes
  }
  return requestSizeLimiter(req, res, next);
});
app.use(sanitizeInput);
app.use(express.json({ limit: '100mb' })); // Increased for video uploads
app.use(express.urlencoded({ limit: '100mb', extended: true }));

// Apply general rate limiting
app.use('/api/', apiLimiter);

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
app.post('/auth/send-otp', passwordResetLimiter, async (req, res) => {
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

app.post('/auth/reset-password', authLimiter, createValidationMiddleware({
  email: validateEmail,
  otp: validateOtp,
  newPassword: validatePassword
}), async (req, res) => {
  const { email, otp, newPassword } = req.body;

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
app.post('/auth/send-registration-otp', otpLimiter, async (req, res) => {
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

// Public endpoint to check if username exists
app.get('/user/username-exists', async (req, res) => {
  const { username } = req.query;
  if (!username || typeof username !== 'string') {
    return res.status(400).json({ exists: false });
  }
  const user = await User.findOne({ username });
  res.json({ exists: !!user });
});

// Public endpoint to check if phone number exists
app.get('/user/phone-exists', async (req, res) => {
  const { phone } = req.query;
  if (!phone || typeof phone !== 'string') {
    return res.status(400).json({ exists: false });
  }

  // Normalize phone number for consistent checking
  const normalizePhoneNumber = (phone) => {
    if (!phone) return phone;
    let normalized = phone.replace(/[^\d+]/g, '');
    if (!normalized.startsWith('+')) {
      normalized = '+' + normalized;
    }
    return normalized;
  };

  const normalizedPhone = normalizePhoneNumber(phone);
  const user = await User.findOne({ phone: normalizedPhone });
  res.json({ exists: !!user });
});

// Public endpoint to check if portfolio name exists globally
app.get('/portfolio/name-exists', async (req, res) => {
  const { profilename } = req.query;
  if (!profilename || typeof profilename !== 'string') {
    return res.status(400).json({ exists: false });
  }
  const Portfolio = require('./models/portfolio');
  const portfolio = await Portfolio.findOne({ profilename });
  res.json({ exists: !!portfolio });
});

// Public endpoint to check if portfolio name exists for a specific user
app.get('/portfolio/name-exists-for-user', async (req, res) => {
  const { profilename, userId } = req.query;
  if (!profilename || typeof profilename !== 'string' || !userId) {
    return res.status(400).json({ exists: false });
  }
  const Portfolio = require('./models/portfolio');
  const portfolio = await Portfolio.findOne({ profilename, userId });
  res.json({ exists: !!portfolio });
});

// OTP routes
app.use('/otp', otpRoutes);

// Register new portfolio and product routes BEFORE auth middleware
const portfolioRoutes = require('./routes/portfolio.routes');
const productRoutes = require('./routes/product.routes');
console.log('Mounting portfolio routes at /portfolios');
app.use('/portfolios', portfolioRoutes);
console.log('Mounting product routes at /products');
app.use('/products', productRoutes);

// Firebase token verification function
const verifyToken = async (req, res, next) => {
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
};

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

// Upload endpoint
app.post('/upload', parser.single('file'), async (req, res) => {
  try {
    console.log('Upload request received');
    console.log('Content-Length:', req.get('Content-Length'));
    console.log('Content-Type:', req.get('Content-Type'));

    if (!req.file) {
      console.error('No file received in upload request');
      return res.status(400).json({ error: 'No file uploaded' });
    }

    console.log('File details:', {
      originalname: req.file.originalname,
      mimetype: req.file.mimetype,
      size: req.file.size,
      path: req.file.path
    });

    const file = req.file;
    const media = new Media({
      userId: req.user.uid,
      url: file.path,
      type: file.mimetype.startsWith('image') ? 'image' :
            file.mimetype.startsWith('video') ? 'video' :
            file.mimetype.startsWith('audio') ? 'audio' : 'other',
      public_id: file.filename,
    });
    await media.save();
    console.log('File uploaded successfully:', file.path);
    res.json(media);
  } catch (err) {
    console.error('Upload error:', err);
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(413).json({ error: 'File too large. Maximum size is 100MB.' });
    }
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

// Create or update user profile with uniqueness validation
app.post('/user', verifyToken, createAsyncValidationMiddleware({
  email: {
    syncValidator: validateEmail,
    asyncCheck: checkEmailUnique,
    uniqueError: 'Email is already registered'
  },
  username: {
    syncValidator: validateUsername,
    asyncCheck: checkUsernameUnique,
    uniqueError: 'Username is already taken'
  }
}), async (req, res) => {
  try {
    // Log incoming request for debugging
    console.log('=== POST /user REQUEST ===');
    console.log('Body:', req.body);
    console.log('User from token:', req.user);
    console.log('Headers:', req.headers);
    const { name, email, phone, profileImageUrl, categories, username, bio, isPhoneVerified } = req.body;
    const uid = req.user && req.user.uid;
    if (!uid) {
      console.error('POST /user error: Missing uid in req.user');
      return res.status(400).json({ error: 'Missing uid in token' });
    }

    // Check if user already exists by UID (for updates)
    let user = await User.findOne({ uid });
    if (user) {
      // User exists, return existing user data (do not update)
      return res.status(200).json(user);
    }

    // Only include fields that are not null or undefined
    const newUserFields = { uid, name, email, profileImageUrl, categories, username, bio };
    if (phone !== undefined && phone !== null && phone !== '') {
      newUserFields.phone = phone;
    }
    if (isPhoneVerified !== undefined && isPhoneVerified !== null) {
      newUserFields.isPhoneVerified = isPhoneVerified;
    }
    console.log('Creating new user with fields:', newUserFields);
    user = new User(newUserFields);
    await user.save();
    res.status(201).json(user);
  } catch (err) {
    if (err.name === 'MongoServerError' && err.code === 11000) {
      console.error('POST /user duplicate key error:', err);
      // Parse the duplicate key error to provide specific feedback
      let errorMessage = 'Duplicate data detected';
      if (err.message.includes('email')) {
        errorMessage = 'Email is already registered';
      } else if (err.message.includes('username')) {
        errorMessage = 'Username is already taken';
      }
      return res.status(409).json({ error: errorMessage, details: err.message });
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
    console.log('=== FOLLOW REQUEST DEBUG ===');
    console.log('Headers:', req.headers);
    console.log('User from token:', req.user);

    const targetUid = req.params.uid;
    const currentUid = req.user?.uid;

    console.log('Follow request - Target UID:', targetUid, 'Current UID:', currentUid);

    if (!currentUid) {
      console.log('ERROR: No current user UID found');
      return res.status(400).json({ error: 'Authentication failed - no user ID' });
    }

    if (targetUid === currentUid) {
      console.log('ERROR: Trying to follow yourself');
      return res.status(400).json({ error: 'Cannot follow yourself' });
    }

    const targetUser = await User.findOne({ uid: targetUid });
    const currentUser = await User.findOne({ uid: currentUid });

    console.log('Target user found:', !!targetUser, 'Current user found:', !!currentUser);
    if (targetUser) console.log('Target user ID:', targetUser._id);
    if (currentUser) console.log('Current user ID:', currentUser._id);

    if (!targetUser || !currentUser) {
      console.log('ERROR: User not found in database');
      return res.status(404).json({ error: 'User not found' });
    }

    // Initialize arrays if they don't exist
    if (!targetUser.followers) targetUser.followers = [];
    if (!currentUser.following) currentUser.following = [];

    // Check if already following (using ObjectId comparison)
    const isAlreadyFollowing = currentUser.following.some(id => id.equals(targetUser._id));
    console.log('Is already following:', isAlreadyFollowing);

    if (isAlreadyFollowing) {
      console.log('ERROR: Already following this user');
      return res.status(400).json({ error: 'Already following this user' });
    }

    // Add to following/followers lists using ObjectIds
    console.log('Adding to following/followers lists...');
    currentUser.following.push(targetUser._id);
    targetUser.followers.push(currentUser._id);

    console.log('Saving users...');
    await currentUser.save();
    await targetUser.save();

    console.log('Follow successful');
    res.json({ success: true, message: 'User followed successfully' });
  } catch (err) {
    console.error('Follow error:', err);
    console.error('Error stack:', err.stack);
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

// Get a single post by ID (for debugging)
app.get('/post/:id', async (req, res) => {
  try {
    console.log('Getting post with ID:', req.params.id);
    const post = await Post.findById(req.params.id);
    if (!post) {
      console.log('Post not found:', req.params.id);
      return res.status(404).json({ error: 'Post not found' });
    }
    console.log('Post found:', post._id, 'owner:', post.userId);
    res.json(post);
  } catch (err) {
    console.error('Get post error:', err);
    res.status(500).json({ error: 'Failed to get post' });
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
    console.log('=== DELETE POST REQUEST ===');
    console.log('Post ID:', req.params.id);
    console.log('User ID:', req.user.uid);

    const post = await Post.findById(req.params.id);
    console.log('Post found:', !!post);

    if (!post) {
      console.error('Post not found:', req.params.id);
      return res.status(404).json({ error: 'Post not found' });
    }

    console.log('Post owner:', post.userId);
    console.log('Current user:', req.user.uid);

    if (post.userId !== req.user.uid) {
      console.error('Forbidden: user', req.user.uid, 'tried to delete post owned by', post.userId);
      return res.status(403).json({ error: 'Forbidden' });
    }
    // Try to find and delete associated media from Cloudinary
    try {
      console.log('Looking for media with URL:', post.url);

      // Try to extract public_id from Cloudinary URL
      let publicId = null;
      if (post.url && post.url.includes('cloudinary.com')) {
        const urlParts = post.url.split('/');
        const uploadIndex = urlParts.findIndex(part => part === 'upload');
        if (uploadIndex !== -1 && uploadIndex + 2 < urlParts.length) {
          // Get the public_id (filename without extension)
          const filename = urlParts[urlParts.length - 1];
          publicId = filename.split('.')[0];
          // Include folder path if exists
          if (uploadIndex + 3 < urlParts.length) {
            const folder = urlParts.slice(uploadIndex + 2, -1).join('/');
            publicId = folder + '/' + publicId;
          }
        }
      }

      console.log('Extracted public_id:', publicId);

      if (publicId) {
        // Determine resource type based on post mediaType
        const resourceType = post.mediaType === 'video' ? 'video' :
                            post.mediaType === 'audio' ? 'video' : 'image'; // Cloudinary treats audio as video resource type
        console.log('Deleting from Cloudinary - public_id:', publicId, 'resource_type:', resourceType);

        const result = await cloudinary.uploader.destroy(publicId, { resource_type: resourceType });
        console.log('Cloudinary deletion result:', result);
      }

      // Also try to find and delete from Media collection
      const Media = mongoose.model('Media');
      const media = await Media.findOne({ url: post.url });
      if (media) {
        console.log('Found media in DB, deleting:', media.public_id);
        await media.deleteOne();
        console.log('Media deleted from DB.');
      } else {
        console.log('No media record found in DB for URL:', post.url);
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

// Fetch posts for any user by UID (excluding audio posts - they belong in portfolios)
app.get('/posts/user/:uid', async (req, res) => {
  try {
    const { uid } = req.params;
    const posts = await Post.find({
      userId: uid,
      mediaType: { $ne: 'audio' }
    }).sort({ createdAt: -1 });
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

// Get audio posts for a specific user (for music portfolio)
app.get('/posts/user/:uid/audio', async (req, res) => {
  try {
    const { uid } = req.params;
    const audioPosts = await Post.find({
      userId: uid,
      mediaType: 'audio'
    }).sort({ createdAt: -1 }).lean();

    // Attach user info to each post
    const user = await User.findOne({ uid });
    const postsWithUser = audioPosts.map(post => ({
      ...post,
      name: user ? user.name : '',
      username: user ? user.username : '',
      profileImageUrl: user ? user.profileImageUrl : '',
      likedBy: post.likedBy || [],
    }));

    res.json(postsWithUser);
  } catch (err) {
    console.error('Error fetching user audio posts:', err);
    res.status(500).json({ error: 'Failed to fetch user audio posts' });
  }
});

// Get only audio posts for music category
app.get('/posts/audio', async (req, res) => {
  try {
    const audioPosts = await Post.find({ mediaType: 'audio' }).sort({ createdAt: -1 }).lean();

    // Fetch user information for each post
    const userIds = [...new Set(audioPosts.map(post => post.userId))];
    const users = await User.find({ uid: { $in: userIds } });
    const userMap = {};
    users.forEach(user => {
      userMap[user.uid] = user;
    });

    // Add user info to posts
    const postsWithUserInfo = audioPosts.map(post => ({
      ...post,
      username: userMap[post.userId]?.username || 'Unknown User',
      userProfileImage: userMap[post.userId]?.profileImageUrl || null,
    }));

    res.json(postsWithUserInfo);
  } catch (err) {
    console.error('Error fetching audio posts:', err);
    res.status(500).json({ error: 'Failed to fetch audio posts' });
  }
});

// Get feed with portfolio information (excluding audio posts)
app.get('/feed', async (req, res) => {
  try {
    const posts = await Post.find({ mediaType: { $ne: 'audio' } }).sort({ createdAt: -1 }).lean();
    
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

// Start the server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📱 For Android emulator: http://10.0.2.2:${PORT}`);
  console.log(`🌐 For local network: http://192.168.1.4:${PORT}`);
});