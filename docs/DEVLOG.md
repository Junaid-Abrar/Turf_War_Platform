# Turf War Platform - Project Documentation

## Project Overview
"Turf War" is a comprehensive sports venue booking system designed to bridge the gap between sports enthusiasts and venue owners.

## Architecture
- **Mobile App (Flutter):** For users to discover venues and book slots.
- **Web Dashboard (React + Vite):** For venue owners to manage bookings and schedules.
- **Backend (Node.js + Express + MongoDB):** The central API server.

## Tech Stack
- **Frontend:** Flutter (Mobile), React + Vite (Web)
- **Backend:** Node.js, Express.js
- **Database:** MongoDB Atlas (Cloud)
- **Authentication:** JWT (JSON Web Tokens) & Bcrypt
- **Image Storage:** Cloudinary
- **State Management:** Provider (Flutter)
- **Real-time & Notifications:** Firebase (Firestore & Cloud Messaging)
- **Payment Gateway:** Stripe

## Development Journal
- **Phase 1:** Project Setup & Hello World Backend.
- **Phase 2:** Database Setup. Connected Node.js to MongoDB Atlas using Mongoose.
- **Phase 3:** User Model. Created Mongoose schema with name, email, password, and role.
- **Phase 4:** User Registration. Built API endpoint `/api/auth/register`.
- **Phase 5:** Security. Implemented password hashing with `bcryptjs`.
- **Phase 6:** Authentication. Implemented `/api/auth/login` and JWT generation.
- **Phase 7:** Protected Routes. Created `protect` middleware to verify JWT tokens and secure API endpoints.
- **Phase 8:** Role-Based Access Control (RBAC). Added `authorize` middleware to restrict access based on user roles (e.g., Admin only).
- **Phase 9:** Mobile App Setup. Created Flutter project with Provider, Http, and Secure Storage. Implemented Auth Service (connecting to localhost via Ngrok) and built Login/Register UI.
- **Phase 10:** Home Screen & Auto-Login. Implemented `SplashScreen` for token checks, `HomeScreen` with user details, and full Login/Logout navigation flow.
- **Phase 11:** Venue Management (Backend). Created `Venue` model (Mongoose), `VenuesController` (CRUD logic), and secured Routes. Verified permission logic (Admin vs User).
- **Phase 12:** Venue Display (Mobile). Implemented `VenueService` and `VenueProvider` in Flutter. Created a card-based UI in `HomeScreen` to display the list of venues fetched from the API.
- **Phase 13:** Image Infrastructure. Integrated Cloudinary for image uploads. Updated Backend to handle file uploads. Created `AddVenueScreen` in Flutter with Image Picker.
- **Phase 14:** Booking Logic (Backend). Created `Booking` model, Controller with conflict detection, and API endpoints (`POST /bookings`, `GET /bookings/my`, `GET /bookings/venue/:id`).
- **Phase 15:** Booking UI (Mobile). Implemented `BookingModel`, `BookingService`, and `BookingProvider`. Created `VenueDetailsScreen`, `BookingScreen` (with date/slot selection), and `MyBookingsScreen`. Integrated with Backend and verified via static analysis.
- **Phase 16:** Admin Dashboard (Web). Scaffolder React+Vite app. Implemented Auth (Login, Protected Routes), Venue Management (List, Add, Delete), and Booking Management (View all bookings for owner). Added backend endpoint `GET /api/bookings/owner`.
- **Phase 17:** Push Notifications & Security. Integrated Firebase Cloud Messaging (FCM) for real-time booking alerts. Updated backend to trigger notifications on new bookings and status changes. Secured sensitive credentials (`google-services.json`, `service-account.json`) by removing them from version control and updating `.gitignore`.
- **Phase 18:** Payments Integration. Integrated Stripe SDK into both Backend and Mobile (Flutter). Implemented PaymentIntent creation, mobile Payment Sheet, and Backend Webhooks to confirm bookings automatically upon successful payment. Updated Web Admin to display payment status.
- **Phase 19:** Real-time Chat. Implemented a messaging system using Cloud Firestore. Added "Chat with Owner" to Mobile app and a "Messages" tab to the Web Admin Dashboard. Features include real-time synchronization, chat history, and sender identification.
- **Phase 20:** Search & Filters. Implemented advanced search in Backend (by name, price, amenities). Added Search Bar and Filter Modal to Mobile App.
- **Phase 21:** Analytics & Reports. Created Backend endpoint to aggregate venue metrics (revenue, bookings). Implemented Analytics Dashboard in Web Admin using Recharts.
- **Phase 22:** User Reviews. Added Review model and controller in Backend to handle ratings and comments. Updated Venue model to track average rating. Implemented "Write Review" and Review List in Mobile App.
- **Phase 23:** User Management (Web Admin). Added endpoints `GET /api/auth/users` and `PUT /api/auth/users/:id/role` to the Backend for listing and modifying user roles. Built a `UserManagement` component in the React Web Admin to allow administrators to securely change user privileges.