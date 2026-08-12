const { protect, authorize } = require('../middleware/auth');
const { createUser, signToken } = require('./helpers');

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
