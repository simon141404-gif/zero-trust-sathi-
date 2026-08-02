const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { body, validationResult } = require('express-validator');
const { authenticate } = require('../middleware/auth');
const { rbacMiddleware, PERMISSIONS } = require('../middleware/rbac');
const logger = require('../utils/logger');

const router = express.Router();

// In-memory file storage (replace with actual storage in production)
const files = new Map();

/**
 * GET /api/storage
 * List all files for the user
 */
router.get('/', authenticate, rbacMiddleware(PERMISSIONS.STORAGE_READ), (req, res) => {
  const userFiles = Array.from(files.values()).filter(f => f.ownerId === req.user.userId);
  
  res.json({
    files: userFiles.map(f => ({
      id: f.id,
      name: f.name,
      size: f.size,
      mimeType: f.mimeType,
      encryptedKey: f.encryptedKey,
      createdAt: f.createdAt,
      updatedAt: f.updatedAt,
    })),
  });
});

/**
 * POST /api/storage
 * Upload a new file (metadata)
 */
router.post('/',
  authenticate,
  rbacMiddleware(PERMISSIONS.STORAGE_WRITE),
  [
    body('name').isLength({ min: 1, max: 255 }).trim(),
    body('size').isInt({ min: 0 }),
    body('mimeType').isLength({ min: 1, max: 100 }),
    body('encryptedKey').isLength({ min: 1 }),
  ],
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { name, size, mimeType, encryptedKey } = req.body;
    
    const fileId = uuidv4();
    const file = {
      id: fileId,
      name,
      size,
      mimeType,
      encryptedKey, // In production, store encrypted file encryption key
      ownerId: req.user.userId,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    
    files.set(fileId, file);
    
    logger.info(`File uploaded: ${name}`, { fileId, userId: req.user.userId });
    
    res.status(201).json({
      message: 'File uploaded successfully',
      file: {
        id: file.id,
        name: file.name,
        size: file.size,
        mimeType: file.mimeType,
        createdAt: file.createdAt,
      },
    });
  }
);

/**
 * GET /api/storage/:id
 * Get file details
 */
router.get('/:id', 
  authenticate, 
  rbacMiddleware(PERMISSIONS.STORAGE_READ),
  (req, res) => {
    const file = files.get(req.params.id);
    
    if (!file) {
      return res.status(404).json({ error: 'File not found' });
    }
    
    // Check ownership or admin
    if (file.ownerId !== req.user.userId && req.user.role !== 'admin') {
      logger.warn(`File access denied: ${req.params.id}`, { userId: req.user.userId });
      return res.status(403).json({ error: 'Access denied' });
    }
    
    res.json({
      file: {
        id: file.id,
        name: file.name,
        size: file.size,
        mimeType: file.mimeType,
        encryptedKey: file.encryptedKey,
        createdAt: file.createdAt,
        updatedAt: file.updatedAt,
      },
    });
  }
);

/**
 * DELETE /api/storage/:id
 * Delete a file
 */
router.delete('/:id',
  authenticate,
  rbacMiddleware(PERMISSIONS.STORAGE_DELETE),
  (req, res) => {
    const file = files.get(req.params.id);
    
    if (!file) {
      return res.status(404).json({ error: 'File not found' });
    }
    
    // Check ownership or admin
    if (file.ownerId !== req.user.userId && req.user.role !== 'admin') {
      logger.warn(`File delete denied: ${req.params.id}`, { userId: req.user.userId });
      return res.status(403).json({ error: 'Access denied' });
    }
    
    files.delete(req.params.id);
    
    logger.info(`File deleted: ${req.params.id}`, { userId: req.user.userId });
    
    res.json({ message: 'File deleted successfully' });
  }
);

/**
 * PUT /api/storage/:id
 * Update file metadata
 */
router.put('/:id',
  authenticate,
  rbacMiddleware(PERMISSIONS.STORAGE_WRITE),
  [
    body('name').optional().isLength({ min: 1, max: 255 }).trim(),
  ],
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const file = files.get(req.params.id);
    
    if (!file) {
      return res.status(404).json({ error: 'File not found' });
    }
    
    // Check ownership
    if (file.ownerId !== req.user.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    const { name } = req.body;
    if (name) file.name = name;
    file.updatedAt = new Date().toISOString();
    
    files.set(req.params.id, file);
    
    logger.info(`File updated: ${req.params.id}`, { userId: req.user.userId });
    
    res.json({
      message: 'File updated successfully',
      file: {
        id: file.id,
        name: file.name,
        updatedAt: file.updatedAt,
      },
    });
  }
);

module.exports = router;
