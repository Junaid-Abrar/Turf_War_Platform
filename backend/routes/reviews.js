const express = require('express');
const router = express.Router({ mergeParams: true }); // Enable access to params from parent router
const { getReviews, addReview } = require('../controllers/reviews');
const { protect } = require('../middleware/auth');

router.route('/')
  .get(getReviews)
  .post(protect, addReview);

module.exports = router;
