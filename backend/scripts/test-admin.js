const http = require('http');

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

console.log('--- TEST 1: Login as Regular User ---');
makeRequest('/api/auth/login', 'POST', null, {
  email: 'fresh.user@example.com',
  password: 'freshpassword123'
}, (loginRes) => {
  if (loginRes.success) {
    const token = loginRes.token;
    console.log('Got Token for Regular User');

    console.log('\n--- TEST 2: Try to access Admin Route ---');
    makeRequest('/api/auth/admin', 'GET', token, null, (adminRes) => {
      console.log('Result:', adminRes);
    });
  }
});