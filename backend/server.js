require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

mongoose.connect(process.env.MONGO_URI)
.then(() => {
    console.log('Connected to MongoDB Atlas');

    app.listen(PORT, () => {
        console.log('Server is running on https://localhost: ${PORT}');
    });
})  .catch((err) => {
    console.error('❌ MongoDB Connection Error:', err);
  });

app.get('/', (req,res) => {
    res.send('API is running>>>');
});

