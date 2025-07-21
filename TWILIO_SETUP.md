# Twilio SMS OTP Integration Setup

This guide will help you set up Twilio SMS OTP functionality for the Tinkerly app.

## Prerequisites

1. A Twilio account (sign up at https://www.twilio.com)
2. A Twilio Verify Service

## Setup Steps

### 1. Create a Twilio Verify Service

1. Log in to your Twilio Console
2. Go to "Verify" in the left sidebar
3. Click "Create a Verify Service"
4. Give it a friendly name (e.g., "Tinkerly SMS Verification")
5. Choose "SMS" as the default channel
6. Click "Create"

### 2. Get Your Twilio Credentials

1. In your Twilio Console, go to "Settings" > "General"
2. Copy your Account SID and Auth Token
3. Go to "Verify" > "Services" and copy your Service SID

### 3. Environment Variables

Create a `.env` file in the `tinkerly-backend` directory with the following variables:

```env
# MongoDB Configuration
MONGODB_URI=mongodb://localhost:27017/tinkerly

# Firebase Configuration
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY_ID=your-private-key-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYour Private Key Here\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
FIREBASE_CLIENT_ID=your-client-id
FIREBASE_AUTH_URI=https://accounts.google.com/o/oauth2/auth
FIREBASE_TOKEN_URI=https://oauth2.googleapis.com/token
FIREBASE_AUTH_PROVIDER_X509_CERT_URL=https://www.googleapis.com/oauth2/v1/certs
FIREBASE_CLIENT_X509_CERT_URL=https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxxxx%40your-project.iam.gserviceaccount.com

# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# SMTP Configuration (for email OTP)
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# Twilio Configuration (for SMS OTP)
TWILIO_ACCOUNT_SID=your-twilio-account-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_SERVICE_SID=your-twilio-verify-service-sid

# Server Configuration
PORT=5000
```

### 4. Install Dependencies

The Twilio package is already included in `package.json`. Run:

```bash
npm install
```

### 5. Test the Integration

1. Start the backend server:
   ```bash
   npm start
   ```

2. Test the SMS OTP endpoints:
   - Send OTP: `POST /otp/send-otp` with `{"phone": "+1234567890"}`
   - Verify OTP: `POST /otp/verify-otp` with `{"phone": "+1234567890", "code": "123456"}`

## API Endpoints

### Send SMS OTP
```
POST /otp/send-otp
Headers: Authorization: Bearer <firebase-id-token>
Body: {"phone": "+1234567890"}
```

### Verify SMS OTP
```
POST /otp/verify-otp
Headers: Authorization: Bearer <firebase-id-token>
Body: {"phone": "+1234567890", "code": "123456"}
```

## Flutter Integration

The Flutter app has been updated with:

1. **UserService methods**:
   - `sendSmsOtp(String phone)`
   - `verifySmsOtp(String phone, String code)`

2. **Updated Register Screen**: Now supports both email and phone verification

3. **New Phone Verification Screen**: For existing users to verify their phone numbers

## Usage in Flutter

### During Registration
Users can choose between email or phone verification during registration.

### For Existing Users
Navigate to the phone verification screen:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const PhoneVerificationScreen(),
  ),
);
```

## Troubleshooting

1. **Invalid phone number format**: Ensure phone numbers include country code (e.g., +1 for US)
2. **Twilio service not found**: Verify your Service SID is correct
3. **Authentication errors**: Check your Twilio Account SID and Auth Token
4. **Firebase token issues**: Ensure the user is authenticated before calling OTP endpoints

## Security Notes

1. Phone numbers are validated on both client and server
2. OTP verification requires Firebase authentication
3. Failed verification attempts are logged
4. Phone verification status is stored in the database 