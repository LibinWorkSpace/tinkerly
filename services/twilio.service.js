const twilio = require('twilio');
require('dotenv').config();

const client = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);

exports.sendOTP = async (phone) => {
  try {
    // Cancel any existing verification for this phone number
    const existingVerifications = await client.verify.v2.services(process.env.TWILIO_SERVICE_SID)
      .verifications.list({ to: phone, status: 'pending' });

    for (const verification of existingVerifications) {
      try {
        await client.verify.v2.services(process.env.TWILIO_SERVICE_SID)
          .verifications(verification.sid).update({ status: 'canceled' });
        console.log('Canceled existing verification:', verification.sid);
      } catch (cancelErr) {
        console.log('Could not cancel verification:', verification.sid, cancelErr.message);
      }
    }
  } catch (listErr) {
    console.log('Could not list existing verifications:', listErr.message);
  }

  // Create new verification
  return await client.verify.v2.services(process.env.TWILIO_SERVICE_SID)
    .verifications.create({ to: phone, channel: 'sms' });
};

exports.verifyOTP = async (phone, code) => {
  console.log('Twilio verifyOTP called with:', { phone, code });
  try {
    const result = await client.verify.v2.services(process.env.TWILIO_SERVICE_SID)
      .verificationChecks.create({ to: phone, code });
    console.log('Twilio verification result:', result);
    return result;
  } catch (error) {
    console.error('Twilio verification error:', {
      code: error.code,
      status: error.status,
      message: error.message,
      moreInfo: error.moreInfo
    });
    throw error;
  }
};