// Idempotent demo-data seed: safe to re-run, always converges to the same dataset.
// Wipes and recreates all documents rather than diffing, since this is demo/dev data only.
require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');
const Venue = require('../models/Venue');
const Booking = require('../models/Booking');
const Review = require('../models/Review');

const DEMO_PASSWORD = 'password123';

const USERS = [
  { name: 'Ada Admin', email: 'admin@turfwar.demo.com', role: 'admin' },
  { name: 'Owen Owner', email: 'owner@turfwar.demo.com', role: 'venue_owner' },
  { name: 'Uma User', email: 'user@turfwar.demo.com', role: 'user' },
  { name: 'Nate Newman', email: 'nate@turfwar.demo.com', role: 'user' }
];

const VENUES = [
  {
    name: 'Riverside Football Turf',
    description: 'A premium 5-a-side artificial turf right on the riverbank, floodlit for evening games.',
    location: 'Riverside, Downtown',
    pricePerHour: 25,
    amenities: ['Floodlights', 'Parking', 'Changing Rooms'],
    images: ['https://images.unsplash.com/photo-1459865264687-595d652de67e?w=800']
  },
  {
    name: 'Uptown Basketball Court',
    description: 'Full-size indoor hardwood court with scoreboard and spectator seating.',
    location: 'Uptown Sports Complex',
    pricePerHour: 30,
    amenities: ['Scoreboard', 'Seating', 'Wifi'],
    images: ['https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800']
  },
  {
    name: 'Greenfield Cricket Ground',
    description: 'Full-length cricket pitch with practice nets attached.',
    location: 'Greenfield Park',
    pricePerHour: 40,
    amenities: ['Practice Nets', 'Parking', 'Refreshments'],
    images: ['https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?w=800']
  },
  {
    name: 'Downtown Tennis Club',
    description: 'Clay courts maintained to tournament standard, racket rental available.',
    location: 'Downtown Sports Club',
    pricePerHour: 20,
    amenities: ['Racket Rental', 'Wifi', 'Parking'],
    images: ['https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=800']
  },
  {
    name: 'Harbor Futsal Arena',
    description: 'Indoor futsal court with a fast rebound-friendly surface, popular for evening leagues.',
    location: 'Harbor District',
    pricePerHour: 22,
    amenities: ['Floodlights', 'Changing Rooms'],
    images: ['https://images.unsplash.com/photo-1552667466-07770ae110d0?w=800']
  },
  {
    name: 'Sunset Badminton Hall',
    description: 'Four-court badminton hall with wooden flooring and equipment rental.',
    location: 'Sunset Plaza',
    pricePerHour: 15,
    amenities: ['Equipment Rental', 'Wifi', 'Parking'],
    images: ['https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800']
  },
  {
    name: 'Northside Volleyball Court',
    description: 'Outdoor sand volleyball court, lit for night play, popular with weekend leagues.',
    location: 'Northside Beach Park',
    pricePerHour: 18,
    amenities: ['Floodlights', 'Showers'],
    images: ['https://images.unsplash.com/photo-1592656094267-764a45160876?w=800']
  },
  {
    name: 'Central Park Multi-Sport Field',
    description: 'Versatile turf marked for football, rugby, and lacrosse, with rentable equipment.',
    location: 'Central Park',
    pricePerHour: 28,
    amenities: ['Equipment Rental', 'Parking', 'Refreshments'],
    images: ['https://images.unsplash.com/photo-1517649763962-0c623066013b?w=800']
  }
];

function daysFromNow(days) {
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d.toISOString().slice(0, 10);
}

async function seed() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected to DB');

  // Wipe demo-relevant collections. This script is meant for a dedicated demo/dev database.
  await Promise.all([
    Booking.deleteMany({}),
    Review.deleteMany({}),
    Venue.deleteMany({}),
    User.deleteMany({})
  ]);

  // The Booking unique index changed shape (now a partial index scoped to non-cancelled
  // statuses) after this cluster's indexes were first created. Mongoose won't migrate an
  // existing index automatically, so reconcile it here.
  await Booking.syncIndexes();

  const createdUsers = {};
  for (const u of USERS) {
    createdUsers[u.email] = await User.create({ ...u, password: DEMO_PASSWORD });
  }
  console.log(`Seeded ${USERS.length} users (password for all: "${DEMO_PASSWORD}")`);

  const owner = createdUsers['owner@turfwar.demo.com'];
  const createdVenues = [];
  for (const v of VENUES) {
    createdVenues.push(await Venue.create({ ...v, owner: owner._id }));
  }
  console.log(`Seeded ${createdVenues.length} venues`);

  const regularUsers = [createdUsers['user@turfwar.demo.com'], createdUsers['nate@turfwar.demo.com']];
  const bookingSpecs = [
    { venue: 0, user: 0, date: daysFromNow(-10), startTime: '18:00', endTime: '19:00', status: 'confirmed', paymentStatus: 'paid' },
    { venue: 1, user: 1, date: daysFromNow(-5), startTime: '10:00', endTime: '11:00', status: 'confirmed', paymentStatus: 'paid' },
    { venue: 2, user: 0, date: daysFromNow(-2), startTime: '09:00', endTime: '11:00', status: 'cancelled', paymentStatus: 'unpaid' },
    { venue: 3, user: 1, date: daysFromNow(2), startTime: '17:00', endTime: '18:00', status: 'pending', paymentStatus: 'unpaid' },
    { venue: 0, user: 1, date: daysFromNow(4), startTime: '19:00', endTime: '20:00', status: 'confirmed', paymentStatus: 'paid' },
    { venue: 4, user: 0, date: daysFromNow(6), startTime: '20:00', endTime: '21:00', status: 'pending', paymentStatus: 'unpaid' }
  ];

  for (const spec of bookingSpecs) {
    const venue = createdVenues[spec.venue];
    const hours = (() => {
      const [sh, sm] = spec.startTime.split(':').map(Number);
      const [eh, em] = spec.endTime.split(':').map(Number);
      return ((eh * 60 + em) - (sh * 60 + sm)) / 60;
    })();
    await Booking.create({
      user: regularUsers[spec.user]._id,
      venue: venue._id,
      date: spec.date,
      startTime: spec.startTime,
      endTime: spec.endTime,
      price: Math.round(venue.pricePerHour * hours * 100) / 100,
      status: spec.status,
      paymentStatus: spec.paymentStatus
    });
  }
  console.log(`Seeded ${bookingSpecs.length} bookings`);

  const reviewSpecs = [
    { venue: 0, user: 1, rating: 5, comment: 'Great turf, floodlights made a huge difference for our evening match.' },
    { venue: 1, user: 0, rating: 4, comment: 'Solid hardwood court, could use better seating.' },
    { venue: 2, user: 1, rating: 5, comment: 'Best cricket ground in the area, nets are a great bonus.' },
    { venue: 3, user: 0, rating: 3, comment: 'Courts are fine but rental rackets were worn out.' }
  ];

  for (const spec of reviewSpecs) {
    await Review.create({
      venue: createdVenues[spec.venue]._id,
      user: regularUsers[spec.user]._id,
      rating: spec.rating,
      comment: spec.comment
    });
  }
  console.log(`Seeded ${reviewSpecs.length} reviews`);

  console.log('\nDemo credentials (all use password "password123"):');
  for (const u of USERS) {
    console.log(`  ${u.role.padEnd(12)} ${u.email}`);
  }

  await mongoose.disconnect();
  console.log('\nDone.');
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
