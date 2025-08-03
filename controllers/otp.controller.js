const twilioService = require('../services/twilio.service');

// Normalize phone number to E.164 format
function normalizePhoneNumber(phone) {
  if (!phone) return phone;

  // Remove all non-digit characters except the leading +
  let normalized = phone.replace(/[^\d+]/g, '');

  // Ensure it starts with +
  if (!normalized.startsWith('+')) {
    normalized = '+' + normalized;
  }

  return normalized;
}

// Send OTP
exports.sendOtp = async (req, res) => {
  const { phone } = req.body;
  console.log('=== SENDING OTP ===');
  console.log('Original phone:', phone);
  console.log('Phone type:', typeof phone);
  console.log('Phone length:', phone?.length);

  const normalizedPhone = normalizePhoneNumber(phone);
  console.log('Normalized phone:', normalizedPhone);

  try {
    const response = await twilioService.sendOTP(normalizedPhone);
    console.log('Twilio send response:', response);
    console.log('Response status:', response.status);
    console.log('Response SID:', response.sid);

    res.status(200).json({
      result: true,
      message: 'OTP Sent successfully',
      status: response.status,
      normalizedPhone: normalizedPhone // Return normalized phone for frontend to use
    });
  } catch (err) {
    console.error('Error sending OTP:', err);
    console.error('Error details:', err.message);
    console.error('Error code:', err.code);
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

  console.log('=== OTP VERIFICATION AUTH ===');
  console.log('Original phone:', phone);
  console.log('Code:', code);
  console.log('User ID:', userId);

  const normalizedPhone = normalizePhoneNumber(phone);
  console.log('Normalized phone:', normalizedPhone);

  try {
    const response = await twilioService.verifyOTP(normalizedPhone, code);
    console.log('Twilio verification response:', response);
    console.log('Response status:', response.status);

    const isValid = response.status === 'approved';
    console.log('Is valid:', isValid);

    if (isValid) {
      const User = require('../models/user.model');

      // Check if this is the current user's phone number
      const currentUser = await User.findOne({ uid: userId });
      if (currentUser && currentUser.phone === normalizedPhone) {
        console.log('User is verifying their existing phone number');
        // Just update the verification status
        const updatedUser = await User.findOneAndUpdate(
          { uid: userId },
          { isPhoneVerified: true },
          { new: true }
        );
        console.log('User phone verification updated:', updatedUser?.uid);
        return res.status(200).json({
          result: true,
          message: 'Phone number verified successfully',
          user: updatedUser,
          status: response.status
        });
      }

      // Check if phone number is already used by another user
      const existingUser = await User.findOne({
        phone: normalizedPhone,
        uid: { $ne: userId }
      });

      if (existingUser) {
        console.log('Phone number already in use by another user:', existingUser.uid);
        return res.status(400).json({
          result: false,
          message: 'This phone number is already registered to another account',
          status: 'phone_already_exists'
        });
      }

      // Update user's phone and isPhoneVerified in DB (new phone number)
      const updatedUser = await User.findOneAndUpdate(
        { uid: userId },
        { phone: normalizedPhone, isPhoneVerified: true },
        { new: true }
      );
      console.log('User updated with new phone number:', updatedUser?.uid);
      return res.status(200).json({
        result: true,
        message: 'OTP Verified and phone updated',
        user: updatedUser,
        status: response.status
      });
    }

    console.log('OTP verification failed - status not approved');
    res.status(400).json({
      result: false,
      message: 'Invalid OTP',
      status: response.status
    });
  } catch (err) {
    console.error('Error verifying OTP (auth):', err);
    console.error('Error details:', err.message);
    console.error('Error code:', err.code);
    console.error('Error status:', err.status);

    // Handle specific Twilio errors
    if (err.code === 20404) {
      return res.status(400).json({
        result: false,
        message: 'OTP has expired or is invalid. Please request a new OTP.',
        error: 'otp_expired'
      });
    }

    if (err.code === 20403) {
      return res.status(400).json({
        result: false,
        message: 'Invalid OTP. Please check and try again.',
        error: 'invalid_otp'
      });
    }

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

  console.log('=== CHANGE PHONE ===');
  console.log('Original phone:', phone);
  console.log('Code:', code);
  console.log('User ID:', userId);

  const normalizedPhone = normalizePhoneNumber(phone);
  console.log('Normalized phone:', normalizedPhone);

  try {
    const response = await twilioService.verifyOTP(normalizedPhone, code);
    const isValid = response.status === 'approved';

    if (isValid) {
      const User = require('../models/user.model');
      const updatedUser = await User.findOneAndUpdate(
        { uid: userId },
        { phone: normalizedPhone, isPhoneVerified: true },
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