const http = require('http');

// 1. The User Data
const user = {
  name: 'Mobile User',
  email: 'mobile@example.com', 
  password: 'mobilepassword123',
  role: 'user'
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
      } catch (_e) {
        console.log('RAW BODY:', body);
      }
    });
  });

  req.on('error', (e) => console.error('ERROR:', e.message));
  req.write(data);
  req.end();
}

console.log('STEP 1: Registering User...');
sendRequest('/api/auth/register', user, (_res) => {
  // Even if duplicate, proceed to login
  console.log('\nSTEP 2: Logging In...');
  sendRequest('/api/auth/login', {
    email: user.email,
    password: user.password
  });
});