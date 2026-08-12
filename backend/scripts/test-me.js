const http = require('http');

// Helper to make requests
function makeRequest(path, method, token, payload, callback) {
  const options = {
    hostname: '127.0.0.1',
    port: 3000,
    path: path,
    method: method,
    headers: { 'Content-Type': 'application/json' }
  };

  if (token) {
    options.headers['Authorization'] = `Bearer ${token}`;
  }

  const req = http.request(options, (res) => {
    let body = '';
    res.on('data', c => body += c);
    res.on('end', () => {
      console.log(`[${method} ${path}] Status: ${res.statusCode}`);
      if (callback) callback(JSON.parse(body));
    });
  });

  if (payload) req.write(JSON.stringify(payload));
  req.end();
}

console.log('--- TEST 1: Accessing Protected Route WITHOUT Token ---');
makeRequest('/api/auth/me', 'GET', null, null, (res1) => {
  console.log('Result:', res1);

  console.log('\n--- TEST 2: Logging in to get Token ---');
  makeRequest('/api/auth/login', 'POST', null, {
    email: 'fresh.user@example.com',
    password: 'freshpassword123'
  }, (loginRes) => {
    if (loginRes.success) {
      const token = loginRes.token;
      console.log('Got Token!');

      console.log('\n--- TEST 3: Accessing Protected Route WITH Token ---');
      makeRequest('/api/auth/me', 'GET', token, null, (meRes) => {
        console.log('Result:', meRes);
      });
    } else {
      console.log('Login failed', loginRes);
    }
  });
});