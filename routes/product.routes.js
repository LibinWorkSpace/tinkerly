const express = require('express');
const router = express.Router();
const Product = require('../models/product');

// Get a product by ID
router.get('/:id', async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ error: 'Product not found' });
    res.json(product);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch product' });
  }
});

// Create a new product
router.post('/', async (req, res) => {
  try {
    const product = new Product(req.body);
    await product.save();
    res.status(201).json(product);
  } catch (err) {
    res.status(500).json({ error: 'Failed to create product' });
  }
});

// Update a product
router.put('/:id', async (req, res) => {
  try {
    const product = await Product.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!product) return res.status(404).json({ error: 'Product not found' });
    res.json(product);
  } catch (err) {
    res.status(500).json({ error: 'Failed to update product' });
  }
});

// Delete a product
router.delete('/:id', async (req, res) => {
  try {
    const product = await Product.findByIdAndDelete(req.params.id);
    if (!product) return res.status(404).json({ error: 'Product not found' });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Failed to delete product' });
  }
});

// Get products by user
router.get('/user/:userId', async (req, res) => {
  try {
    const products = await Product.find({ creatorId: req.params.userId });
    res.json(products);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch products for user' });
  }
});

// Get products by post
router.get('/post/:postId', async (req, res) => {
  try {
    const products = await Product.find({ postId: req.params.postId });
    res.json(products);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch products for post' });
  }
});

module.exports = router; 