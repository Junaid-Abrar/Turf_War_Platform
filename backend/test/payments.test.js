const request = require('supertest');
const app = require('../app');
const Venue = require('../models/Venue');
const Booking = require('../models/Booking');
const { createAuthedUser } = require('./helpers');

async function makeVenue(owner, overrides = {}) {
  return Venue.create({
    name: 'Test Turf',
    description: 'A fine place to play',
    location: 'Downtown',
    pricePerHour: 20,
    owner: owner._id,
    ...overrides
  });
}

describe('POST /api/payments/create-payment-intent', () => {
  it('rejects creating a payment intent for someone else\'s booking', async () => {
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);
    const { user: bookingUser } = await createAuthedUser({ role: 'user' });
    const booking = await Booking.create({
      user: bookingUser._id, venue: venue._id, date: '2026-09-01', startTime: '18:00', endTime: '19:00', price: 20
    });

    const { token: attackerToken } = await createAuthedUser({ role: 'user' });

    const res = await request(app)
      .post('/api/payments/create-payment-intent')
      .set('Authorization', `Bearer ${attackerToken}`)
      .send({ bookingId: booking._id.toString() });

    expect(res.status).toBe(403);
  });

  it('404s for a nonexistent booking', async () => {
    const { token } = await createAuthedUser({ role: 'user' });
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);
    const booking = await Booking.create({
      user: (await createAuthedUser({ role: 'user' })).user._id,
      venue: venue._id,
      date: '2026-09-01',
      startTime: '18:00',
      endTime: '19:00',
      price: 20
    });
    const fakeId = booking._id.toString().replace(/.$/, booking._id.toString().slice(-1) === '0' ? '1' : '0');
    await booking.deleteOne();

    const res = await request(app)
      .post('/api/payments/create-payment-intent')
      .set('Authorization', `Bearer ${token}`)
      .send({ bookingId: fakeId });

    expect(res.status).toBe(404);
  });

  it('rejects creating a payment intent for an already-paid booking', async () => {
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);
    const { user: bookingUser, token } = await createAuthedUser({ role: 'user' });
    const booking = await Booking.create({
      user: bookingUser._id,
      venue: venue._id,
      date: '2026-09-01',
      startTime: '18:00',
      endTime: '19:00',
      price: 20,
      paymentStatus: 'paid'
    });

    const res = await request(app)
      .post('/api/payments/create-payment-intent')
      .set('Authorization', `Bearer ${token}`)
      .send({ bookingId: booking._id.toString() });

    expect(res.status).toBe(400);
  });

  it('rejects an unauthenticated request', async () => {
    const res = await request(app)
      .post('/api/payments/create-payment-intent')
      .send({ bookingId: '000000000000000000000000' });

    expect(res.status).toBe(401);
  });
});

describe('POST /api/payments/confirm', () => {
  it('rejects confirming someone else\'s booking', async () => {
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);
    const { user: bookingUser } = await createAuthedUser({ role: 'user' });
    const booking = await Booking.create({
      user: bookingUser._id, venue: venue._id, date: '2026-09-01', startTime: '18:00', endTime: '19:00', price: 20
    });

    const { token: attackerToken } = await createAuthedUser({ role: 'user' });

    const res = await request(app)
      .post('/api/payments/confirm')
      .set('Authorization', `Bearer ${attackerToken}`)
      .send({ bookingId: booking._id.toString() });

    expect(res.status).toBe(403);
  });

  it('404s for a nonexistent booking', async () => {
    const { token } = await createAuthedUser({ role: 'user' });

    const res = await request(app)
      .post('/api/payments/confirm')
      .set('Authorization', `Bearer ${token}`)
      .send({ bookingId: '000000000000000000000000' });

    expect(res.status).toBe(404);
  });

  it('rejects an unauthenticated request', async () => {
    const res = await request(app)
      .post('/api/payments/confirm')
      .send({ bookingId: '000000000000000000000000' });

    expect(res.status).toBe(401);
  });

  it('is a no-op that reports paid for a booking already marked paid, without calling Stripe', async () => {
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);
    const { user: bookingUser, token } = await createAuthedUser({ role: 'user' });
    const booking = await Booking.create({
      user: bookingUser._id,
      venue: venue._id,
      date: '2026-09-01',
      startTime: '18:00',
      endTime: '19:00',
      price: 20,
      paymentStatus: 'paid',
      status: 'confirmed'
    });

    const res = await request(app)
      .post('/api/payments/confirm')
      .set('Authorization', `Bearer ${token}`)
      .send({ bookingId: booking._id.toString() });

    expect(res.status).toBe(200);
    expect(res.body.paymentStatus).toBe('paid');
    expect(res.body.status).toBe('confirmed');
  });

  it('reports unpaid without calling Stripe when no PaymentIntent was ever created', async () => {
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);
    const { user: bookingUser, token } = await createAuthedUser({ role: 'user' });
    const booking = await Booking.create({
      user: bookingUser._id,
      venue: venue._id,
      date: '2026-09-01',
      startTime: '18:00',
      endTime: '19:00',
      price: 20
    });

    const res = await request(app)
      .post('/api/payments/confirm')
      .set('Authorization', `Bearer ${token}`)
      .send({ bookingId: booking._id.toString() });

    expect(res.status).toBe(200);
    expect(res.body.paymentStatus).toBe('unpaid');
  });
});
