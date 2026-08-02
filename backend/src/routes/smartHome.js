const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { body, validationResult } = require('express-validator');
const { authenticate } = require('../middleware/auth');
const { rbacMiddleware, PERMISSIONS } = require('../middleware/rbac');
const logger = require('../utils/logger');

const router = express.Router();

// In-memory device store (replace with database in production)
const devices = new Map();

// Initialize with sample devices
const sampleDevices = [
  {
    id: 'device-1',
    name: 'Living Room Light',
    type: 'light',
    status: 'off',
    ownerId: 'admin-user-id',
    settings: { brightness: 100, color: '#ffffff' },
    createdAt: new Date().toISOString(),
  },
  {
    id: 'device-2',
    name: 'Smart Thermostat',
    type: 'thermostat',
    status: 'on',
    ownerId: 'admin-user-id',
    settings: { temperature: 72, mode: 'auto' },
    createdAt: new Date().toISOString(),
  },
  {
    id: 'device-3',
    name: 'Front Door Lock',
    type: 'lock',
    status: 'locked',
    ownerId: 'admin-user-id',
    settings: { autoLock: true, code: '****' },
    createdAt: new Date().toISOString(),
  },
];

sampleDevices.forEach(d => devices.set(d.id, d));

/**
 * GET /api/smarthome
 * List all devices for the user
 */
router.get('/', authenticate, rbacMiddleware(PERMISSIONS.SMARTHOME_READ), (req, res) => {
  const userDevices = Array.from(devices.values()).filter(d => d.ownerId === req.user.userId);
  
  res.json({
    devices: userDevices.map(d => ({
      id: d.id,
      name: d.name,
      type: d.type,
      status: d.status,
      settings: d.settings,
      createdAt: d.createdAt,
    })),
  });
});

/**
 * POST /api/smarthome/devices
 * Add a new device
 */
router.post('/devices',
  authenticate,
  rbacMiddleware(PERMISSIONS.SMARTHOME_WRITE),
  [
    body('name').isLength({ min: 1, max: 100 }).trim(),
    body('type').isIn(['light', 'thermostat', 'lock', 'camera', 'sensor', 'switch']),
  ],
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { name, type, settings } = req.body;
    
    const deviceId = uuidv4();
    const device = {
      id: deviceId,
      name,
      type,
      status: 'off',
      ownerId: req.user.userId,
      settings: settings || {},
      createdAt: new Date().toISOString(),
    };
    
    devices.set(deviceId, device);
    
    logger.info(`Device added: ${name}`, { deviceId, userId: req.user.userId });
    
    res.status(201).json({
      message: 'Device added successfully',
      device: {
        id: device.id,
        name: device.name,
        type: device.type,
        status: device.status,
      },
    });
  }
);

/**
 * GET /api/smarthome/devices/:id
 * Get device details
 */
router.get('/devices/:id',
  authenticate,
  rbacMiddleware(PERMISSIONS.SMARTHOME_READ),
  (req, res) => {
    const device = devices.get(req.params.id);
    
    if (!device) {
      return res.status(404).json({ error: 'Device not found' });
    }
    
    // Check ownership or admin
    if (device.ownerId !== req.user.userId && req.user.role !== 'admin') {
      logger.warn(`Device access denied: ${req.params.id}`, { userId: req.user.userId });
      return res.status(403).json({ error: 'Access denied' });
    }
    
    res.json({ device });
  }
);

/**
 * PUT /api/smarthome/devices/:id
 * Update device settings/status
 */
router.put('/devices/:id',
  authenticate,
  rbacMiddleware(PERMISSIONS.SMARTHOME_WRITE),
  (req, res) => {
    const device = devices.get(req.params.id);
    
    if (!device) {
      return res.status(404).json({ error: 'Device not found' });
    }
    
    // Check ownership or admin
    if (device.ownerId !== req.user.userId && req.user.role !== 'admin') {
      logger.warn(`Device update denied: ${req.params.id}`, { userId: req.user.userId });
      return res.status(403).json({ error: 'Access denied' });
    }
    
    const { name, status, settings } = req.body;
    
    if (name) device.name = name;
    if (status) device.status = status;
    if (settings) device.settings = { ...device.settings, ...settings };
    
    devices.set(req.params.id, device);
    
    logger.info(`Device updated: ${req.params.id}`, { 
      userId: req.user.userId,
      changes: { name, status, settings },
    });
    
    res.json({
      message: 'Device updated successfully',
      device,
    });
  }
);

/**
 * DELETE /api/smarthome/devices/:id
 * Remove a device
 */
router.delete('/devices/:id',
  authenticate,
  rbacMiddleware(PERMISSIONS.SMARTHOME_WRITE),
  (req, res) => {
    const device = devices.get(req.params.id);
    
    if (!device) {
      return res.status(404).json({ error: 'Device not found' });
    }
    
    // Check ownership or admin
    if (device.ownerId !== req.user.userId && req.user.role !== 'admin') {
      logger.warn(`Device delete denied: ${req.params.id}`, { userId: req.user.userId });
      return res.status(403).json({ error: 'Access denied' });
    }
    
    devices.delete(req.params.id);
    
    logger.info(`Device deleted: ${req.params.id}`, { userId: req.user.userId });
    
    res.json({ message: 'Device removed successfully' });
  }
);

/**
 * POST /api/smarthome/devices/:id/control
 * Control device (turn on/off, etc.)
 */
router.post('/devices/:id/control',
  authenticate,
  rbacMiddleware(PERMISSIONS.SMARTHOME_WRITE),
  [
    body('action').isIn(['on', 'off', 'lock', 'unlock', 'toggle']),
  ],
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const device = devices.get(req.params.id);
    
    if (!device) {
      return res.status(404).json({ error: 'Device not found' });
    }
    
    // Check ownership or admin
    if (device.ownerId !== req.user.userId && req.user.role !== 'admin') {
      logger.warn(`Device control denied: ${req.params.id}`, { userId: req.user.userId });
      return res.status(403).json({ error: 'Access denied' });
    }
    
    const { action } = req.body;
    
    // Map actions to device states
    const actionMap = {
      'on': 'on',
      'off': 'off',
      'lock': 'locked',
      'unlock': 'unlocked',
      'toggle': device.status === 'on' ? 'off' : 'on',
    };
    
    device.status = actionMap[action];
    
    devices.set(req.params.id, device);
    
    logger.info(`Device controlled: ${req.params.id}`, { 
      action, 
      newStatus: device.status,
      userId: req.user.userId,
    });
    
    res.json({
      message: `Device ${action} successful`,
      device: {
        id: device.id,
        status: device.status,
      },
    });
  }
);

module.exports = router;
