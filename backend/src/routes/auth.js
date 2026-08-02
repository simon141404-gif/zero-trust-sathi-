const express = require('express');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const { body, validationResult } = require('express-validator');
const { generateAccessToken, generateRefreshToken, authenticate } = require('../middleware/auth');
const { ROLES } = require('../middleware/rbac');
const logger = require('../utils/logger');

const router = express.Router();

// In-memory user store (replace with database in production)
const users = new Map();
// Pre-create admin user
const adminPasswordHash = bcrypt.hashSync('admin123', 10);
users.set('admin-user-id', {
  id: 'admin-user-id',
  username: 'admin',
  passwordHash: adminPasswordHash,
  role: ROLES.ADMIN,
  createdAt: new Date().toISOString(),
});

/**
 * POST /api/auth/register
 * Register a new user
 */
router.post('/register', [
  body('username').isLength({ min: 3, max: 50 }).trim().escape(),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  body('email').isEmail().normalizeEmail(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  
  const { username, password, email } = req.body;
  
  // Check if user exists
  const existingUser = Array.from(users.values()).find(
    u => u.username === username || u.email === email
  );
  if (existingUser) {
    return res.status(409).json({ error: 'User already exists' });
  }
  
  try {
    const passwordHash = await bcrypt.hash(password, 12);
    const userId = uuidv4();
    const user = {
      id: userId,
      username,
      email,
      passwordHash,
      role: ROLES.USER,
      createdAt: new Date().toISOString(),
    };
    
    users.set(userId, user);
    
    logger.info(`New user registered: ${username}`, { userId });
    
    const accessToken = generateAccessToken(userId, ROLES.USER);
    const refreshToken = generateRefreshToken(userId);
    
    res.status(201).json({
      message: 'User registered successfully',
      user: { id: userId, username, email, role: ROLES.USER },
      accessToken,
      refreshToken,
    });
  } catch (error) {
    logger.error('Registration failed', { error: error.message });
    res.status(500).json({ error: 'Registration failed' });
  }
});

/**
 * POST /api/auth/login
 * Login and get tokens
 */
router.post('/login', [
  body('username').notEmpty(),
  body('password').notEmpty(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  
  const { username, password } = req.body;
  
  // Find user
  const user = Array.from(users.values()).find(u => u.username === username);
  if (!user) {
    logger.warn(`Login failed: User not found - ${username}`);
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  
  try {
    const isValidPassword = await bcrypt.compare(password, user.passwordHash);
    if (!isValidPassword) {
      logger.warn(`Login failed: Invalid password for user ${username}`);
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    const accessToken = generateAccessToken(user.id, user.role);
    const refreshToken = generateRefreshToken(user.id);
    
    logger.info(`User logged in: ${username}`, { userId: user.id, role: user.role });
    
    res.json({
      message: 'Login successful',
      user: { id: user.id, username, email: user.email, role: user.role },
      accessToken,
      refreshToken,
    });
  } catch (error) {
    logger.error('Login failed', { error: error.message });
    res.status(500).json({ error: 'Login failed' });
  }
});

/**
 * POST /api/auth/refresh
 * Refresh access token
 */
router.post('/refresh', [
  body('refreshToken').notEmpty(),
], (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  
  const { refreshToken } = req.body;
  
  try {
    const jwt = require('jsonwebtoken');
    const { JWT_SECRET } = require('../middleware/auth');
    const decoded = jwt.verify(refreshToken, JWT_SECRET, { algorithms: ['HS256'] });
    
    if (decoded.type !== 'refresh') {
      return res.status(401).json({ error: 'Invalid token type' });
    }
    
    const user = users.get(decoded.userId);
    if (!user) {
      return res.status(401).json({ error: 'User not found' });
    }
    
    const newAccessToken = generateAccessToken(user.id, user.role);
    
    res.json({ accessToken: newAccessToken });
  } catch (error) {
    logger.warn(`Token refresh failed: ${error.message}`);
    res.status(401).json({ error: 'Invalid or expired refresh token' });
  }
});

/**
 * POST /api/auth/logout
 * Invalidate tokens (client-side token removal recommended)
 */
router.post('/logout', authenticate, (req, res) => {
  // In production, implement token blacklisting or use Redis
  logger.info(`User logged out: ${req.user.userId}`);
  res.json({ message: 'Logged out successfully' });
});

/**
 * GET /api/auth/me
 * Get current user info
 */
router.get('/me', authenticate, (req, res) => {
  const user = users.get(req.user.userId);
  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }
  
  res.json({
    user: {
      id: user.id,
      username: user.username,
      email: user.email,
      role: user.role,
      createdAt: user.createdAt,
    },
  });
});

module.exports = router;
