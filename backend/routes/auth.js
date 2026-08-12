const express = require('express');
const router = express.Router();
const rateLimit = require('express-rate-limit');
const {
  register, login, getMe, updateFcmToken, getUsers, updateUserRole
} = require('../controllers/auth');
const { protect, authorize } = require('../middleware/auth');
const {
  registerRules, loginRules, updateUserRoleRules, checkValidation
} = require('../middleware/validators');

// Strict limiter on auth endpoints to slow down credential stuffing / brute force.
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: 'Too many attempts, please try again later' }
});

/**
 * @openapi
 * /auth/register:
 *   post:
 *     tags: [Auth]
 *     summary: Register a new user
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name, email, password]
 *             properties:
 *               name: { type: string }
 *               email: { type: string }
 *               password: { type: string }
 *     responses:
 *       201: { description: User created }
 *       400: { description: Validation error }
 */
router.post('/register', authLimiter, registerRules, checkValidation, register);

/**
 * @openapi
 * /auth/login:
 *   post:
 *     tags: [Auth]
 *     summary: Log in and receive a JWT
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, password]
 *             properties:
 *               email: { type: string }
 *               password: { type: string }
 *     responses:
 *       200: { description: Login successful, returns a JWT }
 *       401: { description: Invalid credentials }
 */
router.post('/login', authLimiter, loginRules, checkValidation, login);

/**
 * @openapi
 * /auth/me:
 *   get:
 *     tags: [Auth]
 *     summary: Get the currently authenticated user
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Current user }
 */
router.get('/me', protect, getMe);

/**
 * @openapi
 * /auth/fcm-token:
 *   put:
 *     tags: [Auth]
 *     summary: Update the current user's FCM push token
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Token updated }
 */
router.put('/fcm-token', protect, updateFcmToken);

/**
 * @openapi
 * /auth/users:
 *   get:
 *     tags: [Auth]
 *     summary: List all users (admin only)
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: List of users }
 */
router.get('/users', protect, authorize('admin'), getUsers);

/**
 * @openapi
 * /auth/users/{id}/role:
 *   put:
 *     tags: [Auth]
 *     summary: Update a user's role (admin only)
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200: { description: Updated user }
 */
router.put('/users/:id/role', protect, authorize('admin'), updateUserRoleRules, checkValidation, updateUserRole);

module.exports = router;
