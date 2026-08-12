const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

let initialized = false;

function loadServiceAccount() {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    return JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  }
  const localPath = path.join(__dirname, 'service-account.json');
  if (fs.existsSync(localPath)) {
    return require(localPath);
  }
  return null;
}

try {
  const serviceAccount = loadServiceAccount();
  if (serviceAccount) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    initialized = true;
    console.log('Firebase Admin Initialized');
  } else {
    console.warn('Firebase Admin not initialized: no service account found (set FIREBASE_SERVICE_ACCOUNT or provide config/service-account.json). Push notifications are disabled.');
  }
} catch (error) {
  console.error('Firebase Admin Initialization Error:', error);
}

const sendNotification = async (fcmToken, title, body, data = {}) => {
  if (!initialized || !fcmToken) return;

  const message = {
    notification: {
      title,
      body,
    },
    data, // Custom data payload
    token: fcmToken,
  };

  try {
    await admin.messaging().send(message);
    console.log('Notification sent successfully');
  } catch (error) {
    console.error('Error sending notification:', error);
  }
};

module.exports = { admin, sendNotification };
