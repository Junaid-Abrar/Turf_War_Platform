import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/core/network/api_exception.dart';
import 'package:mobile_app/core/router/app_routes.dart';
import 'package:mobile_app/core/services/notification_service.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/features/auth/providers/user_provider.dart';
import 'package:mobile_app/features/auth/screens/login_screen.dart';
import 'package:mobile_app/features/auth/services/auth_service.dart';
import 'package:mobile_app/models/user_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_token_storage.dart';

class MockAuthService extends Mock implements AuthService {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockAuthService authService;
  late UserProvider userProvider;

  setUp(() {
    authService = MockAuthService();
    final MockNotificationService notificationService =
        MockNotificationService();
    when(() => notificationService.init()).thenAnswer((_) async {});
    userProvider = UserProvider(
      authService: authService,
      tokenStorage: FakeTokenStorage(),
      notificationService: notificationService,
    );
  });

  /// Boots the real login route inside a minimal router carrying only the
  /// login/register paths, so the "Create an account" link's `goNamed` call
  /// resolves instead of throwing for want of a `GoRouter` ancestor.
  Widget hostedLoginScreen() {
    final GoRouter router = GoRouter(
      initialLocation: AppRoutes.loginPath,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.loginPath,
          name: AppRoutes.login,
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.registerPath,
          name: AppRoutes.register,
          builder: (_, __) => const Scaffold(body: Text('Register screen')),
        ),
      ],
    );

    return ChangeNotifierProvider<UserProvider>.value(
      value: userProvider,
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }

  testWidgets('shows validation errors for empty email and password',
      (WidgetTester tester) async {
    await tester.pumpWidget(hostedLoginScreen());

    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    verifyNever(() => authService.login(any(), any()));
  });

  testWidgets('rejects a malformed email address', (WidgetTester tester) async {
    await tester.pumpWidget(hostedLoginScreen());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'not-an-email',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    verifyNever(() => authService.login(any(), any()));
  });

  testWidgets('a valid submit calls into UserProvider.login',
      (WidgetTester tester) async {
    when(() => authService.login('ana@example.com', 'password123'))
        .thenAnswer(
      (_) async => const UserModel(
        id: 'u1',
        name: 'Ana',
        email: 'ana@example.com',
        role: 'user',
        token: 'tok',
      ),
    );

    await tester.pumpWidget(hostedLoginScreen());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'ana@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    verify(() => authService.login('ana@example.com', 'password123'))
        .called(1);
    expect(userProvider.isAuthenticated, isTrue);
  });

  testWidgets('a failed submit shows the ApiException message in a snackbar',
      (WidgetTester tester) async {
    when(() => authService.login(any(), any())).thenThrow(
      const ApiException('Invalid credentials',
          kind: ApiExceptionKind.badResponse),
    );

    await tester.pumpWidget(hostedLoginScreen());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'ana@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'wrongpass',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid credentials'), findsOneWidget);
    expect(userProvider.isAuthenticated, isFalse);
  });

  testWidgets('tapping "Create an account" navigates to the register route',
      (WidgetTester tester) async {
    await tester.pumpWidget(hostedLoginScreen());

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Register screen'), findsOneWidget);
  });
}
