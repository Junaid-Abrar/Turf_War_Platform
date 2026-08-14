# Contributing

This is primarily a portfolio project, but it's built and tested the way a
real project would be — real CI, real tests, no shortcuts on auth or
payment correctness. If you're poking around, extending it, or using it as
a reference, this is how to work in it.

## Local setup

Each subproject is independent (own `package.json`/`pubspec.yaml`, own
`.env`). Fastest path to all three running together:

```bash
docker compose up --build
```

Or run them individually — see [backend/README.md](../backend/README.md),
[mobile-app/README.md](../mobile-app/README.md), and
[web-admin/README.md](../web-admin/README.md) for the manual steps and the
env vars each one needs.

## Branch and commit conventions

- Branch off `main`; no long-lived branches.
- Commit messages: `type(scope): summary` — `feat(backend): …`,
  `fix(mobile-app): …`, `docs: …`, `chore: …`. Scope is the subproject
  directory when a change is confined to one.
- Keep commits scoped to one logical change. A bug fix and an unrelated
  refactor belong in separate commits even if they touch the same file.

## Before opening a PR

Run the relevant subproject's checks locally — CI runs the same commands,
so this just gets you the feedback sooner:

```bash
# Backend
cd backend && npm run lint && npm test

# Mobile
cd mobile-app && flutter analyze --fatal-infos && flutter test

# Web admin
cd web-admin && npm run lint && npm test && npm run build
```

`.github/workflows/ci.yml` runs all three as separate jobs on every push and
PR to `main`. All three must be green before merging.

## Testing philosophy

- **Backend tests hit a real (in-memory) MongoDB**, not mocks
  (`mongodb-memory-server`). A mocked database call would have hidden the
  exact partial-index bug this project shipped a fix for — see
  [ARCHITECTURE.md](ARCHITECTURE.md#data-model). If you add a query, prefer
  a test that exercises it against a real collection.
- **RBAC is tested at the route, not just unit-tested in isolation** —
  `backend/test/rbac.test.js` sends real requests with real tokens for each
  role and asserts on the HTTP status, because that's the thing that
  actually protects the deployed API.
- **Mobile widget tests avoid golden-testing anything with `pumpAndSettle`
  on an infinite animation** (e.g. the shimmer loader) — it hangs forever.
  See the golden tests in `mobile-app/test/golden/` for the pattern
  (`tester.runAsync` around image capture, frozen mid-animation instead of
  settled).
- New backend routes that mutate data should get `express-validator` rules
  and a corresponding test in the relevant `backend/test/*.test.js` file,
  not manual `if` checks in the controller.

## Adding a new role-scoped endpoint

If you're adding an endpoint that should behave differently for `admin` vs
`venue_owner` (the way `/analytics`, `/bookings/owner`, and `/venues/mine`
do), reuse `venueScopeFilter` from `backend/utils/scopeVenues.js` rather
than writing a new `owner: req.user.id` filter — that's the one place the
admin-vs-owner distinction should live.

## Regenerating mobile app icons/screenshots

App icons and the native splash screen are generated from the in-app logo
painter via a headless Flutter test, not a design tool export (no Xcode on
the dev machine this was built on — `flutter test` provides a Skia surface
without one):

```bash
cd mobile-app
flutter test --run-skipped test/tool/generate_icons_test.dart
flutter test --run-skipped test/tool/screenshots_test.dart
```

Both are tagged `tool` and skipped by default (see `dart_test.yaml`) so CI
never silently rewrites committed assets.

## Reporting issues

Use [GitHub Issues](../../issues). Include the role you were logged in as
(`user` / `venue_owner` / `admin`) and, for backend issues, the response
body of the failing request if you have it — most API errors return a
useful `{ "success": false, "error": "..." }` message.
