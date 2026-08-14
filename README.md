# Turf War

A full-stack turf/sports-venue booking platform: a Node/Express + MongoDB API,
a Flutter mobile app (Android/iOS/Web) for players and venue owners, and a
React admin dashboard.

## Live demo

| | |
|---|---|
| **Web admin** | https://turf-war-platform.vercel.app |
| **Mobile (web build)** | https://turf-war-platform-pfwq.vercel.app |
| **Android APK** | See [Releases](../../releases) |
| **API** | https://turf-war-platform.onrender.com (`/health`, `/api-docs`) |

> The backend is on Render's free tier, which cold-starts after 15 minutes of
> inactivity — the first request after a while can take ~50s. Everything
> after that is normal speed.

### Demo credentials

Seeded by `backend/scripts/seed.js`, all sharing one password:

| Role | Email | Password |
|---|---|---|
| Admin | `admin@turfwar.demo.com` | `password123` |
| Venue owner | `owner@turfwar.demo.com` | `password123` |
| Venue owner | `owner2@turfwar.demo.com` | `password123` |
| Player | `user@turfwar.demo.com` | `password123` |

The web-admin dashboard only supports the `admin` and `venue_owner` roles.
The `user` role is for the mobile app. There are two seeded venue owners
(5 venues / 3 venues) so you can see the admin's platform-wide view against
each owner's scoped view — log in as one, then the other, to compare.

### About the web build of the mobile app

The Flutter app is normally a native Android/iOS app; the web build in
`web-demo/` is a build-time `DEMO_MODE` variant that stubs the Stripe payment
sheet (shows a simulated success) and skips Firebase Cloud Messaging
registration, since neither works in a browser context. A notice on the
Profile screen makes this explicit. The Android APK is the real thing —
live Stripe test-mode payments and push notifications.

## Architecture

```
backend/      Node.js + Express + MongoDB API (JWT auth, Stripe payments,
              Cloudinary image uploads, Socket.io chat)
mobile-app/   Flutter app — players book venues, owners manage listings
web-admin/    React + Vite admin dashboard for venue owners and admins
web-demo/     Committed static build of mobile-app for web (see its README)
```

- API docs: `/api-docs` (Swagger/OpenAPI) on the running backend
- Backend tests: `cd backend && npm test` (Jest + Supertest, in-memory Mongo)
- Mobile tests: `cd mobile-app && flutter test`
- Web admin tests: `cd web-admin && npm test` (Vitest)
- CI: `.github/workflows/ci.yml` runs all three on every push

## Running locally

Each subproject has its own `.env.example` — copy it to `.env` and fill in
values, or run everything with Docker:

```bash
docker compose up --build
```

See `backend/.env.example`, `web-admin/README.md`, and `mobile-app/run.sh` /
`mobile-app/.env.example` for subproject-specific instructions.
