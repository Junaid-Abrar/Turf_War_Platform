const request = require('supertest');
const app = require('../app');
const User = require('../models/User');
const { createAuthedUser } = require('./helpers');

describe('POST /api/auth/register', () => {
  it('registers a new user and forces role to "user"', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Alice', email: 'alice@example.com', password: 'password123', role: 'admin' });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.email).toBe('alice@example.com');
    expect(res.body.data.role).toBe('user'); // role in body is ignored server-side
  });

  it('rejects a duplicate email', async () => {
    await request(app)
      .post('/api/auth/register')
      .send({ name: 'Alice', email: 'dupe@example.com', password: 'password123' });

    const res = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Alice 2', email: 'dupe@example.com', password: 'password123' });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it('rejects an invalid email and a short password', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Bob', email: 'not-an-email', password: '123' });

    expect(res.status).toBe(400);
  });
});

describe('POST /api/auth/login', () => {
  beforeEach(async () => {
    await request(app)
      .post('/api/auth/register')
      .send({ name: 'Carol', email: 'carol@example.com', password: 'password123' });
  });

  it('logs in with correct credentials and returns a JWT', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'carol@example.com', password: 'password123' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(typeof res.body.token).toBe('string');
    expect(res.body.user.email).toBe('carol@example.com');
  });

  it('rejects a wrong password', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'carol@example.com', password: 'wrong-password' });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it('rejects a nonexistent email', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'nobody@example.com', password: 'password123' });

    expect(res.status).toBe(401);
  });
});

describe('GET /api/auth/me', () => {
  it('returns the current user when authenticated', async () => {
    const { user, token } = await createAuthedUser({ email: 'dave@example.com' });

    const res = await request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data._id).toBe(user._id.toString());
  });

  it('rejects a missing token', async () => {
    const res = await request(app).get('/api/auth/me');
    expect(res.status).toBe(401);
  });

  it('rejects a malformed/invalid token', async () => {
    const res = await request(app)
      .get('/api/auth/me')
      .set('Authorization', 'Bearer not-a-real-token');

    expect(res.status).toBe(401);
  });

  it('returns 401 when the token belongs to a since-deleted user', async () => {
    const { user, token } = await createAuthedUser({ email: 'evan@example.com' });
    await User.findByIdAndDelete(user._id);

    const res = await request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(401);
  });
});

describe('role escalation attempts', () => {
  it('a plain user cannot list all users', async () => {
    const { token } = await createAuthedUser({ role: 'user' });

    const res = await request(app)
      .get('/api/auth/users')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(403);
  });

  it('a plain user cannot change their own role via updateUserRole', async () => {
    const { user, token } = await createAuthedUser({ role: 'user' });

    const res = await request(app)
      .put(`/api/auth/users/${user._id}/role`)
      .set('Authorization', `Bearer ${token}`)
      .send({ role: 'admin' });

    expect(res.status).toBe(403);
  });

  it('an admin can change another user\'s role', async () => {
    const { token: adminToken } = await createAuthedUser({ role: 'admin' });
    const { user: target } = await createAuthedUser({ role: 'user' });

    const res = await request(app)
      .put(`/api/auth/users/${target._id}/role`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ role: 'venue_owner' });

    expect(res.status).toBe(200);
    expect(res.body.data.role).toBe('venue_owner');
  });

  it('rejects an invalid role value even from an admin', async () => {
    const { token: adminToken } = await createAuthedUser({ role: 'admin' });
    const { user: target } = await createAuthedUser({ role: 'user' });

    const res = await request(app)
      .put(`/api/auth/users/${target._id}/role`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ role: 'superadmin' });

    expect(res.status).toBe(400);
  });
});
