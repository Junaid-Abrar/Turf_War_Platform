require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');

const emailToPromote = process.argv[2];
const newRole = 'admin';

if (!emailToPromote) {
  console.error('Usage: node scripts/make-admin.js <email>');
  process.exit(1);
}

const promoteUser = async () => {
  let exitCode = 0;
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to DB');

    const user = await User.findOne({ email: emailToPromote });

    if (!user) {
      console.log('User not found:', emailToPromote);
      exitCode = 1;
    } else {
      user.role = newRole;
      await user.save();
      console.log(`SUCCESS: ${user.name} (${user.email}) is now an ${newRole}`);
    }
  } catch (err) {
    console.error(err);
    exitCode = 1;
  } finally {
    await mongoose.disconnect();
  }
  process.exit(exitCode);
};

promoteUser();
