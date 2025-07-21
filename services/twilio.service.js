const twilio = require('twilio');
require('dotenv').config();

const client = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);

exports.sendOTP = async (phone) => {
  return await client.verify.v2.services(process.env.TWILIO_SERVICE_SID)
    .verifications.create({ to: phone, channel: 'sms' });
};

exports.verifyOTP = async (phone, code) => {
  return await client.verify.v2.services(process.env.TWILIO_SERVICE_SID)
    .verificationChecks.create({ to: phone, code });
}; 