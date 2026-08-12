const base64url = (obj) =>
  btoa(JSON.stringify(obj)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

// jwt-decode never verifies the signature, so a fake unsigned token is fine for tests.
export const makeFakeToken = (payload) => {
  const header = base64url({ alg: 'HS256', typ: 'JWT' });
  const body = base64url(payload);
  return `${header}.${body}.fakesignature`;
};

export const makeValidToken = (overrides = {}) =>
  makeFakeToken({
    id: 'user-1',
    name: 'Ada Lovelace',
    email: 'ada@example.com',
    role: 'admin',
    exp: Math.floor(Date.now() / 1000) + 3600,
    ...overrides,
  });

export const makeExpiredToken = (overrides = {}) =>
  makeFakeToken({
    id: 'user-1',
    name: 'Ada Lovelace',
    email: 'ada@example.com',
    role: 'admin',
    exp: Math.floor(Date.now() / 1000) - 3600,
    ...overrides,
  });
