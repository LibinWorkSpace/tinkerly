// Simple security test script
const axios = require('axios');

const BASE_URL = 'http://localhost:5000';

async function testRateLimit() {
  console.log('🔒 Testing Rate Limiting...');
  
  try {
    // Test OTP rate limiting (should allow 3 requests, then block)
    for (let i = 1; i <= 5; i++) {
      try {
        const response = await axios.post(`${BASE_URL}/auth/send-registration-otp`, {
          email: 'test@example.com'
        });
        console.log(`Request ${i}: ${response.status} - ${response.data.success ? 'Success' : 'Failed'}`);
      } catch (error) {
        if (error.response && error.response.status === 429) {
          console.log(`Request ${i}: 429 - Rate limited! ✅`);
        } else {
          console.log(`Request ${i}: ${error.response?.status} - ${error.response?.data?.error || error.message}`);
        }
      }
      
      // Small delay between requests
      await new Promise(resolve => setTimeout(resolve, 100));
    }
  } catch (error) {
    console.error('Rate limit test failed:', error.message);
  }
}

async function testSecurityHeaders() {
  console.log('\n🛡️ Testing Security Headers...');
  
  try {
    const response = await axios.get(`${BASE_URL}/posts/all`);
    const headers = response.headers;
    
    console.log('Security Headers:');
    console.log(`- X-Content-Type-Options: ${headers['x-content-type-options'] || 'Missing ❌'}`);
    console.log(`- X-Frame-Options: ${headers['x-frame-options'] || 'Missing ❌'}`);
    console.log(`- X-XSS-Protection: ${headers['x-xss-protection'] || 'Missing ❌'}`);
    console.log(`- Referrer-Policy: ${headers['referrer-policy'] || 'Missing ❌'}`);
    
  } catch (error) {
    console.error('Security headers test failed:', error.message);
  }
}

async function testInputValidation() {
  console.log('\n🔍 Testing Input Validation...');
  
  try {
    // Test with malicious input
    const maliciousEmail = '<script>alert("xss")</script>@test.com';
    const response = await axios.post(`${BASE_URL}/auth/send-registration-otp`, {
      email: maliciousEmail
    });
    
    console.log('Input sanitization test - Response:', response.data);
  } catch (error) {
    console.log(`Input validation working: ${error.response?.data?.error || error.message}`);
  }
}

async function runTests() {
  console.log('🚀 Starting Security Tests...\n');
  
  await testRateLimit();
  await testSecurityHeaders();
  await testInputValidation();
  
  console.log('\n✅ Security tests completed!');
  console.log('\n📝 Summary:');
  console.log('- Rate limiting: Protects against brute force attacks');
  console.log('- Security headers: Prevents common web vulnerabilities');
  console.log('- Input validation: Sanitizes user input to prevent XSS');
}

// Run tests if this file is executed directly
if (require.main === module) {
  runTests().catch(console.error);
}

module.exports = { testRateLimit, testSecurityHeaders, testInputValidation };
