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

describe('POST /api/bookings', () => {
  it('computes price server-side and ignores a client-supplied price', async () => {
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner, { pricePerHour: 20 });
    const { token } = await createAuthedUser({ role: 'user' });

    const res = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send({
        venueId: venue._id.toString(),
        date: '2026-09-01',
        startTime: '18:00',
        endTime: '19:30', // 1.5 hours
        price: 0.01 // attacker-supplied, must be ignored
      });

    expect(res.status).toBe(201);
    expect(res.body.data.price).toBe(30); // 20 * 1.5
  });

  it('rejects an invalid time range (end before start)', async () => {
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);
    const { token } = await createAuthedUser({ role: 'user' });

    const res = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send({
        venueId: venue._id.toString(),
        date: '2026-09-01',
        startTime: '19:00',
        endTime: '18:00'
      });

    expect(res.status).toBe(400);
  });

  it('blocks double-booking the same venue/date/startTime', async () => {
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);
    const { token: token1 } = await createAuthedUser({ role: 'user' });
    const { token: token2 } = await createAuthedUser({ role: 'user' });

    const payload = {
      venueId: venue._id.toString(),
      date: '2026-09-05',
      startTime: '10:00',
      endTime: '11:00'
    };

    const first = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token1}`)
      .send(payload);
    expect(first.status).toBe(201);

    const second = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token2}`)
      .send(payload);
    expect(second.status).toBe(400);
  });

  it('prevents an owner from booking their own venue', async () => {
    const { user: owner, token } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);

    const res = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send({
        venueId: venue._id.toString(),
        date: '2026-09-01',
        startTime: '18:00',
        endTime: '19:00'
      });

    expect(res.status).toBe(400);
  });

  it('404s for a nonexistent venue', async () => {
    const { token } = await createAuthedUser({ role: 'user' });
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);
    const fakeId = venue._id.toString().replace(/.$/, venue._id.toString().slice(-1) === '0' ? '1' : '0');
    await venue.deleteOne();

    const res = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send({ venueId: fakeId, date: '2026-09-01', startTime: '18:00', endTime: '19:00' });

    expect(res.status).toBe(404);
  });

  it('rejects a malformed venueId with a validation error, not a 500', async () => {
    const { token } = await createAuthedUser({ role: 'user' });

    const res = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send({ venueId: 'not-an-id', date: '2026-09-01', startTime: '18:00', endTime: '19:00' });

    expect(res.status).toBe(400);
  });
});

describe('PATCH /api/bookings/:id/cancel', () => {
  it('lets the booking owner cancel it, freeing the slot', async () => {
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);
    const { token } = await createAuthedUser({ role: 'user' });

    const created = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send({ venueId: venue._id.toString(), date: '2026-09-10', startTime: '08:00', endTime: '09:00' });

    const bookingId = created.body.data._id;

    const cancelRes = await request(app)
      .patch(`/api/bookings/${bookingId}/cancel`)
      .set('Authorization', `Bearer ${token}`);

    expect(cancelRes.status).toBe(200);
    expect(cancelRes.body.data.status).toBe('cancelled');

    // Slot should now be free for a new booking
    const { token: token2 } = await createAuthedUser({ role: 'user' });
    const rebook = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token2}`)
      .send({ venueId: venue._id.toString(), date: '2026-09-10', startTime: '08:00', endTime: '09:00' });

    expect(rebook.status).toBe(201);
  });

  it('forbids cancelling someone else\'s booking', async () => {
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);
    const { token } = await createAuthedUser({ role: 'user' });

    const created = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send({ venueId: venue._id.toString(), date: '2026-09-11', startTime: '08:00', endTime: '09:00' });

    const { token: otherToken } = await createAuthedUser({ role: 'user' });

    const res = await request(app)
      .patch(`/api/bookings/${created.body.data._id}/cancel`)
      .set('Authorization', `Bearer ${otherToken}`);

    expect(res.status).toBe(403);
  });

  it('rejects cancelling an already-cancelled booking', async () => {
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);
    const { token } = await createAuthedUser({ role: 'user' });

    const created = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send({ venueId: venue._id.toString(), date: '2026-09-12', startTime: '08:00', endTime: '09:00' });

    const bookingId = created.body.data._id;
    await request(app).patch(`/api/bookings/${bookingId}/cancel`).set('Authorization', `Bearer ${token}`);

    const res = await request(app)
      .patch(`/api/bookings/${bookingId}/cancel`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(400);
  });
});

describe('PATCH /api/bookings/:id/status', () => {
  it('lets the venue owner confirm a pending booking', async () => {
    const { user: owner, token: ownerToken } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);
    const { token } = await createAuthedUser({ role: 'user' });

    const created = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send({ venueId: venue._id.toString(), date: '2026-09-15', startTime: '08:00', endTime: '09:00' });

    const res = await request(app)
      .patch(`/api/bookings/${created.body.data._id}/status`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ status: 'confirmed' });

    expect(res.status).toBe(200);
    expect(res.body.data.status).toBe('confirmed');
  });

  it('forbids a random user from confirming a booking', async () => {
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);
    const { token } = await createAuthedUser({ role: 'user' });

    const created = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send({ venueId: venue._id.toString(), date: '2026-09-16', startTime: '08:00', endTime: '09:00' });

    const { token: randomToken } = await createAuthedUser({ role: 'user' });

    const res = await request(app)
      .patch(`/api/bookings/${created.body.data._id}/status`)
      .set('Authorization', `Bearer ${randomToken}`)
      .send({ status: 'confirmed' });

    expect(res.status).toBe(403);
  });

  it('rejects an invalid status value', async () => {
    const { user: owner, token: ownerToken } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);
    const { token } = await createAuthedUser({ role: 'user' });

    const created = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send({ venueId: venue._id.toString(), date: '2026-09-17', startTime: '08:00', endTime: '09:00' });

    const res = await request(app)
      .patch(`/api/bookings/${created.body.data._id}/status`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ status: 'bogus' });

    expect(res.status).toBe(400);
  });
});

describe('GET /api/bookings/my', () => {
  it('only returns the logged-in user\'s bookings', async () => {
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);
    const { user, token } = await createAuthedUser({ role: 'user' });
    const { token: otherToken } = await createAuthedUser({ role: 'user' });

    await Booking.create({
      user: user._id, venue: venue._id, date: '2026-09-01', startTime: '08:00', endTime: '09:00', price: 20
    });
    await Booking.create({
      user: (await createAuthedUser({ role: 'user' })).user._id,
      venue: venue._id,
      date: '2026-09-02',
      startTime: '08:00',
      endTime: '09:00',
      price: 20
    });

    const res = await request(app).get('/api/bookings/my').set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].user).toBe(user._id.toString());

    // sanity: otherToken exists but unused for filtering assertion above
    expect(otherToken).toBeTruthy();
  });
});
