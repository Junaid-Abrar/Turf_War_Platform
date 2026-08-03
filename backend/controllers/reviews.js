const Review = require('../models/Review');
const Venue = require('../models/Venue');

// @desc    Get reviews for a venue
// @route   GET /api/venues/:venueId/reviews
// @access  Public
exports.getReviews = async (req, res) => {
  try {
    const reviews = await Review.find({ venue: req.params.venueId })
      .populate('user', 'name')
      .sort('-createdAt');

    res.status(200).json({
      success: true,
      count: reviews.length,
      data: reviews
    });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Server Error' });
  }
};

// @desc    Add review
// @route   POST /api/venues/:venueId/reviews
// @access  Private
exports.addReview = async (req, res) => {
  try {
    req.body.venue = req.params.venueId;
    req.body.user = req.user.id;

    const venue = await Venue.findById(req.params.venueId);
    if (!venue) {
      return res.status(404).json({ success: false, error: 'Venue not found' });
    }

    // Prevent venue owner from reviewing their own venue
    if (venue.owner.toString() === req.user.id) {
      return res.status(400).json({ success: false, error: 'You cannot review your own venue' });
    }

    const review = await Review.create(req.body);

    res.status(201).json({
      success: true,
      data: review
    });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(400).json({ success: false, error: 'You have already reviewed this venue' });
    }
    console.error(err);
    res.status(500).json({ success: false, error: 'Server Error' });
  }
};
