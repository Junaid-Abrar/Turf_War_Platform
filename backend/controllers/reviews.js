const Review = require('../models/Review');
const Venue = require('../models/Venue');
const asyncHandler = require('../middleware/asyncHandler');
const ErrorResponse = require('../utils/ErrorResponse');

// @desc    Get reviews for a venue
// @route   GET /api/venues/:venueId/reviews
// @access  Public
exports.getReviews = asyncHandler(async (req, res) => {
  const reviews = await Review.find({ venue: req.params.venueId })
    .populate('user', 'name')
    .sort('-createdAt');

  res.status(200).json({
    success: true,
    count: reviews.length,
    data: reviews
  });
});

// @desc    Add review
// @route   POST /api/venues/:venueId/reviews
// @access  Private
exports.addReview = asyncHandler(async (req, res, next) => {
  req.body.venue = req.params.venueId;
  req.body.user = req.user.id;

  const venue = await Venue.findById(req.params.venueId);
  if (!venue) {
    return next(new ErrorResponse('Venue not found', 404));
  }

  // Prevent venue owner from reviewing their own venue
  if (venue.owner.toString() === req.user.id) {
    return next(new ErrorResponse('You cannot review your own venue', 400));
  }

  const review = await Review.create(req.body);

  res.status(201).json({
    success: true,
    data: review
  });
});
