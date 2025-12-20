const http = require('http');

// Helper function
function makeRequest(path, method, token, payload, callback) {
  const options = {
    hostname: '127.0.0.1',
    port: 3000,
    path: path,
    method: method,
    headers: { 'Content-Type': 'application/json' }
  };
  if (token) options.headers['Authorization'] = `Bearer ${token}`;

  const req = http.request(options, (res) => {
    let body = '';
    res.on('data', c => body += c);
    res.on('end', () => {
      console.log(`[${method} ${path}] Status: ${res.statusCode}`);
      try {
        if (callback) callback(JSON.parse(body));
      } catch (e) { console.log('Body:', body); }
    });
  });
  if (payload) req.write(JSON.stringify(payload));
  req.end();
}

// 1. Login as Regular User
console.log('--- STEP 1: Testing Regular User Permission ---');
makeRequest('/api/auth/login', 'POST', null, { email: 'mobile@example.com', password: 'mobilepassword123' }, (userLogin) => {
  if (!userLogin.token) {
     // If mobile user doesn't exist, try fresh user
     console.log('Mobile user login failed, trying fresh user...');
     makeRequest('/api/auth/login', 'POST', null, { email: 'fresh.user@example.com', password: 'freshpassword123' }, (freshLogin) => {
        runTest(freshLogin);
     });
  } else {
     runTest(userLogin);
  }
});

function runTest(userLogin) {
  // Try to create venue
  makeRequest('/api/venues', 'POST', userLogin.token, {
    name: 'Unauthorized Turf',
    description: 'This should fail',
    location: 'Nowhere',
    pricePerHour: 10
  }, (res) => {
    console.log('Regular User Create Result:', res.success ? 'FAILED (Should not succeed)' : 'PASSED (Access Denied)');
    
    // 2. Register/Login as Admin
    console.log('\n--- STEP 2: Testing Admin Permission ---');
    const adminUser = { name: 'Admin Boss', email: 'admin@turf.com', password: 'adminpassword', role: 'admin' };
    
    // Register Admin (Ignore if exists)
    makeRequest('/api/auth/register', 'POST', null, adminUser, () => {
      // Login Admin
      makeRequest('/api/auth/login', 'POST', null, { email: adminUser.email, password: adminUser.password }, (adminLogin) => {
        if (!adminLogin.token) return console.log('Admin Login Failed');

        // Create Venue as Admin
        makeRequest('/api/venues', 'POST', adminLogin.token, {
          name: 'Premier League Turf',
          description: 'Top quality grass',
          location: 'Wembley Stadium',
          pricePerHour: 100,
          amenities: ['Parking', 'Showers', 'Lights']
        }, (venueRes) => {
          console.log('Admin Create Result:', venueRes.success ? 'PASSED' : 'FAILED');
          if(!venueRes.success) console.log(venueRes);

          // 3. Get All Venues
          console.log('\n--- STEP 3: Fetching All Venues ---');
          makeRequest('/api/venues', 'GET', null, null, (listRes) => {
            console.log(`Found ${listRes.count} venues.`);
            if (listRes.count > 0) console.log('First Venue Name:', listRes.data[0].name);
          });
        });
      });
    });
  });
}
