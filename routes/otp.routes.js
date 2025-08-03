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

// Test endpoint to check Twilio configuration
router.get('/test-twilio', (req, res) => {
  const hasAccountSid = !!process.env.TWILIO_ACCOUNT_SID;
  const hasAuthToken = !!process.env.TWILIO_AUTH_TOKEN;
  const hasServiceSid = !!process.env.TWILIO_SERVICE_SID;

  res.json({
    twilioConfigured: hasAccountSid && hasAuthToken && hasServiceSid,
    accountSid: hasAccountSid ? 'Set' : 'Missing',
    authToken: hasAuthToken ? 'Set' : 'Missing',
    serviceSid: hasServiceSid ? 'Set' : 'Missing',
    accountSidLength: process.env.TWILIO_ACCOUNT_SID?.length || 0,
    serviceSidLength: process.env.TWILIO_SERVICE_SID?.length || 0
  });
});

// Check user's phone verification status
router.get('/phone-status', verifyToken, async (req, res) => {
  try {
    const User = require('../models/user.model');
    const user = await User.findOne({ uid: req.user.uid });

    res.json({
      hasPhone: !!user?.phone,
      phone: user?.phone,
      isPhoneVerified: user?.isPhoneVerified || false,
      userId: req.user.uid
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Public OTP endpoints for registration
router.post('/send-otp', otpController.sendOtp);
router.post('/verify-otp', otpController.verifyOtp);
// Authenticated endpoint for profile phone verification
router.post('/verify-otp-auth', verifyToken, otpController.verifyOtpAuth);
// Authenticated endpoint for changing phone number
router.post('/change-phone', verifyToken, otpController.changePhone);

module.exports = router; 