import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/core/router/app_router.dart';
import 'package:mobile_app/core/router/app_routes.dart';
import 'package:mobile_app/features/auth/providers/user_provider.dart';

/// Route-shape tests.
///
/// `flutter analyze` cannot catch a mismatch between a route's declared path
/// parameters and the ones a `goNamed` call supplies — that only surfaces as a
/// runtime assertion when a user taps through. These tests resolve every named
/// route against the same path table the app uses, so a missing or misspelled
/// parameter fails in CI instead.
void main() {
  // Mirrors the structure in `buildRouter`, without the screen widgets so the
  // test needs no Firebase or provider setup.
  RouteConfiguration config() {
    final GoRouter router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.splashPath,
          name: AppRoutes.splash,
          builder: (_, __) => const _Stub(),
        ),
        GoRoute(
          path: AppRoutes.loginPath,
          name: AppRoutes.login,
          builder: (_, __) => const _Stub(),
        ),
        GoRoute(
          path: AppRoutes.registerPath,
          name: AppRoutes.register,
          builder: (_, __) => const _Stub(),
        ),
        GoRoute(
          path: AppRoutes.homePath,
          name: AppRoutes.home,
          builder: (_, __) => const _Stub(),
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.venueDetailsPath,
              name: AppRoutes.venueDetails,
              builder: (_, __) => const _Stub(),
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoutes.bookingPath,
                  name: AppRoutes.booking,
                  builder: (_, __) => const _Stub(),
                ),
                GoRoute(
                  path: AppRoutes.chatPath,
                  name: AppRoutes.chat,
                  builder: (_, __) => const _Stub(),
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.myBookingsPath,
              name: AppRoutes.myBookings,
              builder: (_, __) => const _Stub(),
            ),
            GoRoute(
              path: AppRoutes.addVenuePath,
              name: AppRoutes.addVenue,
              builder: (_, __) => const _Stub(),
            ),
            GoRoute(
              path: AppRoutes.profilePath,
              name: AppRoutes.profile,
              builder: (_, __) => const _Stub(),
            ),
          ],
        ),
      ],
    );
    return router.configuration;
  }

  group('named route resolution', () {
    test('top-level routes resolve to their paths', () {
      final RouteConfiguration routes = config();
      expect(routes.namedLocation(AppRoutes.splash), '/');
      expect(routes.namedLocation(AppRoutes.login), '/login');
      expect(routes.namedLocation(AppRoutes.register), '/register');
      expect(routes.namedLocation(AppRoutes.home), '/home');
    });

    test('home sub-routes nest under /home', () {
      final RouteConfiguration routes = config();
      expect(routes.namedLocation(AppRoutes.myBookings), '/home/bookings');
      expect(routes.namedLocation(AppRoutes.addVenue), '/home/add-venue');
      expect(routes.namedLocation(AppRoutes.profile), '/home/profile');
    });

    test('venue details takes a venueId', () {
      final RouteConfiguration routes = config();
      expect(
        routes.namedLocation(
          AppRoutes.venueDetails,
          pathParameters: <String, String>{'venueId': 'abc123'},
        ),
        '/home/venue/abc123',
      );
    });

    test('booking nests under its venue', () {
      final RouteConfiguration routes = config();
      expect(
        routes.namedLocation(
          AppRoutes.booking,
          pathParameters: <String, String>{'venueId': 'abc123'},
        ),
        '/home/venue/abc123/book',
      );
    });

    // Chat sits under the venue route, so it needs *both* ids — passing only
    // receiverId (the obvious mistake) must fail loudly here rather than in the
    // app.
    test('chat requires both venueId and receiverId', () {
      final RouteConfiguration routes = config();
      expect(
        routes.namedLocation(
          AppRoutes.chat,
          pathParameters: <String, String>{
            'venueId': 'abc123',
            'receiverId': 'owner1',
          },
          queryParameters: <String, String>{'name': 'Owner'},
        ),
        '/home/venue/abc123/chat/owner1?name=Owner',
      );

      expect(
        () => routes.namedLocation(
          AppRoutes.chat,
          pathParameters: <String, String>{'receiverId': 'owner1'},
        ),
        throwsA(anything),
      );
    });
  });

  // The redirect is the only thing standing between a signed-out visitor and
  // the booking screens, so every cell of the matrix is pinned down here.
  group('auth redirect', () {
    test('holds on splash while the stored token is being validated', () {
      expect(authRedirect(AuthStatus.unknown, AppRoutes.splashPath), isNull);
      expect(
        authRedirect(AuthStatus.unknown, AppRoutes.homePath),
        AppRoutes.splashPath,
      );
      expect(
        authRedirect(AuthStatus.unknown, '/home/venue/v1'),
        AppRoutes.splashPath,
      );
    });

    test('sends a signed-out user to login from any protected route', () {
      for (final String location in <String>[
        AppRoutes.homePath,
        '/home/venue/v1',
        '/home/venue/v1/book',
        '/home/bookings',
        '/home/profile',
        '/home/add-venue',
        AppRoutes.splashPath,
      ]) {
        expect(
          authRedirect(AuthStatus.unauthenticated, location),
          AppRoutes.loginPath,
          reason: '$location should redirect a signed-out user to login',
        );
      }
    });

    test('lets a signed-out user reach login and register', () {
      expect(
        authRedirect(AuthStatus.unauthenticated, AppRoutes.loginPath),
        isNull,
      );
      expect(
        authRedirect(AuthStatus.unauthenticated, AppRoutes.registerPath),
        isNull,
      );
    });

    test('bounces a signed-in user off the auth screens', () {
      expect(
        authRedirect(AuthStatus.authenticated, AppRoutes.loginPath),
        AppRoutes.homePath,
      );
      expect(
        authRedirect(AuthStatus.authenticated, AppRoutes.registerPath),
        AppRoutes.homePath,
      );
      // Resolving auto-login on the splash screen must move on, not stick.
      expect(
        authRedirect(AuthStatus.authenticated, AppRoutes.splashPath),
        AppRoutes.homePath,
      );
    });

    test('leaves a signed-in user on protected routes', () {
      for (final String location in <String>[
        AppRoutes.homePath,
        '/home/venue/v1',
        '/home/venue/v1/book',
        '/home/venue/v1/chat/o1',
        '/home/bookings',
        '/home/profile',
      ]) {
        expect(
          authRedirect(AuthStatus.authenticated, location),
          isNull,
          reason: '$location should be reachable when signed in',
        );
      }
    });
  });
}

class _Stub extends StatelessWidget {
  const _Stub();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
