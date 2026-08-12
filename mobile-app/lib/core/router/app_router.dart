import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/user_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/bookings/screens/booking_screen.dart';
import '../../features/bookings/screens/my_bookings_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/venues/screens/add_venue_screen.dart';
import '../../features/venues/screens/home_screen.dart';
import '../../features/venues/screens/venue_details_screen.dart';
import '../../models/venue_model.dart';
import 'app_routes.dart';

/// Builds the app's router.
///
/// Navigation used to be inline `Navigator.push(MaterialPageRoute(...))` at
/// roughly eight call sites, with auth handled by a splash screen that manually
/// `pushReplacement`-ed to either login or home. Both concerns now live here:
/// routes are named and declared once, and [_redirect] is the single place that
/// decides whether the user may see a screen.
GoRouter buildRouter(UserProvider userProvider) {
  return GoRouter(
    initialLocation: AppRoutes.splashPath,
    // Re-runs the redirect whenever auth state changes, so a 401-triggered
    // logout anywhere in the app bounces to the login screen on its own.
    refreshListenable: userProvider,
    redirect: (BuildContext context, GoRouterState state) =>
        authRedirect(userProvider.status, state.matchedLocation),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splashPath,
        name: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.loginPath,
        name: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerPath,
        name: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.homePath,
        name: AppRoutes.home,
        builder: (_, __) => const HomeScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.venueDetailsPath,
            name: AppRoutes.venueDetails,
            builder: (BuildContext context, GoRouterState state) {
              return VenueDetailsScreen(
                venueId: state.pathParameters['venueId']!,
                // Passed when navigating from the list so the screen can render
                // immediately; null on a cold deep link, which triggers a fetch.
                initialVenue: state.extra as VenueModel?,
              );
            },
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.bookingPath,
                name: AppRoutes.booking,
                builder: (BuildContext context, GoRouterState state) {
                  return BookingScreen(venue: state.extra! as VenueModel);
                },
              ),
              GoRoute(
                path: AppRoutes.chatPath,
                name: AppRoutes.chat,
                builder: (BuildContext context, GoRouterState state) {
                  return ChatScreen(
                    receiverId: state.pathParameters['receiverId']!,
                    receiverName:
                        state.uri.queryParameters['name'] ?? 'Venue owner',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.myBookingsPath,
            name: AppRoutes.myBookings,
            builder: (_, __) => const MyBookingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.addVenuePath,
            name: AppRoutes.addVenue,
            builder: (_, __) => const AddVenueScreen(),
          ),
          GoRoute(
            path: AppRoutes.profilePath,
            name: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('No route for ${state.uri}'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.goNamed(AppRoutes.home),
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The app's only auth gate.
///
/// Returning null means "allow"; returning a path redirects there. Written as a
/// pure function of ([status], [location]) rather than reading the provider and
/// router state directly, so the whole redirect matrix is unit-testable.
@visibleForTesting
String? authRedirect(AuthStatus status, String location) {
  // Still validating the stored token — hold on the splash screen so an
  // already-signed-in user never sees the login form flash past.
  if (status == AuthStatus.unknown) {
    return location == AppRoutes.splashPath ? null : AppRoutes.splashPath;
  }

  // The two screens a signed-out user is allowed to sit on. Splash is not one
  // of them: once the status has resolved there is nothing left to wait for.
  final bool onSignedOutScreen =
      location == AppRoutes.loginPath || location == AppRoutes.registerPath;

  if (status == AuthStatus.unauthenticated) {
    return onSignedOutScreen ? null : AppRoutes.loginPath;
  }

  // Authenticated: bounce off the auth screens (including splash) into the app.
  return (onSignedOutScreen || location == AppRoutes.splashPath)
      ? AppRoutes.homePath
      : null;
}
