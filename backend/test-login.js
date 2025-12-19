const http = require('http');

// 1. The User Data (Must match the one created earlier)
const user = {
  email: 'fresh.user@example.com',
  password: 'freshpassword123'
};

function sendRequest(path, payload, callback) {
  const data = JSON.stringify(payload);
  const options = {
    hostname: '127.0.0.1',
    port: 3000,
    path: path,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': data.length
    }
  };

  const req = http.request(options, (res) => {
    let body = '';
    res.on('data', (chunk) => body += chunk);
    res.on('end', () => {
      console.log(`\n--- RESPONSE FROM ${path} ---`);
      console.log('STATUS:', res.statusCode);
      try {
        const parsed = JSON.parse(body);
        console.log(parsed);
        if (callback) callback(parsed);
      } catch (e) {
        console.log('RAW BODY:', body);
      }
    });
  });

  req.on('error', (e) => console.error('ERROR:', e.message));
  req.write(data);
  req.end();
}

console.log('STEP: Logging In...');
sendRequest('/api/auth/login', {
  email: user.email,
  password: user.password
});


