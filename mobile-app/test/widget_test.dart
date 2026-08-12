// App-boot smoke test.
//
// The real entry point, `TurfWarApp` in lib/main.dart, constructs its own
// `TokenStorage`/`ApiClient`/Firebase-backed services inline in `initState`
// with no injection seam, and calls `Firebase.initializeApp()` before that —
// neither is available under `flutter test`. Rather than boot `TurfWarApp`
// itself, this wires the same pieces `main.dart` wires (`UserProvider` +
// `buildRouter`) with mocked services, which is the deepest boot achievable
// without touching application code. It exercises the real `SplashScreen` ->
// `authRedirect` -> `LoginScreen` path a cold, signed-out launch takes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/network/api_exception.dart';
import 'package:mobile_app/core/router/app_router.dart';
import 'package:mobile_app/core/services/notification_service.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/features/auth/providers/user_provider.dart';
import 'package:mobile_app/features/auth/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_token_storage.dart';

class MockAuthService extends Mock implements AuthService {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  testWidgets('renders a basic MaterialApp scaffold', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        title: 'Turf War',
        theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
        home: const Scaffold(body: Center(child: Text('TURF WAR'))),
      ),
    );

    expect(find.text('TURF WAR'), findsOneWidget);
  });

  testWidgets(
    'a cold launch with no stored token lands on the login screen',
    (WidgetTester tester) async {
      final MockAuthService authService = MockAuthService();
      final MockNotificationService notificationService =
          MockNotificationService();
      when(() => notificationService.init()).thenAnswer((_) async {});

      final UserProvider userProvider = UserProvider(
        authService: authService,
        tokenStorage: FakeTokenStorage(),
        notificationService: notificationService,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<UserProvider>.value(
          value: userProvider,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: buildRouter(userProvider),
          ),
        ),
      );

      // SplashScreen's tryAutoLogin fires from a post-frame callback.
      expect(find.text('TURF WAR'), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.text('Welcome back. Sign in to book your next slot.'),
          findsOneWidget);
      expect(userProvider.status, AuthStatus.unauthenticated);
    },
  );

  testWidgets(
    'a cold launch with a stale stored token clears it and drops back to login',
    (WidgetTester tester) async {
      // HomeScreen needs VenueProvider/BookingProvider that this minimal
      // harness does not wire up (see the file comment), so the "token is
      // still valid" path is not exercised here — only that a rejected token
      // is cleared and the redirect resolves, same as SplashScreen -> login
      // above but arriving via tryAutoLogin's failure branch instead of the
      // no-token branch.
      final MockAuthService authService = MockAuthService();
      final MockNotificationService notificationService =
          MockNotificationService();
      when(() => notificationService.init()).thenAnswer((_) async {});
      when(() => authService.getProfile(token: any(named: 'token'))).thenThrow(
        const ApiException('Not authorized', kind: ApiExceptionKind.badResponse),
      );

      final FakeTokenStorage tokenStorage = FakeTokenStorage('stale-token');
      final UserProvider userProvider = UserProvider(
        authService: authService,
        tokenStorage: tokenStorage,
        notificationService: notificationService,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<UserProvider>.value(
          value: userProvider,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: buildRouter(userProvider),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(userProvider.status, AuthStatus.unauthenticated);
      expect(tokenStorage.cachedToken, isNull);
      expect(find.text('Welcome back. Sign in to book your next slot.'),
          findsOneWidget);
    },
  );
}
