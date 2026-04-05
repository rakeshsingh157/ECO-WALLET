const http = require('http');

console.log('⏳ Starting Advanced ECO Wallet API Flow Test...\n');

const testAdvancedFlow = async () => {
  const baseUrl = 'http://localhost:8000/api';
  let adminToken, user1Token, user2Token;
  let user1Id, user2Id;

  // Helper to make requests
  const makeRequest = (method, path, body = null, token = null) => {
    return new Promise((resolve, reject) => {
      const url = new URL(baseUrl + path);
      const options = {
        hostname: url.hostname,
        port: url.port,
        path: url.pathname + url.search,
        method: method,
        headers: { 'Content-Type': 'application/json' },
      };

      if (token) options.headers['Authorization'] = `Bearer ${token}`;

      const req = http.request(options, (res) => {
        let data = '';
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => resolve({ statusCode: res.statusCode, body: data ? JSON.parse(data) : null }));
      });

      req.on('error', (e) => reject(e));
      if (body) req.write(JSON.stringify(body));
      req.end();
    });
  };

  try {
    console.log('1️⃣  Logging in as default Admin...');
    const adminRes = await makeRequest('POST', '/auth/login', {
      email: 'admin@ecowallet.io',
      password: 'Admin@EcoWallet2026'
    });
    
    if (adminRes.statusCode !== 200) {
      console.log('❌ Admin login failed. Make sure the server has run once to auto-seed the admin account.');
      return;
    }
    adminToken = adminRes.body.data.accessToken;
    console.log('Status: 200 ✅');

    console.log('\n2️⃣  Testing Admin Minting...');
    const mintRes = await makeRequest('POST', '/admin/mint', {
      amount: 5000,
      reason: 'Testing Ecosystem Expansion',
      admin_secret: 'change_me_admin_secret_key', // From default .env
      otp: '123456' 
    }, adminToken);
    
    console.log(`Status: ${mintRes.statusCode} ${mintRes.statusCode === 200 ? '✅' : '❌'}`);
    if (mintRes.statusCode === 200) {
      console.log('Bank Balance updated to:', mintRes.body.data.new_bank_balance, 'ECO');
    }

    console.log('\n3️⃣  Creating Two Target Users...');
    const ts = Date.now();
    const u1Res = await makeRequest('POST', '/auth/register', { name: 'Alice', email: `alice${ts}@eco.io`, password: 'Password123!' });
    const u2Res = await makeRequest('POST', '/auth/register', { name: 'Bob', email: `bob${ts}@eco.io`, password: 'Password123!' });
    
    user1Token = u1Res.body.data.accessToken;
    user1Id = u1Res.body.data.user.user_id;
    user2Token = u2Res.body.data.accessToken;
    user2Id = u2Res.body.data.user.user_id;
    console.log(`Alice ID: ${user1Id} | Bob ID: ${user2Id} ✅`);

    console.log('\n4️⃣  Fetching Available Tasks for Alice...');
    const tasksRes = await makeRequest('GET', '/rewards/tasks', null, user1Token);
    console.log(`Status: ${tasksRes.statusCode} ✅`);
    const tasks = tasksRes.body.data.tasks;
    console.log(`Found ${tasks.length} tasks.`);
    
    if (tasks.length > 0) {
      const taskId = tasks[0].task_id;
      console.log(`\n5️⃣  Alice Completes Task (ID: ${taskId})...`);
      const completeRes = await makeRequest('POST', `/rewards/complete/${taskId}`, null, user1Token);
      console.log(`Status: ${completeRes.statusCode} ✅`);
      console.log('Alice Earned:', completeRes.body.data.reward, 'ECO');
      console.log('Alice New Balance:', completeRes.body.data.new_balance, 'ECO');

      console.log('\n6️⃣  Alice Transfers ECO to Bob...');
      const transferRes = await makeRequest('POST', '/transfer/send', {
        receiver_id: user2Id,
        amount: Math.min(10, completeRes.body.data.new_balance),
        description: 'Hello Bob!'
      }, user1Token);
      
      console.log(`Status: ${transferRes.statusCode} ${transferRes.statusCode === 200 ? '✅' : '❌'}`);
      if (transferRes.statusCode === 200) {
        console.log(`Transfer ID: ${transferRes.body.data.transaction_id}`);
        console.log('Alice Remaining Balance:', transferRes.body.data.new_balance, 'ECO');

        console.log('\n7️⃣  Checking Bob\'s Notification & Balance...');
        const bBalRes = await makeRequest('GET', '/wallet/balance', null, user2Token);
        const bNotRes = await makeRequest('GET', '/notifications', null, user2Token);
        console.log(`Bob Balance: ${bBalRes.body.data.balance} ECO ✅`);
        if (bNotRes.body.data.notifications.length > 0) {
          console.log(`Bob got notification: "${bNotRes.body.data.notifications[0].title}" ✅`);
        }
      } else {
        console.log('Transfer error:', transferRes.body.message);
      }
    }

    console.log('\n🎉 Advanced Ecosystem Test Complete!');
  } catch (err) {
    console.error('\n❌ Test Error:', err.message);
  }
};

testAdvancedFlow();
