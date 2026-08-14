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
 * Marks a booking paid/confirmed and fires the payment-success notifications.
 * Called from both the webhook and the client-driven confirm endpoint, since
 * either can be the first to observe a succeeded PaymentIntent. Idempotent —
 * safe to call again if the other path already marked it paid.
 */
async function markBookingPaid(bookingId) {
  const booking = await Booking.findById(bookingId).populate({
    path: 'venue',
    populate: { path: 'owner' }
  });
  if (!booking || booking.paymentStatus === 'paid') {
    return;
  }

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
    await markBookingPaid(paymentIntent.metadata.bookingId);
  }

  res.json({ received: true });
}));

/**
 * @openapi
 * /payments/confirm:
 *   post:
 *     tags: [Payments]
 *     summary: Client-driven fallback that verifies a PaymentIntent directly with Stripe and marks the booking paid, so confirmation does not depend solely on webhook delivery timing.
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
 *       200: { description: Current payment status for the booking }
 *       403: { description: Not authorized to confirm this booking }
 *       404: { description: Booking not found }
 */
router.post('/confirm', protect, asyncHandler(async (req, res, next) => {
  const { bookingId } = req.body;

  const booking = await Booking.findById(bookingId);
  if (!booking) {
    return next(new ErrorResponse('Booking not found', 404));
  }

  if (booking.user.toString() !== req.user.id) {
    return next(new ErrorResponse('Not authorized to confirm this booking', 403));
  }

  // Ask Stripe directly rather than trusting the client's word that the
  // payment sheet succeeded — this is the source of truth, same as the
  // webhook, just polled synchronously instead of pushed asynchronously.
  if (booking.paymentStatus !== 'paid' && booking.stripePaymentIntentId) {
    const paymentIntent = await stripe.paymentIntents.retrieve(booking.stripePaymentIntentId);
    if (paymentIntent.status === 'succeeded') {
      await markBookingPaid(booking._id);
    }
  } else if (booking.paymentStatus !== 'paid' && !booking.stripePaymentIntentId && process.env.DEMO_MODE === 'true') {
    // The public web demo stubs the Stripe payment sheet client-side (no
    // PaymentIntent is ever created), so there is nothing to verify against
    // Stripe. Only take the client's word for it when this server is itself
    // explicitly running in demo mode — a real deployment always has
    // DEMO_MODE unset and falls through, requiring a verified PaymentIntent.
    await markBookingPaid(booking._id);
  }

  const current = await Booking.findById(bookingId);
  res.status(200).json({
    success: true,
    paymentStatus: current.paymentStatus,
    status: current.status
  });
}));

module.exports = router;
