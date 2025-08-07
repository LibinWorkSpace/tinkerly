const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Portfolio = require('../models/portfolio');
const Post = require('../models/Post');
const Product = require('../models/product');
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
    console.log('Fetching portfolios for userId:', req.params.userId);
    const portfolios = await Portfolio.find({ userId: req.params.userId });
    console.log('Found portfolios:', portfolios.length);
    res.json(portfolios);
  } catch (err) {
    console.error('Error fetching portfolios:', err);
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

    // Check global uniqueness
    const isGloballyUnique = await checkPortfolioNameUnique(profilename);
    if (!isGloballyUnique) {
      return res.status(409).json({ error: 'Portfolio name is already taken by another user' });
    }

    // Check uniqueness for this user
    const isUniqueForUser = await checkPortfolioNameUniqueForUser(profilename, userId);
    if (!isUniqueForUser) {
      return res.status(409).json({ error: 'You already have a portfolio with this name' });
    }
    console.log('Creating portfolio with data:', req.body);
    const portfolio = new Portfolio(req.body);
    await portfolio.save();
    console.log('Portfolio created successfully:', portfolio._id);

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

module.exports = router;