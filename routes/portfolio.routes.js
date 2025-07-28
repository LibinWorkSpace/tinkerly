const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Portfolio = require('../models/portfolio');
const Post = require('../models/Post');
const Product = require('../models/product');

// Get all portfolios for a user
router.get('/user/:userId', async (req, res) => {
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

// Get a single portfolio by ID
router.get('/:id', async (req, res) => {
  try {
    const portfolio = await Portfolio.findById(req.params.id);
    if (!portfolio) return res.status(404).json({ error: 'Portfolio not found' });
    res.json(portfolio);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch portfolio' });
  }
});

// Create a new portfolio
router.post('/', async (req, res) => {
  try {
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