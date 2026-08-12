const jwt = require('jsonwebtoken');
const User = require('../models/User');

async function createUser({ name = 'Test User', email, password = 'password123', role = 'user' } = {}) {
  const user = await User.create({
    name,
    email: email || `${role}-${Date.now()}-${Math.random().toString(36).slice(2)}@example.com`,
    password,
    role
  });
  return user;
}

function signToken(user) {
  return jwt.sign(
    { id: user._id, role: user.role, name: user.name, email: user.email },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRE }
  );
}

async function createAuthedUser(overrides = {}) {
  const user = await createUser(overrides);
  const token = signToken(user);
  return { user, token };
}

module.exports = { createUser, signToken, createAuthedUser };
