const logger = require('../utils/logger');

// In-memory rate limiting storage
const rateLimitStore = new Map();

/**
 * Rate Limiter Configuration
 * 100 requests per 15 minutes per IP
 */
const RATE_LIMIT_WINDOW = 15 * 60 * 1000; // 15 minutes in milliseconds
const RATE_LIMIT_MAX_REQUESTS = 100; // 100 requests per window

/**
 * Clean up expired entries from rate limit store
 */
const cleanupExpiredEntries = () => {
  const now = Date.now();
  for (const [key, value] of rateLimitStore.entries()) {
    if (now - value.timestamp > RATE_LIMIT_WINDOW) {
      rateLimitStore.delete(key);
    }
  }
};

// Run cleanup every 5 minutes
setInterval(cleanupExpiredEntries, 5 * 60 * 1000);

/**
 * Rate limiter middleware
 * Limits requests to 100 per 15 minutes per IP
 */
const rateLimiter = (req, res, next) => {
  const clientIp = req.ip || req.connection.remoteAddress || 'unknown';
  const now = Date.now();
  
  // Get or create rate limit record for this IP
  let record = rateLimitStore.get(clientIp);
  
  if (!record) {
    // First request from this IP
    record = {
      timestamp: now,
      count: 1,
    };
    rateLimitStore.set(clientIp, record);
    next();
    return;
  }
  
  // Check if request is within the time window
  if (now - record.timestamp > RATE_LIMIT_WINDOW) {
    // Reset the window
    record.timestamp = now;
    record.count = 1;
    next();
    return;
  }
  
  // Increment request count
  record.count++;
  
  // Check if rate limit exceeded
  if (record.count > RATE_LIMIT_MAX_REQUESTS) {
    const retryAfter = Math.ceil((record.timestamp + RATE_LIMIT_WINDOW - now) / 1000);
    
    logger.warn(`Rate limit exceeded for IP: ${clientIp}`, {
      ip: clientIp,
      count: record.count,
      limit: RATE_LIMIT_MAX_REQUESTS,
      window: '15 minutes',
    });
    
    return res.status(429).json({
      error: 'Too many requests',
      message: `Rate limit exceeded. Maximum ${RATE_LIMIT_MAX_REQUESTS} requests per 15 minutes.`,
      retryAfter: retryAfter,
      limit: RATE_LIMIT_MAX_REQUESTS,
      window: '15 minutes',
    });
  }
  
  // Add rate limit headers to response
  res.set('X-RateLimit-Limit', RATE_LIMIT_MAX_REQUESTS);
  res.set('X-RateLimit-Remaining', Math.max(0, RATE_LIMIT_MAX_REQUESTS - record.count));
  res.set('X-RateLimit-Reset', Math.ceil((record.timestamp + RATE_LIMIT_WINDOW) / 1000));
  
  next();
};

module.exports = {
  rateLimiter,
  RATE_LIMIT_WINDOW,
  RATE_LIMIT_MAX_REQUESTS,
};
