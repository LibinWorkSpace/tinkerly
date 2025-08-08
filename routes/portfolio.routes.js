const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Portfolio = require('../models/portfolio');
const Post = require('../models/Post');
const Product = require('../models/product');
const User = require('../models/user.model');
const admin = require('../firebase');
const {
  validatePortfolioName,
  checkPortfolioNameUnique,
  checkPortfolioNameUniqueForUser,
  createAsyncValidationMiddleware
} = require('../middleware/validation');

// Firebase Auth middleware for protected routes
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

// Search portfolios by name or category (MUST be before /:id route)
router.get('/search', async (req, res) => {
  try {
    console.log('Portfolio search request received:', req.query);
    const { query } = req.query;
    if (!query || query.trim() === '') {
      console.log('Empty query, returning empty array');
      return res.json([]);
    }

    console.log('Searching portfolios with query:', query);
    // Case-insensitive, partial match on profilename, category, or description
    const portfolios = await Portfolio.find({
      $or: [
        { profilename: { $regex: query, $options: 'i' } },
        { category: { $regex: query, $options: 'i' } },
        { description: { $regex: query, $options: 'i' } }
      ],
    }).select('profilename category description profileImageUrl userId createdAt'); // Only public fields

    console.log('Found portfolios:', portfolios.length);
    res.json(portfolios);
  } catch (err) {
    console.error('Error searching portfolios:', err);
    res.status(500).json({ error: 'Failed to search portfolios', details: err.message });
  }
});

// Get all portfolios for a user (protected)
router.get('/user/:userId', verifyToken, async (req, res) => {
  try {
    console.log('📁 Fetching portfolios for userId (portfolio routes):', req.params.userId);
    const portfolios = await Portfolio.find({ userId: req.params.userId });
    console.log('📁 Found portfolios (portfolio routes):', portfolios.length);
    console.log('📁 Portfolio details:', portfolios.map(p => ({ id: p._id, name: p.profilename, category: p.category })));
    res.json(portfolios);
  } catch (err) {
    console.error('📁 Error fetching portfolios (portfolio routes):', err);
    res.status(500).json({ error: 'Failed to fetch portfolios', details: err.message });
  }
});

// Get a single portfolio by ID (public for now)
router.get('/:id', async (req, res) => {
  try {
    const portfolio = await Portfolio.findById(req.params.id);
    if (!portfolio) return res.status(404).json({ error: 'Portfolio not found' });
    res.json(portfolio);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch portfolio' });
  }
});

// Create a new portfolio with uniqueness validation
router.post('/', async (req, res) => {
  try {
    const { profilename, userId } = req.body;

    // Validate portfolio name format
    const nameValidation = validatePortfolioName(profilename);
    if (!nameValidation.isValid) {
      return res.status(400).json({ error: nameValidation.error });
    }

    // Check global uniqueness (with exception for default category names)
    const isGloballyUnique = await checkPortfolioNameUnique(profilename);
    if (!isGloballyUnique) {
      return res.status(409).json({ error: 'Portfolio name is already taken by another user' });
    }

    // Check uniqueness for this user
    const isUniqueForUser = await checkPortfolioNameUniqueForUser(profilename, userId);
    if (!isUniqueForUser) {
      return res.status(409).json({ error: 'You already have a portfolio with this name' });
    }
    console.log('📁 Creating portfolio with data:', req.body);
    const portfolio = new Portfolio(req.body);
    await portfolio.save();
    console.log('📁 Portfolio created successfully:', portfolio._id);
    console.log('📁 Portfolio details:', {
      id: portfolio._id,
      userId: portfolio.userId,
      profilename: portfolio.profilename,
      category: portfolio.category
    });

    // Also update the user's portfolioIds array
    const User = require('../models/user.model');
    try {
      await User.findOneAndUpdate(
        { uid: req.body.userId },
        { $addToSet: { portfolioIds: portfolio._id } }
      );
      console.log('Updated user portfolioIds for userId:', req.body.userId);
    } catch (userUpdateErr) {
      console.error('Failed to update user portfolioIds:', userUpdateErr);
      // Don't fail the portfolio creation if user update fails
    }

    res.status(201).json(portfolio);
  } catch (err) {
    console.error('Error creating portfolio:', err);
    if (err.name === 'MongoServerError' && err.code === 11000) {
      // Parse the duplicate key error to provide specific feedback
      let errorMessage = 'Portfolio name is already taken';
      if (err.message.includes('userId_1_profilename_1')) {
        errorMessage = 'You already have a portfolio with this name';
      } else if (err.message.includes('profilename_1')) {
        errorMessage = 'Portfolio name is already taken by another user';
      }
      return res.status(409).json({ error: errorMessage, details: err.message });
    }
    res.status(500).json({ error: 'Failed to create portfolio', details: err.message });
  }
});

// Update a portfolio
router.put('/:id', async (req, res) => {
  try {
    console.log('Updating portfolio:', req.params.id, 'with data:', req.body);
    
    // Add updatedAt timestamp
    const updateData = {
      ...req.body,
      updatedAt: new Date()
    };
    
    const portfolio = await Portfolio.findByIdAndUpdate(req.params.id, updateData, { new: true });
    if (!portfolio) {
      console.log('Portfolio not found:', req.params.id);
      return res.status(404).json({ error: 'Portfolio not found' });
    }
    
    console.log('Portfolio updated successfully:', portfolio._id);
    res.json(portfolio);
  } catch (err) {
    console.error('Error updating portfolio:', err);
    res.status(500).json({ error: 'Failed to update portfolio', details: err.message });
  }
});

// Delete a portfolio
router.delete('/:id', async (req, res) => {
  try {
    const portfolio = await Portfolio.findByIdAndDelete(req.params.id);
    if (!portfolio) return res.status(404).json({ error: 'Portfolio not found' });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Failed to delete portfolio' });
  }
});

// Get posts for a portfolio
router.get('/:id/posts', async (req, res) => {
  try {
    const posts = await Post.find({ portfolioId: req.params.id });
    res.json(posts);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch posts for portfolio' });
  }
});

// Get products for a portfolio
router.get('/:id/products', async (req, res) => {
  try {
    const posts = await Post.find({ portfolioId: req.params.id });
    const postIds = posts.map(post => post._id);
    const products = await Product.find({ postId: { $in: postIds } });
    res.json(products);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch products for portfolio' });
  }
});

// Get a portfolio with its posts and products
router.get('/:id/full', async (req, res) => {
  try {
    console.log('Fetching full portfolio data for ID:', req.params.id);
    
    const portfolio = await Portfolio.findById(req.params.id).lean();
    if (!portfolio) {
      console.log('Portfolio not found:', req.params.id);
      return res.status(404).json({ error: 'Portfolio not found' });
    }
    
    console.log('Portfolio found:', portfolio.profilename);
    
    const posts = await Post.find({ portfolioId: req.params.id });
    console.log('Posts found for portfolio:', posts.length);
    
    const postIds = posts.map(post => post._id);
    const products = await Product.find({ postId: { $in: postIds } });
    console.log('Products found for posts:', products.length);
    
    const result = { ...portfolio, posts, products };
    console.log('Returning portfolio data with posts:', posts.length, 'and products:', products.length);
    
    res.json(result);
  } catch (err) {
    console.error('Error fetching portfolio details:', err);
    res.status(500).json({ error: 'Failed to fetch portfolio details' });
  }
});

// Get followers for a portfolio
router.get('/:id/followers', async (req, res) => {
  try {
    const portfolio = await Portfolio.findById(req.params.id).populate('followers', 'name username profileImageUrl');
    if (!portfolio) return res.status(404).json({ error: 'Portfolio not found' });
    res.json(portfolio.followers);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch followers' });
  }
});

// Follow a portfolio (protected)
router.post('/:id/follow', verifyToken, async (req, res) => {
  try {
    console.log('=== PORTFOLIO FOLLOW REQUEST DEBUG ===');
    console.log('Portfolio ID:', req.params.id);
    console.log('Current user UID:', req.user?.uid);

    const portfolioId = req.params.id;
    const currentUid = req.user?.uid;

    if (!currentUid) {
      console.log('ERROR: No current user UID found');
      return res.status(400).json({ error: 'Authentication failed - no user ID' });
    }

    // Find the portfolio and current user
    const portfolio = await Portfolio.findById(portfolioId);
    const currentUser = await User.findOne({ uid: currentUid });

    if (!portfolio) {
      console.log('ERROR: Portfolio not found:', portfolioId);
      return res.status(404).json({ error: 'Portfolio not found' });
    }

    if (!currentUser) {
      console.log('ERROR: Current user not found:', currentUid);
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if user is trying to follow their own portfolio
    if (portfolio.userId === currentUid) {
      console.log('ERROR: Trying to follow own portfolio');
      return res.status(400).json({ error: 'Cannot follow your own portfolio' });
    }

    // Check if already following
    const isAlreadyFollowing = portfolio.followers.some(followerId =>
      followerId.equals(currentUser._id)
    );

    if (isAlreadyFollowing) {
      console.log('ERROR: Already following this portfolio');
      return res.status(400).json({ error: 'Already following this portfolio' });
    }

    // Add current user to portfolio's followers list
    console.log(`\n➕ FOLLOW DEBUG:`);
    console.log(`- User ${currentUid} following portfolio ${portfolioId}`);
    console.log(`- Portfolio followers before: [${portfolio.followers.map(id => id.toString()).join(', ')}]`);

    portfolio.followers.push(currentUser._id);
    await portfolio.save();

    console.log(`- Portfolio followers after: [${portfolio.followers.map(id => id.toString()).join(', ')}]`);
    console.log('✅ Portfolio follow successful');
    res.json({
      success: true,
      message: 'Portfolio followed successfully',
      followersCount: portfolio.followers.length
    });
  } catch (err) {
    console.error('Portfolio follow error:', err);
    res.status(500).json({ error: 'Failed to follow portfolio', details: err.message });
  }
});

// Unfollow a portfolio (protected)
router.post('/:id/unfollow', verifyToken, async (req, res) => {
  try {
    console.log('=== PORTFOLIO UNFOLLOW REQUEST DEBUG ===');
    console.log('Portfolio ID:', req.params.id);
    console.log('Current user UID:', req.user?.uid);

    const portfolioId = req.params.id;
    const currentUid = req.user?.uid;

    if (!currentUid) {
      return res.status(400).json({ error: 'Authentication failed - no user ID' });
    }

    // Find the portfolio and current user
    const portfolio = await Portfolio.findById(portfolioId);
    const currentUser = await User.findOne({ uid: currentUid });

    if (!portfolio) {
      return res.status(404).json({ error: 'Portfolio not found' });
    }

    if (!currentUser) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if currently following
    const isCurrentlyFollowing = portfolio.followers.some(followerId =>
      followerId.equals(currentUser._id)
    );

    if (!isCurrentlyFollowing) {
      return res.status(400).json({ error: 'Not currently following this portfolio' });
    }

    // Remove current user from portfolio's followers list
    console.log(`\n🔄 UNFOLLOW DEBUG:`);
    console.log(`- User ${currentUid} unfollowing portfolio ${portfolioId}`);
    console.log(`- Portfolio followers before: [${portfolio.followers.map(id => id.toString()).join(', ')}]`);

    portfolio.followers = portfolio.followers.filter(followerId =>
      !followerId.equals(currentUser._id)
    );
    await portfolio.save();

    console.log(`- Portfolio followers after: [${portfolio.followers.map(id => id.toString()).join(', ')}]`);
    console.log('✅ Portfolio unfollow successful');
    res.json({
      success: true,
      message: 'Portfolio unfollowed successfully',
      followersCount: portfolio.followers.length
    });
  } catch (err) {
    console.error('Portfolio unfollow error:', err);
    res.status(500).json({ error: 'Failed to unfollow portfolio', details: err.message });
  }
});

// Check portfolio follow status (protected)
router.get('/:id/follow-status', verifyToken, async (req, res) => {
  try {
    const portfolioId = req.params.id;
    const currentUid = req.user?.uid;

    if (!currentUid) {
      return res.status(400).json({ error: 'Authentication failed - no user ID' });
    }

    const portfolio = await Portfolio.findById(portfolioId);
    const currentUser = await User.findOne({ uid: currentUid });

    if (!portfolio) {
      return res.status(404).json({ error: 'Portfolio not found' });
    }

    if (!currentUser) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if following using ObjectId comparison
    const isFollowing = portfolio.followers.some(followerId =>
      followerId.equals(currentUser._id)
    );

    res.json({
      isFollowing,
      followersCount: portfolio.followers.length,
      canFollow: portfolio.userId !== currentUid // Can't follow own portfolio
    });
  } catch (err) {
    console.error('Portfolio follow status error:', err);
    res.status(500).json({ error: 'Failed to check follow status', details: err.message });
  }
});

// Get portfolio followers list
router.get('/:id/followers', verifyToken, async (req, res) => {
  try {
    const portfolioId = req.params.id;
    const currentUid = req.user?.uid;

    const portfolio = await Portfolio.findById(portfolioId).populate('followers');
    if (!portfolio) {
      return res.status(404).json({ error: 'Portfolio not found' });
    }

    const currentUser = await User.findOne({ uid: currentUid });

    // Get detailed follower information
    const followers = await User.find({
      _id: { $in: portfolio.followers }
    }).select('uid name username profileImageUrl followers following bio');

    // Add mutual connection info and follow status
    const followersWithInfo = followers.map(follower => {
      const mutualConnections = follower.following ?
        follower.following.filter(id =>
          currentUser.following && currentUser.following.some(myFollowId => myFollowId.equals(id))
        ).length : 0;

      const isFollowingBack = currentUser.following &&
        currentUser.following.some(id => id.equals(follower._id));

      return {
        uid: follower.uid,
        name: follower.name,
        username: follower.username,
        profileImageUrl: follower.profileImageUrl,
        bio: follower.bio,
        followersCount: follower.followers ? follower.followers.length : 0,
        followingCount: follower.following ? follower.following.length : 0,
        mutualConnections,
        isFollowingBack,
        isCurrentUser: follower.uid === currentUid
      };
    });

    res.json({
      portfolio: {
        _id: portfolio._id,
        profilename: portfolio.profilename,
        category: portfolio.category,
        profileImageUrl: portfolio.profileImageUrl,
        followersCount: portfolio.followers.length
      },
      followers: followersWithInfo
    });
  } catch (err) {
    console.error('Error fetching portfolio followers:', err);
    res.status(500).json({ error: 'Failed to fetch portfolio followers' });
  }
});

// Get user's followed portfolios
router.get('/user/:userId/followed', verifyToken, async (req, res) => {
  try {
    const targetUserId = req.params.userId;
    const currentUid = req.user?.uid;

    const currentUser = await User.findOne({ uid: currentUid });
    if (!currentUser) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Get portfolios that the current user follows
    const followedPortfolios = await Portfolio.find({
      followers: { $in: [currentUser._id] }
    }).populate('userId', 'uid name username profileImageUrl');

    // Add additional info to each portfolio
    const portfoliosWithInfo = followedPortfolios.map(portfolio => ({
      _id: portfolio._id,
      profilename: portfolio.profilename,
      category: portfolio.category,
      profileImageUrl: portfolio.profileImageUrl,
      description: portfolio.description,
      followersCount: portfolio.followers ? portfolio.followers.length : 0,
      owner: {
        uid: portfolio.userId.uid,
        name: portfolio.userId.name,
        username: portfolio.userId.username,
        profileImageUrl: portfolio.userId.profileImageUrl
      },
      createdAt: portfolio.createdAt
    }));

    res.json(portfoliosWithInfo);
  } catch (err) {
    console.error('Error fetching followed portfolios:', err);
    res.status(500).json({ error: 'Failed to fetch followed portfolios' });
  }
});

module.exports = router;