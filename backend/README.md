# Turf War — Backend

Node.js/Express + MongoDB API: auth, venues, bookings, Stripe payments,
Cloudinary image uploads, and Socket-free realtime chat via Firestore on the
client side. See the [root README](../README.md) for the full-project
picture and [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) /
[docs/API.md](../docs/API.md) for details.

## Setup

```bash
cp .env.example .env   # fill in Mongo URI + Stripe/Cloudinary keys, see below
npm install
npm run seed            # idempotent — creates demo users/venues/bookings
npm run dev
```

`GET /health` should return `{"status":"ok","db":"connected"}`.
Swagger UI is at `/api-docs`.

### Required env vars

See [.env.example](.env.example) for the full list with comments. At
minimum you need `MONGO_URI` and `JWT_SECRET` to boot; `STRIPE_SECRET_KEY`
and `CLOUDINARY_*` are needed for payments and image uploads respectively.
Firebase push notifications are optional and silently disabled if unset.

## Scripts

| Command | Does |
|---|---|
| `npm run dev` | Start with `node --watch` (auto-restart on change) |
| `npm start` | Start without watch (production) |
| `npm run lint` | ESLint |
| `npm test` | Jest + Supertest against an in-memory MongoDB |
| `npm run test:coverage` | Same, with coverage report |
| `npm run seed` | Idempotent demo data — safe to run repeatedly, including against a live Atlas cluster |

## Testing

67 tests across `auth`, `venues`, `bookings`, `payments`, and `rbac`,
running against `mongodb-memory-server` rather than mocks — see
[docs/CONTRIBUTING.md](../docs/CONTRIBUTING.md#testing-philosophy) for why.
`app.js` is exported separately from `server.js` specifically so Supertest
can import the Express app without opening a real port or DB connection.

## Notable implementation details

- **Booking price is computed server-side** from `venue.pricePerHour` — the
  client's request body is never trusted for price. See
  [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md#booking-flow-server-side-pricing).
- **A partial unique index on `Booking`** (`{venue, date, startTime}`,
  scoped to non-cancelled statuses) rejects double-bookings at the database
  layer.
- **`venueScopeFilter`** (`utils/scopeVenues.js`) is the single place that
  decides whether a query is scoped to one owner or spans the whole
  platform for admin — reused by `getAnalytics`, `getOwnerBookings`, and
  `getMyVenues` rather than duplicated per controller.
- **Centralized error handling** — controllers throw/`next(new
  ErrorResponse(...))` and never write their own try/catch boilerplate;
  `middleware/asyncHandler.js` + `middleware/errorHandler.js` catch
  everything at the edges.
- Stripe webhook signature verification needs the *raw* request body, so
  `/payments/webhook` is mounted before `express.json()` in `app.js` — if
  you add global body-parsing middleware, make sure it still comes after
  that route.
- `express-mongo-sanitize` is **not** used here — it reassigns `req.query`,
  which Express 5 made a read-only getter, and crashes every request. A
  small custom in-place sanitizer lives at `middleware/sanitize.js` instead.

## Deployment

Deployed on Render as a Docker web service from `backend/Dockerfile`. This
repo is a monorepo, so all three of Render's Docker fields matter and are
resolved **relative to Root Directory**, not the repo root:

- **Root Directory:** `backend`
- **Docker Build Context Directory:** `.` (relative to Root Directory, so
  effectively `backend/`)
- **Dockerfile Path:** `Dockerfile` (bare filename, relative to Root
  Directory)

This matches `docker-compose.yml`'s `build: ./backend`, so
`backend/Dockerfile`'s `COPY package*.json ./` resolves the same way in
both places. Leaving Root Directory empty and trying to compensate with a
`backend/`-prefixed Context/Dockerfile Path leads to either doubled paths
(`backend/backend/Dockerfile`) or a build that "succeeds" but silently
excludes `package-lock.json` from the build context, failing `npm ci` with
`EUSAGE`.
