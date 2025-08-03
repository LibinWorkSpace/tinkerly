const mongoose = require('mongoose');
const crypto = require('crypto');

const otpSchema = new mongoose.Schema({
  identifier: { 
    type: String, 
    required: true, 
    index: true 
  }, // email or phone
  hashedOtp: { 
    type: String, 
    required: true 
  },
  salt: { 
    type: String, 
    required: true 
  },
  type: { 
    type: String, 
    enum: ['registration', 'password_reset', 'phone_verification'], 
    required: true 
  },
  attempts: { 
    type: Number, 
    default: 0, 
    max: 3 
  },
  expiresAt: { 
    type: Date, 
    required: true,
    index: { expireAfterSeconds: 0 } // MongoDB TTL index
  },
  createdAt: { 
    type: Date, 
    default: Date.now 
  },
  ipAddress: String,
  userAgent: String
});

// Hash OTP before saving
otpSchema.methods.hashOtp = function(otp) {
  this.salt = crypto.randomBytes(16).toString('hex');
  this.hashedOtp = crypto.pbkdf2Sync(otp, this.salt, 10000, 64, 'sha512').toString('hex');
};

// Verify OTP
otpSchema.methods.verifyOtp = function(otp) {
  const hash = crypto.pbkdf2Sync(otp, this.salt, 10000, 64, 'sha512').toString('hex');
  return this.hashedOtp === hash;
};

// Static method to create OTP
otpSchema.statics.createOtp = async function(identifier, type, ipAddress, userAgent) {
  // Remove any existing OTPs for this identifier and type
  await this.deleteMany({ identifier, type });
  
  // Generate 6-digit OTP
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  
  const otpDoc = new this({
    identifier,
    type,
    expiresAt: new Date(Date.now() + 10 * 60 * 1000), // 10 minutes
    ipAddress,
    userAgent
  });
  
  otpDoc.hashOtp(otp);
  await otpDoc.save();
  
  return { otp, otpDoc };
};

// Static method to verify OTP
otpSchema.statics.verifyOtp = async function(identifier, otp, type) {
  const otpDoc = await this.findOne({ 
    identifier, 
    type,
    expiresAt: { $gt: new Date() }
  });
  
  if (!otpDoc) {
    return { success: false, error: 'OTP not found or expired' };
  }
  
  if (otpDoc.attempts >= 3) {
    return { success: false, error: 'Too many attempts. Please request a new OTP' };
  }
  
  otpDoc.attempts += 1;
  await otpDoc.save();
  
  if (!otpDoc.verifyOtp(otp)) {
    return { success: false, error: 'Invalid OTP' };
  }
  
  // OTP verified successfully, remove it
  await otpDoc.deleteOne();
  return { success: true };
};

module.exports = mongoose.model('Otp', otpSchema);
