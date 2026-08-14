# Turf War — Web Admin

React + Vite dashboard for venue owners and admins: analytics, venue and
booking management, and (admin-only) user management and platform-wide
scope. See the [root README](../README.md) for the full-project picture.

## Setup

```bash
cp .env.example .env   # point VITE_API_URL at your backend
npm install
npm run dev
```

`VITE_FIREBASE_*` vars are only needed for the in-app chat feature — the
app runs fine with them empty (Firestore calls silently no-op and chat
shows an empty state rather than throwing).

## Scripts

| Command | Does |
|---|---|
| `npm run dev` | Dev server with HMR |
| `npm run build` | Production build to `dist/` |
| `npm run preview` | Serve the production build locally |
| `npm run lint` | ESLint |
| `npm test` | Vitest + Testing Library |

## Role-aware dashboard

`Dashboard.jsx` computes `isAdmin = user.role === 'admin'` once and threads
it as a prop into `AnalyticsDashboard`, `VenueList`, and `BookingList` —
each renders its admin-only affordance (an "Owner" column/line, a
platform-wide vs. "your" label, hiding "Add Venue" for admin) off that one
prop rather than re-deriving role state independently. The underlying data
is scoped server-side (see [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md#role-based-data-scoping)),
so this component is purely about labeling — it never has to hide data the
API already excludes.

## Notable implementation details

- **Dark mode** via `ThemeContext` (`localStorage` key `adminTheme`,
  defaulting to `prefers-color-scheme`), toggled through Bootstrap's
  `data-bs-theme` attribute on `<html>`. If you add a component with a
  hardcoded `bg-light`/`text-dark` combo, check it in dark mode —
  Bootstrap's theme attribute doesn't reach those on its own; see the
  `[data-bs-theme='dark']` override block in `src/custom.css` for the
  existing fix (badges) as a pattern.
- **Token expiry is checked client-side** on load and on login
  (`AuthContext` decodes the JWT's `exp`), in addition to the backend
  rejecting expired tokens — this avoids a UI that looks logged-in for a
  few seconds before the first API call 401s.
- Any `401` response clears the session and toasts, via an axios response
  interceptor (`setOnUnauthorized` hook in `api/axios.js`, wired from
  `AuthContext` — kept as a hook rather than a direct import to avoid a
  circular dependency between the two modules).

## Testing

11 tests (Vitest + Testing Library + jsdom): `AuthContext` covers the token
lifecycle (empty/valid/expired restore, login, logout), and
`Dashboard.test.jsx` renders with real `AuthContext`/`ThemeContext`
providers (not mocked context) to assert the brand/heading/button-visibility
differences between `venue_owner` and `admin`.

If you add a test that touches `localStorage` directly: Node's own
experimental global `localStorage` shadows jsdom's working implementation
on newer Node versions, because Vitest only overrides globals that are
either absent or in its own allowlist. `src/test/setup.js` has a small
polyfill guarded by `typeof localStorage.setItem !== 'function'`, so it's a
no-op where this doesn't manifest — you shouldn't need to touch it, but
it's why `localStorage.clear()` doesn't throw in this suite.
