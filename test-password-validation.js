// Test password validation on backend
const axios = require('axios');

const BASE_URL = 'http://localhost:5000';

async function testPasswordValidation() {
  console.log('🔐 Testing Password Validation on Backend...\n');

  const testCases = [
    {
      name: 'Weak Password (too short)',
      password: '123',
      shouldFail: true
    },
    {
      name: 'Weak Password (no uppercase)',
      password: 'password123!',
      shouldFail: true
    },
    {
      name: 'Weak Password (no special chars)',
      password: 'Password123',
      shouldFail: true
    },
    {
      name: 'Strong Password',
      password: 'MySecure123!',
      shouldFail: false
    }
  ];

  for (const testCase of testCases) {
    try {
      console.log(`Testing: ${testCase.name}`);
      console.log(`Password: "${testCase.password}"`);
      
      const response = await axios.post(`${BASE_URL}/auth/reset-password`, {
        email: 'test@example.com',
        otp: '123456',
        newPassword: testCase.password
      });
      
      if (testCase.shouldFail) {
        console.log('❌ Expected validation to fail, but it passed');
      } else {
        console.log('✅ Strong password accepted (validation passed)');
      }
      
    } catch (error) {
      if (error.response && error.response.status === 400) {
        const errorData = error.response.data;
        if (testCase.shouldFail) {
          console.log('✅ Weak password rejected:', errorData.details?.[0]?.message || errorData.error);
        } else {
          console.log('❌ Strong password rejected:', errorData.details?.[0]?.message || errorData.error);
        }
      } else if (error.response && error.response.status === 429) {
        console.log('⏳ Rate limited - validation middleware is working');
      } else {
        console.log('ℹ️  Other error (expected for invalid OTP):', error.response?.data?.error || error.message);
      }
    }
    
    console.log('---');
    await new Promise(resolve => setTimeout(resolve, 100));
  }
}

testPasswordValidation().catch(console.error);
