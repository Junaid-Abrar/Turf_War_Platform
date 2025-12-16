const express = require('express'); // Import Express (think of this like importing 'package:flutter/material.dart')

const app = express(); // Initialize the app
const PORT = 3000; // The port our server will run on

// This is a "Route". It tells the server what to do when a specific URL is accessed.
// '/' is the home path.
// req (Request): Data coming FROM the user (or Flutter app).
// res (Response): Data we send BACK to the user.
app.get('/', (req, res) => {
    res.send('Hello World! The Turf War Backend is alive.');
});

// Start the server and listen for connections
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
