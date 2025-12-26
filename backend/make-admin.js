require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');

const emailToPromote = 'jd@gmail.com

'; // CHANGE THIS if you are logged in as someone else
const newRole = 'admin';

const promoteUser = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to DB');

    const user = await User.findOne({ email: emailToPromote });

    if (!user) {
      console.log('❌ User not found:', emailToPromote);
      process.exit(1);
    }

    user.role = newRole;
    await user.save();

    console.log(`🎉 SUCCESS: ${user.name} (${user.email}) is now an ${newRole}`);
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};

promoteUser();
