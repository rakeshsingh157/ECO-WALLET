const http = require('http');

function post(path, data) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify(data);
    const req = http.request({
      hostname: 'localhost',
      port: 5001,
      path: path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload),
      },
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(body) });
        } catch (_) {
          resolve({ status: res.statusCode, raw: body });
        }
      });
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

function get(path) {
  return new Promise((resolve, reject) => {
    const req = http.get(`http://localhost:5001${path}`, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(body) });
        } catch (_) {
          resolve({ status: res.statusCode, raw: body });
        }
      });
    });
    req.on('error', reject);
  });
}

async function runTests() {
  console.log('--- 1. Testing Signup ---');
  const signup = await post('/api/merchant/signup', {
    mobile_number: '6200779484',
    shop_name: 'Rakesh Kirana Store',
    owner_name: 'Rakesh Singh',
    security_pin: '1234',
  });
  console.log('Signup result:', signup);

  console.log('\n--- 2. Testing Login ---');
  const login = await post('/api/merchant/login', {
    mobile_number: '6200779484',
    security_pin: '1234',
  });
  console.log('Login result:', login);

  console.log('\n--- 3. Testing Wrong PIN ---');
  const wrongPin = await post('/api/merchant/login', {
    mobile_number: '6200779484',
    security_pin: '9999',
  });
  console.log('Wrong PIN result:', wrongPin);

  console.log('\n--- 4. Testing Unregistered Phone Login ---');
  const notFound = await post('/api/merchant/login', {
    mobile_number: '9111122222',
    security_pin: '1234',
  });
  console.log('Not Found result:', notFound);

  console.log('\n--- 5. Testing Wallet Lookup ---');
  const walletLookup = await get('/api/wallet/user/key_mch_6200779484_auto');
  console.log('Wallet Lookup result:', walletLookup);

  console.log('\n--- 6. Testing Product Add ---');
  const addProd = await post('/api/products', {
    name: 'Fortune Mustard Oil 1L',
    price: 155,
    category: 'Oil & Ghee',
    unit: 'L',
    stock: 25,
  });
  console.log('Product Add result:', addProd);

  console.log('\n--- 7. Testing Product List ---');
  const prodList = await get('/api/products');
  console.log('Product List count:', prodList.data.count, 'First item:', prodList.data.data[0]?.name);
}

runTests();
