const request = require('supertest');
const app = require('../app');
const { protect, authorize } = require('../middleware/auth');
const { createUser, signToken, createAuthedUser } = require('./helpers');
const Venue = require('../models/Venue');
const Booking = require('../models/Booking');

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

function mockRes() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

describe('protect middleware', () => {
  it('calls next() and sets req.user for a valid token', async () => {
    const user = await createUser({ role: 'user' });
    const token = signToken(user);
    const req = { headers: { authorization: `Bearer ${token}` } };
    const res = mockRes();
    const next = jest.fn();

    await protect(req, res, next);

    expect(next).toHaveBeenCalledTimes(1);
    expect(req.user).toBeTruthy();
    expect(req.user._id.toString()).toBe(user._id.toString());
    expect(res.status).not.toHaveBeenCalled();
  });

  it('responds 401 when no Authorization header is present', async () => {
    const req = { headers: {} };
    const res = mockRes();
    const next = jest.fn();

    await protect(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('responds 401 for a token signed with the wrong secret', async () => {
    const jwt = require('jsonwebtoken');
    const badToken = jwt.sign({ id: '000000000000000000000000' }, 'wrong-secret');
    const req = { headers: { authorization: `Bearer ${badToken}` } };
    const res = mockRes();
    const next = jest.fn();

    await protect(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('responds 401 when the token\'s user no longer exists', async () => {
    const user = await createUser({ role: 'user' });
    const token = signToken(user);
    await user.deleteOne();

    const req = { headers: { authorization: `Bearer ${token}` } };
    const res = mockRes();
    const next = jest.fn();

    await protect(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });
});

describe('authorize middleware', () => {
  it('calls next() when the user role is allowed', () => {
    const req = { user: { role: 'admin' } };
    const res = mockRes();
    const next = jest.fn();

    authorize('admin', 'venue_owner')(req, res, next);

    expect(next).toHaveBeenCalledTimes(1);
    expect(res.status).not.toHaveBeenCalled();
  });

  it('responds 403 when the user role is not allowed', () => {
    const req = { user: { role: 'user' } };
    const res = mockRes();
    const next = jest.fn();

    authorize('admin', 'venue_owner')(req, res, next);

    expect(res.status).toHaveBeenCalledWith(403);
    expect(next).not.toHaveBeenCalled();
  });
});

describe('admin/owner scoping across venues, bookings, and analytics', () => {
  async function seedTwoOwnerWorld() {
    const { user: ownerA, token: tokenA } = await createAuthedUser({ role: 'venue_owner' });
    const { user: ownerB, token: tokenB } = await createAuthedUser({ role: 'venue_owner' });
    const { token: adminToken } = await createAuthedUser({ role: 'admin' });
    const { token: userToken } = await createAuthedUser({ role: 'user' });

    const venueA = await makeVenue(ownerA, { name: 'Venue A' });
    const venueB = await makeVenue(ownerB, { name: 'Venue B' });

    const { user: customer } = await createAuthedUser({ role: 'user' });
    await Booking.create({
      user: customer._id, venue: venueA._id, date: '2026-09-01', startTime: '08:00', endTime: '09:00', price: 20, status: 'confirmed'
    });
    await Booking.create({
      user: customer._id, venue: venueB._id, date: '2026-09-02', startTime: '08:00', endTime: '09:00', price: 30, status: 'confirmed'
    });

    return { ownerA, tokenA, ownerB, tokenB, adminToken, userToken, venueA, venueB };
  }

  describe('GET /api/venues/mine', () => {
    it('scopes an owner to only their own venues', async () => {
      const { tokenA, venueA } = await seedTwoOwnerWorld();

      const res = await request(app).get('/api/venues/mine').set('Authorization', `Bearer ${tokenA}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveLength(1);
      expect(res.body.data[0]._id).toBe(venueA._id.toString());
    });

    it('gives admin every venue across both owners', async () => {
      const { adminToken } = await seedTwoOwnerWorld();

      const res = await request(app).get('/api/venues/mine').set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveLength(2);
    });
  });

  describe('GET /api/bookings/owner', () => {
    it('scopes an owner to bookings on only their own venues', async () => {
      const { tokenA, venueA } = await seedTwoOwnerWorld();

      const res = await request(app).get('/api/bookings/owner').set('Authorization', `Bearer ${tokenA}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveLength(1);
      expect(res.body.data[0].venue._id).toBe(venueA._id.toString());
    });

    it('gives admin bookings across both owners', async () => {
      const { adminToken } = await seedTwoOwnerWorld();

      const res = await request(app).get('/api/bookings/owner').set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveLength(2);
    });

    it('rejects a plain user role', async () => {
      const { userToken } = await seedTwoOwnerWorld();

      const res = await request(app).get('/api/bookings/owner').set('Authorization', `Bearer ${userToken}`);

      expect(res.status).toBe(403);
    });
  });

  describe('GET /api/analytics', () => {
    it('scopes an owner to their own venues\' totals', async () => {
      const { tokenA } = await seedTwoOwnerWorld();

      const res = await request(app).get('/api/analytics').set('Authorization', `Bearer ${tokenA}`);

      expect(res.status).toBe(200);
      expect(res.body.data.totalBookings).toBe(1);
      expect(res.body.data.totalRevenue).toBe(20);
    });

    it('gives admin non-zero platform-wide totals across both owners', async () => {
      const { adminToken } = await seedTwoOwnerWorld();

      const res = await request(app).get('/api/analytics').set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.totalBookings).toBe(2);
      expect(res.body.data.totalRevenue).toBe(50);
    });

    it('rejects a plain user role', async () => {
      const { userToken } = await seedTwoOwnerWorld();

      const res = await request(app).get('/api/analytics').set('Authorization', `Bearer ${userToken}`);

      expect(res.status).toBe(403);
    });
  });

  describe('PATCH /api/bookings/:id/status', () => {
    it('rejects a plain user role at the route level', async () => {
      const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
      const venue = await makeVenue(owner);
      const { user: customer, token: customerToken } = await createAuthedUser({ role: 'user' });
      const booking = await Booking.create({
        user: customer._id, venue: venue._id, date: '2026-09-03', startTime: '08:00', endTime: '09:00', price: 20
      });

      const res = await request(app)
        .patch(`/api/bookings/${booking._id}/status`)
        .set('Authorization', `Bearer ${customerToken}`)
        .send({ status: 'confirmed' });

      expect(res.status).toBe(403);
    });

    it('lets admin confirm a booking on a venue they do not own', async () => {
      const { adminToken, venueA } = await seedTwoOwnerWorld();
      const { user: customer } = await createAuthedUser({ role: 'user' });
      const booking = await Booking.create({
        user: customer._id, venue: venueA._id, date: '2026-09-04', startTime: '08:00', endTime: '09:00', price: 20
      });

      const res = await request(app)
        .patch(`/api/bookings/${booking._id}/status`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ status: 'confirmed' });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe('confirmed');
    });
  });
});
