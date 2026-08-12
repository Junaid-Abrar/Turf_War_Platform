const express = require('express');
const router = express.Router();
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { protect } = require('../middleware/auth');
const Booking = require('../models/Booking');
const User = require('../models/User');
const { sendNotification } = require('../config/firebase');

// @desc    Create a payment intent
// @route   POST /api/payments/create-payment-intent
// @access  Private
router.post('/create-payment-intent', protect, async (req, res) => {
  try {
    const { bookingId } = req.body;

    const booking = await Booking.findById(bookingId).populate('venue');
    if (!booking) {
      return res.status(404).json({ success: false, error: 'Booking not found' });
    }

    if (booking.user.toString() !== req.user.id) {
      return res.status(403).json({ success: false, error: 'Not authorized to pay for this booking' });
    }

    if (booking.paymentStatus === 'paid') {
      return res.status(400).json({ success: false, error: 'Booking is already paid' });
    }

    // Stripe expects amount in cents
    const amount = Math.round(booking.price * 100);

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: 'usd',
      metadata: { bookingId: booking._id.toString() },
      automatic_payment_methods: { enabled: true },
    });

    // Update booking with payment intent ID
    booking.stripePaymentIntentId = paymentIntent.id;
    await booking.save();

    res.status(200).json({
      success: true,
      clientSecret: paymentIntent.client_secret,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Payment initialization failed' });
  }
});

// @desc    Stripe Webhook
// @route   POST /api/payments/webhook
// @access  Public
// Raw-body parsing for this path is registered in server.js, before express.json() —
// Stripe signature verification needs the untouched request body.
router.post('/webhook', async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle the event
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

      // Trigger Notifications here
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
});

module.exports = router;
