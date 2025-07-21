const express = require('express');
const router = express.Router();
const otpController = require('../controllers/otp.controller');

// Middleware to verify Firebase token
const verifyToken = async (req, res, next) => {
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
    const idToken = req.headers.authorization.split('Bearer ')[1];
    try {
      const admin = require('../firebase');
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      req.user = decodedToken;
      next();
    } catch (err) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
  } else {
    return res.status(401).json({ error: 'No token provided' });
  }
};

// Public OTP endpoints for registration
router.post('/send-otp', otpController.sendOtp);
router.post('/verify-otp', otpController.verifyOtp);
// Authenticated endpoint for profile phone verification
router.post('/verify-otp-auth', verifyToken, otpController.verifyOtpAuth);
// Authenticated endpoint for changing phone number
router.post('/change-phone', verifyToken, otpController.changePhone);

module.exports = router; 