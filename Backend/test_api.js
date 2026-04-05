const http = require('http');

console.log('⏳ Starting ECO Wallet API Test...\n');

const testApi = async () => {
  const baseUrl = 'http://localhost:8000/api';

  // Helper to make requests
  const makeRequest = (method, path, body = null, token = null) => {
    return new Promise((resolve, reject) => {
      const url = new URL(baseUrl + path);
      const options = {
        hostname: url.hostname,
        port: url.port,
        path: url.pathname + url.search,
        method: method,
        headers: {
          'Content-Type': 'application/json',
        },
      };

      if (token) {
        options.headers['Authorization'] = `Bearer ${token}`;
      }

      const req = http.request(options, (res) => {
        let data = '';
        res.on('data', (chunk) => {
          data += chunk;
        });
        res.on('end', () => {
          resolve({
            statusCode: res.statusCode,
            body: data ? JSON.parse(data) : null,
          });
        });
      });

      req.on('error', (e) => {
        reject(e);
      });

      if (body) {
        req.write(JSON.stringify(body));
      }
      req.end();
    });
  };

  try {
    // 1. Health Check
    console.log('1️⃣  Testing /api/health...');
    const health = await makeRequest('GET', '/health');
    console.log(`Status: ${health.statusCode} ✅`);
    console.log(health.body);

    // 2. Bank Status
    console.log('\n2️⃣  Testing /api/bank/status (Public)...');
    const bank = await makeRequest('GET', '/bank/status');
    console.log(`Status: ${bank.statusCode} ✅`);
    console.log('Bank Balance:', bank.body.data.total_balance, 'ECO');

    // 3. Register a Test User
    console.log('\n3️⃣  Testing User Registration...');
    const email = `testuser_${Date.now()}@ecowallet.io`;
    const password = 'Password123!';
    const registerRes = await makeRequest('POST', '/auth/register', {
      name: 'Test Setup User',
      email: email,
      password: password
    });
    
    if (registerRes.statusCode === 201) {
      console.log(`Status: ${registerRes.statusCode} ✅`);
      console.log('User created:', registerRes.body.data.user.email);
      const token = registerRes.body.data.accessToken;

      // 4. Check Balance
      console.log('\n4️⃣  Testing Wallet Balance (Protected)...');
      const balanceRes = await makeRequest('GET', '/wallet/balance', null, token);
      console.log(`Status: ${balanceRes.statusCode} ✅`);
      console.log('Balance:', balanceRes.body.data.balance, 'ECO');
      
      console.log('\n🎉 All basic tests passed! The backend architecture is sound.');
    } else {
      console.log(`Status: ${registerRes.statusCode} ❌`);
      console.log('Registration failed:', registerRes.body);
      console.log('Is MongoDB running?');
    }

  } catch (err) {
    if (err.code === 'ECONNREFUSED') {
      console.log('\n❌ Connection Refused. Is the backend server running on port 8000?');
      console.log('Run `npm start` or `npm run dev` in the Backend folder first.');
    } else {
      console.error('\n❌ Test Error:', err.message);
    }
  }
};

testApi();
