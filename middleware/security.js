const cors = require('cors');

// Basic security headers middleware (simplified version)
const securityHeaders = (req, res, next) => {
  // Basic security headers
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');

  // HSTS header for HTTPS
  if (req.secure || req.headers['x-forwarded-proto'] === 'https') {
    res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains; preload');
  }

  next();
};

// CORS configuration
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);

    // Get allowed origins from environment variable
    const allowedOrigins = process.env.ALLOWED_ORIGINS
      ? process.env.ALLOWED_ORIGINS.split(',').map(origin => origin.trim())
      : ['http://localhost:3000'];

    if (process.env.NODE_ENV === 'development') {
      // In development, allow localhost with any port
      if (origin.startsWith('http://localhost:') || origin.startsWith('http://127.0.0.1:')) {
        return callback(null, true);
      }
    }

    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      console.warn(`CORS blocked request from origin: ${origin}`);
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  maxAge: 86400 // 24 hours
};

// Request logging middleware
const requestLogger = (req, res, next) => {
  const start = Date.now();
  const originalSend = res.send;
  
  res.send = function(data) {
    const duration = Date.now() - start;
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path} - ${res.statusCode} - ${duration}ms - IP: ${req.ip}`);
    originalSend.call(this, data);
  };
  
  next();
};

// IP whitelist middleware (for admin endpoints)
const ipWhitelist = (allowedIPs) => {
  return (req, res, next) => {
    const clientIP = req.ip || req.connection.remoteAddress;
    
    if (allowedIPs.includes(clientIP)) {
      next();
    } else {
      res.status(403).json({ error: 'Access denied from this IP address' });
    }
  };
};

// Request size limiter
const requestSizeLimiter = (req, res, next) => {
  const contentLength = parseInt(req.get('Content-Length'));
  const maxSize = 100 * 1024 * 1024; // 100MB for video uploads

  if (contentLength > maxSize) {
    return res.status(413).json({ error: 'Request entity too large. Maximum file size is 100MB.' });
  }

  next();
};

module.exports = {
  securityHeaders,
  corsOptions,
  requestLogger,
  ipWhitelist,
  requestSizeLimiter
};
