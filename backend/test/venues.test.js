const request = require('supertest');
const app = require('../app');
const Venue = require('../models/Venue');
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

describe('POST /api/venues', () => {
  it('allows a venue_owner to create a venue', async () => {
    const { token } = await createAuthedUser({ role: 'venue_owner' });

    const res = await request(app)
      .post('/api/venues')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Owner Field', description: 'Nice pitch', location: 'City', pricePerHour: 15 });

    expect(res.status).toBe(201);
    expect(res.body.data.name).toBe('Owner Field');
  });

  it('forbids a plain user from creating a venue', async () => {
    const { token } = await createAuthedUser({ role: 'user' });

    const res = await request(app)
      .post('/api/venues')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Should Fail', description: 'x', location: 'x', pricePerHour: 15 });

    expect(res.status).toBe(403);
  });

  it('rejects a negative/zero pricePerHour', async () => {
    const { token } = await createAuthedUser({ role: 'venue_owner' });

    const res = await request(app)
      .post('/api/venues')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Bad Price', description: 'x', location: 'x', pricePerHour: 0 });

    expect(res.status).toBe(400);
  });
});

describe('GET /api/venues/search', () => {
  it('filters by price range', async () => {
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    await makeVenue(owner, { name: 'Cheap', pricePerHour: 10 });
    await makeVenue(owner, { name: 'Pricey', pricePerHour: 100 });

    const res = await request(app).get('/api/venues/search').query({ minPrice: 50 });

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].name).toBe('Pricey');
  });

  it('filters by name/location text query', async () => {
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    await makeVenue(owner, { name: 'Riverside Pitch', location: 'Riverside' });
    await makeVenue(owner, { name: 'Uptown Court', location: 'Uptown' });

    const res = await request(app).get('/api/venues/search').query({ query: 'riverside' });

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].name).toBe('Riverside Pitch');
  });

  it('filters by amenities (all must match)', async () => {
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    await makeVenue(owner, { name: 'Full', amenities: ['Wifi', 'Parking'] });
    await makeVenue(owner, { name: 'PartialOnly', amenities: ['Wifi'] });

    const res = await request(app).get('/api/venues/search').query({ amenities: 'Wifi,Parking' });

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].name).toBe('Full');
  });
});

describe('PUT /api/venues/:id', () => {
  it('allows the owner to update their venue', async () => {
    const { user: owner, token } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);

    const res = await request(app)
      .put(`/api/venues/${venue._id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ pricePerHour: 99 });

    expect(res.status).toBe(200);
    expect(res.body.data.pricePerHour).toBe(99);
  });

  it('forbids a different owner from updating the venue', async () => {
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);
    const { token: otherToken } = await createAuthedUser({ role: 'venue_owner' });

    const res = await request(app)
      .put(`/api/venues/${venue._id}`)
      .set('Authorization', `Bearer ${otherToken}`)
      .send({ pricePerHour: 1 });

    expect(res.status).toBe(403);
  });

  it('allows an admin to update any venue', async () => {
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);
    const { token: adminToken } = await createAuthedUser({ role: 'admin' });

    const res = await request(app)
      .put(`/api/venues/${venue._id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ pricePerHour: 42 });

    expect(res.status).toBe(200);
    expect(res.body.data.pricePerHour).toBe(42);
  });

  it('ignores attempts to reassign the owner field', async () => {
    const { user: owner, token } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);
    const { user: attacker } = await createAuthedUser({ role: 'venue_owner' });

    const res = await request(app)
      .put(`/api/venues/${venue._id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ owner: attacker._id.toString() });

    expect(res.status).toBe(200);
    expect(res.body.data.owner).toBe(owner._id.toString());
  });
});

describe('DELETE /api/venues/:id', () => {
  it('forbids a non-owner, non-admin from deleting', async () => {
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);
    const { token: otherToken } = await createAuthedUser({ role: 'venue_owner' });

    const res = await request(app)
      .delete(`/api/venues/${venue._id}`)
      .set('Authorization', `Bearer ${otherToken}`);

    expect(res.status).toBe(403);
  });

  it('allows the owner to delete their venue', async () => {
    const { user: owner, token } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);

    const res = await request(app)
      .delete(`/api/venues/${venue._id}`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(await Venue.findById(venue._id)).toBeNull();
  });
});

describe('GET /api/venues/:id', () => {
  it('returns a single venue', async () => {
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);

    const res = await request(app).get(`/api/venues/${venue._id}`);

    expect(res.status).toBe(200);
    expect(res.body.data.name).toBe('Test Turf');
  });

  it('404s for a nonexistent venue', async () => {
    const { user: owner } = await createAuthedUser({ role: 'venue_owner' });
    const venue = await makeVenue(owner);
    const fakeId = venue._id.toString().replace(/.$/, venue._id.toString().slice(-1) === '0' ? '1' : '0');

    const res = await request(app).get(`/api/venues/${fakeId}`);
    expect(res.status).toBe(404);
  });
});
