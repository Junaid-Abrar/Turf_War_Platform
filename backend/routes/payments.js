const express = require('express');
const router = express.Router();
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { protect } = require('../middleware/auth');
const Booking = require('../models/Booking');
const User = require('../models/User');
const { sendNotification } = require('../config/firebase');
const asyncHandler = require('../middleware/asyncHandler');
const ErrorResponse = require('../utils/ErrorResponse');

/**
 * @openapi
 * /payments/create-payment-intent:
 *   post:
 *     tags: [Payments]
 *     summary: Create a Stripe payment intent for a booking (owner-only, idempotent on paid bookings)
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [bookingId]
 *             properties:
 *               bookingId: { type: string }
 *     responses:
 *       200: { description: Stripe client secret }
 *       403: { description: Not authorized to pay for this booking }
 */
router.post('/create-payment-intent', protect, asyncHandler(async (req, res, next) => {
  const { bookingId } = req.body;

  const booking = await Booking.findById(bookingId).populate('venue');
  if (!booking) {
    return next(new ErrorResponse('Booking not found', 404));
  }

  if (booking.user.toString() !== req.user.id) {
    return next(new ErrorResponse('Not authorized to pay for this booking', 403));
  }

  if (booking.paymentStatus === 'paid') {
    return next(new ErrorResponse('Booking is already paid', 400));
  }

  // Stripe expects amount in cents
  const amount = Math.round(booking.price * 100);

  const paymentIntent = await stripe.paymentIntents.create({
    amount: amount,
    currency: 'usd',
    metadata: { bookingId: booking._id.toString() },
    automatic_payment_methods: { enabled: true }
  });

  booking.stripePaymentIntentId = paymentIntent.id;
  await booking.save();

  res.status(200).json({
    success: true,
    clientSecret: paymentIntent.client_secret
  });
}));

/**
 * @openapi
 * /payments/webhook:
 *   post:
 *     tags: [Payments]
 *     summary: Stripe webhook — marks a booking paid/confirmed on payment_intent.succeeded
 *     responses:
 *       200: { description: Event received }
 *       400: { description: Invalid signature }
 */
// Raw-body parsing for this path is registered in server.js, before express.json() —
// Stripe signature verification needs the untouched request body.
router.post('/webhook', asyncHandler(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET);
  } catch (err) {
    req.log?.warn({ err }, 'Stripe webhook signature verification failed');
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === 'payment_intent.succeeded') {
    const paymentIntent = event.data.object;
    const bookingId = paymentIntent.metadata.bookingId;

    const booking = await Booking.findById(bookingId).populate({
      path: 'venue',
      populate: { path: 'owner' }
    });
    if (booking) {
      booking.paymentStatus = 'paid';
      booking.status = 'confirmed';
      await booking.save();

      const user = await User.findById(booking.user);
      const venue = booking.venue;

      if (user && user.fcmToken) {
        sendNotification(
          user.fcmToken,
          'Payment Successful!',
          `Your booking for ${venue.name} is confirmed.`
        );
      }

      if (venue.owner && venue.owner.fcmToken) {
        sendNotification(
          venue.owner.fcmToken,
          'New Confirmed Booking',
          `Payment received for ${venue.name} booking on ${booking.date}.`
        );
      }
    }
  }

  res.json({ received: true });
}));

module.exports = router;
