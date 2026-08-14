# API Reference

This is a summary of the main resources and the auth model. Full
request/response schemas — generated from JSDoc on each route — are served
live at `/api-docs` (Swagger UI) on the running backend:
https://turf-war-platform.onrender.com/api-docs.

Base URL: `https://turf-war-platform.onrender.com/api` (or
`http://localhost:3000/api` running locally).

## Auth model

All endpoints except registration, login, venue browsing, and the Stripe
webhook require a JWT in `Authorization: Bearer <token>`, obtained from
`POST /auth/login`.

Three roles, enforced by `authorize(...roles)` middleware at the route
level (not just hidden in the UI):

| Role | Can do |
|---|---|
| `user` | Browse venues, book, pay, review, chat |
| `venue_owner` | Everything `user` can, plus list/manage their own venues and see bookings/analytics scoped to those venues |
| `admin` | Everything `venue_owner` can, but scoped to **every** venue on the platform, plus user management |

Where a route is owner/admin-scoped, the actual data returned is filtered by
`venueScopeFilter` — `{}` (no filter) for admin, `{ owner: user.id }` for
`venue_owner`. See [ARCHITECTURE.md](ARCHITECTURE.md#role-based-data-scoping).

## Auth

| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `/auth/register` | — | Rate-limited (strict) |
| POST | `/auth/login` | — | Rate-limited (strict) |
| GET | `/auth/me` | user | Current user profile |
| PUT | `/auth/fcm-token` | user | Register device token for push notifications |
| GET | `/auth/users` | admin | List all users |
| PUT | `/auth/users/:id/role` | admin | Change a user's role |

## Venues

| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/venues` | — | Paginated list, supports sorting |
| GET | `/venues/search` | — | Filter by name/location, price range, amenities |
| GET | `/venues/mine` | owner/admin | Scoped: own venues, or all venues for admin |
| GET | `/venues/:id` | — | Venue detail |
| POST | `/venues` | owner/admin | Multipart (images via Cloudinary) |
| PUT | `/venues/:id` | owner/admin | JSON only — no image re-upload on update |
| DELETE | `/venues/:id` | owner/admin | Cascades: deletes the venue's bookings and reviews |

## Bookings

| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `/bookings` | user | **Price is computed server-side** from `venue.pricePerHour`, never trusted from the request |
| GET | `/bookings/my` | user | Caller's own bookings |
| GET | `/bookings/owner` | owner/admin | Scoped: bookings for own venues, or all for admin |
| GET | `/bookings/venue/:venueId` | — | Public: a venue's booked slots (for the availability grid) |
| PATCH | `/bookings/:id/cancel` | user | Booking owner only |
| PATCH | `/bookings/:id/status` | owner/admin | Confirm/reject a pending booking |

Double-booking is rejected at the database layer by a partial unique index
on `{venue, date, startTime}` (scoped to non-cancelled bookings) — see
[ARCHITECTURE.md](ARCHITECTURE.md#data-model).

## Payments (Stripe)

| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `/payments/create-payment-intent` | user | Booking-owner check; rejects if already paid |
| POST | `/payments/webhook` | — (Stripe signature) | Marks booking paid on `payment_intent.succeeded` |
| POST | `/payments/confirm` | user | Client-driven fallback — polls Stripe directly rather than trusting the client's word |

Both the webhook and `/confirm` funnel into the same idempotent
`markBookingPaid()`, since either can be the first to observe a succeeded
payment. See [ARCHITECTURE.md](ARCHITECTURE.md#payment-flow-dual-confirmation-path).

## Reviews

| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/venues/:venueId/reviews` | — | A venue's reviews |
| POST | `/venues/:venueId/reviews` | user | One review per user per venue; owners can't review their own venue |

## Analytics

| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/analytics` | owner/admin | Single `$facet` aggregation: revenue, booking counts, active venues, 30-day revenue series. Scoped by `venueScopeFilter` |

## Misc

| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/health` | — | Used as the Render health check |

## Errors

Every error response has the shape:

```json
{ "success": false, "error": "message" }
```

Validation errors (from `express-validator`) return `400` with the first
failing field's message. Auth failures return `401` (missing/invalid token)
or `403` (valid token, wrong role or not the resource owner).

## Rate limiting

`POST /auth/register` and `POST /auth/login` are rate-limited more strictly
than the rest of the API (`express-rate-limit`), to slow down credential
stuffing / brute force without affecting normal browsing traffic.
