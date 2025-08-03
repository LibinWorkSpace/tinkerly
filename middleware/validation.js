const validator = require('validator');
const rateLimit = require('express-rate-limit');

// Input sanitization middleware
const sanitizeInput = (req, res, next) => {
  const sanitizeString = (str) => {
    if (typeof str !== 'string') return str;
    return validator.escape(str.trim());
  };

  const sanitizeObject = (obj) => {
    if (typeof obj !== 'object' || obj === null) return obj;
    
    const sanitized = {};
    for (const [key, value] of Object.entries(obj)) {
      if (typeof value === 'string') {
        sanitized[key] = sanitizeString(value);
      } else if (typeof value === 'object') {
        sanitized[key] = sanitizeObject(value);
      } else {
        sanitized[key] = value;
      }
    }
    return sanitized;
  };

  if (req.body) {
    req.body = sanitizeObject(req.body);
  }
  
  next();
};

// Email validation
const validateEmail = (email) => {
  if (!email || typeof email !== 'string') {
    return { isValid: false, error: 'Email is required' };
  }
  
  if (!validator.isEmail(email)) {
    return { isValid: false, error: 'Invalid email format' };
  }
  
  if (email.length > 254) {
    return { isValid: false, error: 'Email too long' };
  }
  
  return { isValid: true };
};

// Phone validation
const validatePhone = (phone) => {
  if (!phone || typeof phone !== 'string') {
    return { isValid: false, error: 'Phone number is required' };
  }
  
  // E.164 format validation
  if (!validator.isMobilePhone(phone, 'any', { strictMode: true })) {
    return { isValid: false, error: 'Invalid phone number format. Use international format (+1234567890)' };
  }
  
  return { isValid: true };
};

// Password validation
const validatePassword = (password) => {
  if (!password || typeof password !== 'string') {
    return { isValid: false, error: 'Password is required' };
  }
  
  if (password.length < 8) {
    return { isValid: false, error: 'Password must be at least 8 characters long' };
  }
  
  if (password.length > 128) {
    return { isValid: false, error: 'Password too long' };
  }
  
  if (!validator.isStrongPassword(password, {
    minLength: 8,
    minLowercase: 1,
    minUppercase: 1,
    minNumbers: 1,
    minSymbols: 1
  })) {
    return { 
      isValid: false, 
      error: 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character' 
    };
  }
  
  return { isValid: true };
};

// OTP validation
const validateOtp = (otp) => {
  if (!otp || typeof otp !== 'string') {
    return { isValid: false, error: 'OTP is required' };
  }
  
  if (!/^\d{6}$/.test(otp)) {
    return { isValid: false, error: 'OTP must be 6 digits' };
  }
  
  return { isValid: true };
};

// Username validation
const validateUsername = (username) => {
  if (!username || typeof username !== 'string') {
    return { isValid: false, error: 'Username is required' };
  }
  
  if (username.length < 3 || username.length > 30) {
    return { isValid: false, error: 'Username must be between 3 and 30 characters' };
  }
  
  if (!/^[a-zA-Z0-9_]+$/.test(username)) {
    return { isValid: false, error: 'Username can only contain letters, numbers, and underscores' };
  }
  
  return { isValid: true };
};

// Validation middleware factory
const createValidationMiddleware = (validations) => {
  return (req, res, next) => {
    const errors = [];
    
    for (const [field, validator] of Object.entries(validations)) {
      const value = req.body[field];
      const result = validator(value);
      
      if (!result.isValid) {
        errors.push({ field, message: result.error });
      }
    }
    
    if (errors.length > 0) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors
      });
    }
    
    next();
  };
};

// Portfolio name validation
const validatePortfolioName = (profilename) => {
  if (!profilename || typeof profilename !== 'string') {
    return { isValid: false, error: 'Portfolio name is required' };
  }

  if (profilename.length < 3 || profilename.length > 50) {
    return { isValid: false, error: 'Portfolio name must be between 3 and 50 characters' };
  }

  if (!/^[a-zA-Z0-9_\s-]+$/.test(profilename)) {
    return { isValid: false, error: 'Portfolio name can only contain letters, numbers, spaces, underscores, and hyphens' };
  }

  return { isValid: true };
};

// Async uniqueness validation functions
const checkEmailUnique = async (email) => {
  const User = require('../models/user.model');
  const existingUser = await User.findOne({ email });
  return !existingUser;
};

const checkUsernameUnique = async (username) => {
  const User = require('../models/user.model');
  const existingUser = await User.findOne({ username });
  return !existingUser;
};

const checkPortfolioNameUnique = async (profilename) => {
  const Portfolio = require('../models/portfolio');
  const existingPortfolio = await Portfolio.findOne({ profilename });
  return !existingPortfolio;
};

const checkPortfolioNameUniqueForUser = async (profilename, userId) => {
  const Portfolio = require('../models/portfolio');
  const existingPortfolio = await Portfolio.findOne({ profilename, userId });
  return !existingPortfolio;
};

// Async validation middleware factory
const createAsyncValidationMiddleware = (validations) => {
  return async (req, res, next) => {
    const errors = [];

    for (const [field, validator] of Object.entries(validations)) {
      const value = req.body[field];

      try {
        if (typeof validator === 'function') {
          // Sync validation
          const result = validator(value);
          if (!result.isValid) {
            errors.push({ field, message: result.error });
          }
        } else if (typeof validator === 'object' && validator.asyncCheck) {
          // Async validation
          const syncResult = validator.syncValidator(value);
          if (!syncResult.isValid) {
            errors.push({ field, message: syncResult.error });
          } else {
            // Only check uniqueness if sync validation passes
            const isUnique = await validator.asyncCheck(value);
            if (!isUnique) {
              errors.push({ field, message: validator.uniqueError });
            }
          }
        }
      } catch (error) {
        errors.push({ field, message: 'Validation error occurred' });
      }
    }

    if (errors.length > 0) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors
      });
    }

    next();
  };
};

module.exports = {
  sanitizeInput,
  validateEmail,
  validatePhone,
  validatePassword,
  validateOtp,
  validateUsername,
  validatePortfolioName,
  checkEmailUnique,
  checkUsernameUnique,
  checkPortfolioNameUnique,
  checkPortfolioNameUniqueForUser,
  createValidationMiddleware,
  createAsyncValidationMiddleware
};
