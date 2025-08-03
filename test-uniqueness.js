// Test uniqueness constraints
const axios = require('axios');

const BASE_URL = 'http://localhost:5000';

async function testEmailUniqueness() {
  console.log('📧 Testing Email Uniqueness...\n');

  // Test with existing email
  try {
    const response = await axios.get(`${BASE_URL}/user/exists?email=libinmani.2.0@gmail.com`);
    console.log('✅ Email exists check:', response.data);
  } catch (error) {
    console.log('❌ Email exists check failed:', error.message);
  }

  // Test with new email
  try {
    const response = await axios.get(`${BASE_URL}/user/exists?email=newemail@test.com`);
    console.log('✅ New email check:', response.data);
  } catch (error) {
    console.log('❌ New email check failed:', error.message);
  }
}

async function testUsernameUniqueness() {
  console.log('\n👤 Testing Username Uniqueness...\n');

  // Test with existing username
  try {
    const response = await axios.get(`${BASE_URL}/user/username-exists?username=Libin Mani`);
    console.log('✅ Username exists check:', response.data);
  } catch (error) {
    console.log('❌ Username exists check failed:', error.message);
  }

  // Test with new username
  try {
    const response = await axios.get(`${BASE_URL}/user/username-exists?username=newuser123`);
    console.log('✅ New username check:', response.data);
  } catch (error) {
    console.log('❌ New username check failed:', error.message);
  }
}

async function testPortfolioNameUniqueness() {
  console.log('\n📁 Testing Portfolio Name Uniqueness...\n');

  // Test with existing portfolio name
  try {
    const response = await axios.get(`${BASE_URL}/portfolio/name-exists?profilename=Programming`);
    console.log('✅ Portfolio name exists check:', response.data);
  } catch (error) {
    console.log('❌ Portfolio name exists check failed:', error.message);
  }

  // Test with new portfolio name
  try {
    const response = await axios.get(`${BASE_URL}/portfolio/name-exists?profilename=NewPortfolio123`);
    console.log('✅ New portfolio name check:', response.data);
  } catch (error) {
    console.log('❌ New portfolio name check failed:', error.message);
  }
}

async function testValidationErrors() {
  console.log('\n🔍 Testing Validation Errors...\n');

  // Test invalid email format
  try {
    const response = await axios.post(`${BASE_URL}/user`, {
      name: 'Test User',
      email: 'invalid-email',
      username: 'testuser123'
    });
    console.log('❌ Should have failed for invalid email');
  } catch (error) {
    if (error.response && error.response.status === 400) {
      console.log('✅ Invalid email rejected:', error.response.data.details?.[0]?.message);
    } else {
      console.log('❌ Unexpected error:', error.message);
    }
  }

  // Test invalid username format
  try {
    const response = await axios.post(`${BASE_URL}/user`, {
      name: 'Test User',
      email: 'test@example.com',
      username: 'ab' // Too short
    });
    console.log('❌ Should have failed for short username');
  } catch (error) {
    if (error.response && error.response.status === 400) {
      console.log('✅ Short username rejected:', error.response.data.details?.[0]?.message);
    } else {
      console.log('❌ Unexpected error:', error.message);
    }
  }

  // Test duplicate email
  try {
    const response = await axios.post(`${BASE_URL}/user`, {
      name: 'Test User',
      email: 'libinmani.2.0@gmail.com', // Existing email
      username: 'uniqueuser123'
    });
    console.log('❌ Should have failed for duplicate email');
  } catch (error) {
    if (error.response && error.response.status === 400) {
      console.log('✅ Duplicate email rejected:', error.response.data.details?.[0]?.message);
    } else {
      console.log('❌ Unexpected error:', error.message);
    }
  }
}

async function runTests() {
  console.log('🚀 Starting Uniqueness Tests...\n');
  
  await testEmailUniqueness();
  await testUsernameUniqueness();
  await testPortfolioNameUniqueness();
  await testValidationErrors();
  
  console.log('\n✅ Uniqueness tests completed!');
  console.log('\n📝 Summary:');
  console.log('- Email uniqueness: Prevents duplicate email registrations');
  console.log('- Username uniqueness: Prevents duplicate usernames');
  console.log('- Portfolio name uniqueness: Prevents duplicate portfolio names');
  console.log('- Input validation: Validates format and requirements');
}

runTests().catch(console.error);
