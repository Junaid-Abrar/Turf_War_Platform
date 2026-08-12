const { body, validationResult } = require('express-validator');
const ErrorResponse = require('../utils/ErrorResponse');

// Runs after a chain of express-validator checks; turns the first failure into a 400.
exports.checkValidation = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return next(new ErrorResponse(errors.array()[0].msg, 400));
  }
  next();
};

exports.registerRules = [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('email').isEmail().withMessage('A valid email is required').normalizeEmail(),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
];

exports.loginRules = [
  body('email').isEmail().withMessage('A valid email is required').normalizeEmail(),
  body('password').notEmpty().withMessage('Password is required')
];

exports.createVenueRules = [
  body('name').trim().notEmpty().withMessage('Venue name is required'),
  body('description').trim().notEmpty().withMessage('Description is required'),
  body('location').trim().notEmpty().withMessage('Location is required'),
  body('pricePerHour').isFloat({ gt: 0 }).withMessage('pricePerHour must be a positive number')
];

exports.updateVenueRules = [
  body('name').optional().trim().notEmpty().withMessage('Name cannot be empty'),
  body('description').optional().trim().notEmpty().withMessage('Description cannot be empty'),
  body('location').optional().trim().notEmpty().withMessage('Location cannot be empty'),
  body('pricePerHour').optional().isFloat({ gt: 0 }).withMessage('pricePerHour must be a positive number')
];

exports.createBookingRules = [
  body('venueId').isMongoId().withMessage('A valid venueId is required'),
  body('date').matches(/^\d{4}-\d{2}-\d{2}$/).withMessage('date must be in YYYY-MM-DD format'),
  body('startTime').matches(/^([01]\d|2[0-3]):[0-5]\d$/).withMessage('startTime must be in HH:MM format'),
  body('endTime').matches(/^([01]\d|2[0-3]):[0-5]\d$/).withMessage('endTime must be in HH:MM format')
];

exports.updateBookingStatusRules = [
  body('status').isIn(['confirmed', 'cancelled']).withMessage("status must be 'confirmed' or 'cancelled'")
];

exports.addReviewRules = [
  body('rating').isInt({ min: 1, max: 5 }).withMessage('rating must be an integer between 1 and 5'),
  body('comment').trim().notEmpty().withMessage('comment is required')
];

exports.updateUserRoleRules = [
  body('role').isIn(['user', 'venue_owner', 'admin']).withMessage('Invalid role')
];
