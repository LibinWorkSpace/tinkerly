const twilioService = require('../services/twilio.service');

// Send OTP
exports.sendOtp = async (req, res) => {
  const { phone } = req.body;
  console.log('Sending OTP to:', phone);

  try {
    const response = await twilioService.sendOTP(phone);
    console.log('Twilio response:', response);

    res.status(200).json({
      result: true,
      message: 'OTP Sent successfully',
      status: response.status
    });
  } catch (err) {
    console.error('Error sending OTP:', err);
    res.status(500).json({
      result: false,
      message: 'Failed to send OTP',
      error: err.message
    });
  }
};

// Verify OTP (public, pre-registration)
exports.verifyOtp = async (req, res) => {
  const { phone, code } = req.body;

  try {
    const response = await twilioService.verifyOTP(phone, code);
    const isValid = response.status === 'approved';

    if (isValid) {
      // For pre-registration, do NOT update any user in the database!
      return res.status(200).json({
        result: true,
        message: 'OTP Verified successfully',
        status: response.status
      });
    }

    res.status(400).json({
      result: false,
      message: 'Invalid OTP',
      status: response.status
    });
  } catch (err) {
    console.error('Error verifying OTP:', err);
    res.status(500).json({
      result: false,
      message: 'OTP Verification failed',
      error: err.message
    });
  }
};

// Authenticated phone verification for profile
exports.verifyOtpAuth = async (req, res) => {
  const { phone, code } = req.body;
  const userId = req.user.uid;

  try {
    const response = await twilioService.verifyOTP(phone, code);
    const isValid = response.status === 'approved';

    if (isValid) {
      // Update user's phone and isPhoneVerified in DB
      const User = require('../models/user.model');
      const updatedUser = await User.findOneAndUpdate(
        { uid: userId },
        { phone: phone, isPhoneVerified: true },
        { new: true }
      );
      return res.status(200).json({
        result: true,
        message: 'OTP Verified and phone updated',
        user: updatedUser,
        status: response.status
      });
    }

    res.status(400).json({
      result: false,
      message: 'Invalid OTP',
      status: response.status
    });
  } catch (err) {
    console.error('Error verifying OTP (auth):', err);
    res.status(500).json({
      result: false,
      message: 'OTP Verification failed',
      error: err.message
    });
  }
};

// Authenticated phone number change
exports.changePhone = async (req, res) => {
  const { phone, code } = req.body;
  const userId = req.user.uid;

  try {
    const response = await twilioService.verifyOTP(phone, code);
    const isValid = response.status === 'approved';

    if (isValid) {
      const User = require('../models/user.model');
      const updatedUser = await User.findOneAndUpdate(
        { uid: userId },
        { phone: phone, isPhoneVerified: true },
        { new: true }
      );
      return res.status(200).json({
        result: true,
        message: 'Phone number changed and verified',
        user: updatedUser,
        status: response.status
      });
    }

    res.status(400).json({
      result: false,
      message: 'Invalid OTP',
      status: response.status
    });
  } catch (err) {
    console.error('Error changing phone:', err);
    res.status(500).json({
      result: false,
      message: 'Phone change failed',
      error: err.message
    });
  }
}; 