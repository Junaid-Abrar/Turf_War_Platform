# Turf War — Mobile

Flutter app for players and venue owners: browse/book venues, pay with
Stripe, manage bookings, chat with venue owners, and (for owners) list and
manage venues. Builds to Android, iOS, and web. See the
[root README](../README.md) for the full-project picture.

## Setup

```bash
cp .env.example .env   # edit API_BASE_URL for your platform, see below
./run.sh                # builds --dart-define flags from .env and runs
```

Flutter has no runtime `.env` — every config value is a compile-time
`--dart-define` constant, read through `lib/core/config/app_config.dart`.
`run.sh` exists so you don't have to type five `--dart-define` flags by
hand (a hardcoded ngrok URL is how the previous version of this app ended
up with a dead URL committed — see `.env.example` for the full explanation).

### `API_BASE_URL` by platform

| Target | URL |
|---|---|
| Android emulator | `http://10.0.2.2:3000/api` (`10.0.2.2` = host machine) |
| iOS simulator | `http://localhost:3000/api` |
| Physical device | `http://<your-lan-ip>:3000/api` |
| Deployed | `https://<your-app>.onrender.com/api` |

## Demo mode

Set `DEMO_MODE=true` to stub the Stripe payment sheet (simulated success,
no real PaymentIntent) and skip Firebase Cloud Messaging registration —
this is what the committed `web-demo/` build uses, since neither Stripe's
full payment UI nor FCM works reliably in a browser context. A banner on
the Profile screen makes demo mode visible when it's on. Leave it `false`
for a real device build.

The login screen also has a **"Use a demo account"** picker (player / venue
owner / administrator) so you don't need to type credentials to explore the
app.

## Project structure

```
lib/
  features/{auth,venues,bookings,chat,payments,profile}/   feature modules
  core/{config,network,router,services,utils,widgets}/     cross-cutting
```

- `core/network/api_client.dart` — `dio`-based client with one auth
  interceptor and one error interceptor mapping every failure to a typed
  `ApiException`, plus an `onUnauthorized` hook that clears the session
  app-wide on any 401.
- `core/router/` — `go_router` with a single `authRedirect(AuthStatus,
  location)` pure function deciding where to send an unauthenticated/
  authenticated user; it's `@visibleForTesting` specifically so the
  redirect matrix is unit-testable without booting the app.
- `core/theme/` — light/dark theme built from one shared base, persisted
  via `shared_preferences`, loaded before `runApp`.
- `core/widgets/` — the shared design-system components (buttons, cards,
  shimmer skeletons, rating stars, status badges) every screen is built on.

## Scripts / commands

| Command | Does |
|---|---|
| `./run.sh` | Run on the default device, with `.env` defines |
| `./run.sh -d chrome` | Run in Chrome (extra args pass through) |
| `./run.sh build apk --release` | Build a release APK |
| `flutter analyze --fatal-infos` | Static analysis (CI-gated) |
| `flutter test` | Full test suite |
| `flutter test --coverage` | Same, with coverage |

## Testing

84 tests, 2 skipped (asset-generator tool tests — see below). Providers are
tested with `mocktail` mocking the concrete service classes directly (no
interfaces needed — they were already constructor-injected). Widget tests
cover form validation, navigation, and the time-slot picker. Golden tests
in `test/golden/` snapshot the design system in both themes.

Two gotchas if you're adding to the golden tests: wrap image capture in
`tester.runAsync` (`toImage`/`toByteData` hang forever in the fake-async
zone), and never `pumpAndSettle` on anything with a looping animation like
the shimmer loader — it never settles.

## Regenerating app icons / screenshots

The app icon and native splash are generated from the same
`TurfWarLogoPainter` the app renders in-UI, via a headless test rather than
an image export (there's no Xcode on the machine this was built on, and
`flutter test` provides a Skia rendering surface without one):

```bash
flutter test --run-skipped test/tool/generate_icons_test.dart
flutter test --run-skipped test/tool/screenshots_test.dart
```

Both are tagged `tool` and skipped in normal test runs (`dart_test.yaml`),
so CI never silently rewrites committed assets.

## Web build caveats

`flutter_stripe` and `firebase_messaging` have limited or no web support —
that's what `DEMO_MODE` exists to work around. The committed `web-demo/` at
the repo root is a static `flutter build web --dart-define=DEMO_MODE=true
...` output, checked in because Vercel has no native Flutter build step.
