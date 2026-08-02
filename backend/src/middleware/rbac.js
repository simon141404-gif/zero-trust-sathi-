const logger = require('../utils/logger');

// Role definitions with permissions
const ROLES = {
  ADMIN: 'admin',
  USER: 'user',
  GUEST: 'guest',
};

const PERMISSIONS = {
  // Storage permissions
  STORAGE_READ: 'storage:read',
  STORAGE_WRITE: 'storage:write',
  STORAGE_DELETE: 'storage:delete',
  STORAGE_ADMIN: 'storage:admin',
  
  // Smart home permissions
  SMARTHOME_READ: 'smarthome:read',
  SMARTHOME_WRITE: 'smarthome:write',
  SMARTHOME_ADMIN: 'smarthome:admin',
  
  // User management
  USER_READ: 'user:read',
  USER_WRITE: 'user:write',
  USER_ADMIN: 'user:admin',
};

// Role-permission mapping
const ROLE_PERMISSIONS = {
  [ROLES.ADMIN]: Object.values(PERMISSIONS), // Admin has all permissions
  [ROLES.USER]: [
    PERMISSIONS.STORAGE_READ,
    PERMISSIONS.STORAGE_WRITE,
    PERMISSIONS.STORAGE_DELETE,
    PERMISSIONS.SMARTHOME_READ,
    PERMISSIONS.SMARTHOME_WRITE,
    PERMISSIONS.USER_READ,
  ],
  [ROLES.GUEST]: [
    PERMISSIONS.STORAGE_READ,
    PERMISSIONS.SMARTHOME_READ,
  ],
};

/**
 * Check if role has required permission
 */
const hasPermission = (role, permission) => {
  const rolePermissions = ROLE_PERMISSIONS[role] || [];
  return rolePermissions.includes(permission);
};

/**
 * RBAC middleware factory
 * Creates middleware that checks for specific permission
 */
const rbacMiddleware = (requiredPermission) => {
  return (req, res, next) => {
    const userRole = req.user?.role;
    
    if (!userRole) {
      logger.warn('RBAC check failed: No role in request', { 
        path: req.path,
        userId: req.user?.userId 
      });
      return res.status(403).json({ error: 'Access denied' });
    }
    
    if (!hasPermission(userRole, requiredPermission)) {
      logger.warn(`RBAC: User role ${userRole} lacks permission ${requiredPermission}`, {
        path: req.path,
        userId: req.user?.userId,
      });
      return res.status(403).json({ 
        error: 'Insufficient permissions',
        required: requiredPermission,
        current: userRole,
      });
    }
    
    next();
  };
};

/**
 * Middleware to check if user owns resource or is admin
 */
const ownershipMiddleware = (getOwnerId) => {
  return (req, res, next) => {
    const userId = req.user?.userId;
    const userRole = req.user?.role;
    
    // Admin can access everything
    if (userRole === ROLES.ADMIN) {
      return next();
    }
    
    const ownerId = getOwnerId(req);
    if (ownerId !== userId) {
      logger.warn('Ownership check failed', {
        userId,
        ownerId,
        path: req.path,
      });
      return res.status(403).json({ error: 'Access denied: Not your resource' });
    }
    
    next();
  };
};

module.exports = {
  ROLES,
  PERMISSIONS,
  hasPermission,
  rbacMiddleware,
  ownershipMiddleware,
};
