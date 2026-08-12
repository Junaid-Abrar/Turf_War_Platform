const mongoose = require('mongoose');
const logger = require('../config/logger');

const reviewSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  venue: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Venue',
    required: true
  },
  rating: {
    type: Number,
    min: 1,
    max: 5,
    required: true
  },
  comment: {
    type: String,
    required: true
  }
}, {
  timestamps: true
});

// Prevent user from reviewing same venue twice
reviewSchema.index({ venue: 1, user: 1 }, { unique: true });

// Static method to get avg rating and save
reviewSchema.statics.getAverageRating = async function(venueId) {
  const obj = await this.aggregate([
    {
      $match: { venue: venueId }
    },
    {
      $group: {
        _id: '$venue',
        averageRating: { $avg: '$rating' }
      }
    }
  ]);

  try {
    await this.model('Venue').findByIdAndUpdate(venueId, {
      averageRating: obj[0] ? obj[0].averageRating : 0
    });
  } catch (err) {
    logger.error({ err }, 'Failed to recalculate average rating');
  }
};

// Recalculate average rating after a review is created or deleted
reviewSchema.post('save', function() {
  this.constructor.getAverageRating(this.venue);
});

reviewSchema.post('deleteOne', { document: true, query: false }, function() {
  this.constructor.getAverageRating(this.venue);
});

module.exports = mongoose.model('Review', reviewSchema);
