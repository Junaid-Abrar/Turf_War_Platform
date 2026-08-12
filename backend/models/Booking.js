const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
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
  date: {
    type: String, // Storing as 'YYYY-MM-DD' is easier for simple slot logic
    required: true
  },
  startTime: {
    type: String, // '18:00'
    required: true
  },
  endTime: {
    type: String, // '19:00'
    required: true
  },
  price: {
    type: Number,
    required: true
  },
  status: {
    type: String,
    enum: ['pending', 'confirmed', 'cancelled'],
    default: 'pending'
  },
  paymentStatus: {
    type: String,
    enum: ['unpaid', 'paid', 'failed'],
    default: 'unpaid'
  },
  stripePaymentIntentId: {
    type: String
  }
}, {
  timestamps: true
});

// Prevent double booking: Unique index on Venue + Date + StartTime.
// Scoped to non-cancelled bookings so a cancelled slot frees up for rebooking.
bookingSchema.index(
  { venue: 1, date: 1, startTime: 1 },
  { unique: true, partialFilterExpression: { status: { $in: ['pending', 'confirmed'] } } }
);

module.exports = mongoose.model('Booking', bookingSchema);
