import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/network/api_exception.dart';
import 'package:mobile_app/core/services/notification_service.dart';
import 'package:mobile_app/features/auth/providers/user_provider.dart';
import 'package:mobile_app/features/auth/services/auth_service.dart';
import 'package:mobile_app/models/user_model.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/fake_token_storage.dart';

class MockAuthService extends Mock implements AuthService {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockAuthService authService;
  late FakeTokenStorage tokenStorage;
  late MockNotificationService notificationService;
  late UserProvider provider;

  const UserModel loggedInUser = UserModel(
    id: 'u1',
    name: 'Ana',
    email: 'ana@example.com',
    role: 'user',
    token: 'fresh-token',
  );

  setUp(() {
    authService = MockAuthService();
    tokenStorage = FakeTokenStorage();
    notificationService = MockNotificationService();
    // login/tryAutoLogin fire-and-forget this, so it must resolve or the
    // unawaited future dangles across tests.
    when(() => notificationService.init()).thenAnswer((_) async {});
    provider = UserProvider(
      authService: authService,
      tokenStorage: tokenStorage,
      notificationService: notificationService,
    );
  });

  group('login', () {
    test('success writes the token, sets authenticated and stores the user',
        () async {
      when(() => authService.login('ana@example.com', 'pw12345'))
          .thenAnswer((_) async => loggedInUser);

      final Future<void> future =
          provider.login('ana@example.com', 'pw12345');
      expect(provider.isLoading, isTrue);
      await future;

      expect(provider.isLoading, isFalse);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.user, loggedInUser);
      expect(tokenStorage.cachedToken, 'fresh-token');
    });

    test('a response with no token throws and leaves the session unauthenticated',
        () async {
      const UserModel noToken = UserModel(
        id: 'u1',
        name: 'Ana',
        email: 'ana@example.com',
        role: 'user',
      );
      when(() => authService.login(any(), any()))
          .thenAnswer((_) async => noToken);

      await expectLater(
        provider.login('ana@example.com', 'pw12345'),
        throwsA(isA<ApiException>()),
      );
      expect(provider.isLoading, isFalse);
      expect(provider.isAuthenticated, isFalse);
      expect(tokenStorage.cachedToken, isNull);
    });

    test('failure propagates the ApiException and clears isLoading', () async {
      when(() => authService.login(any(), any())).thenThrow(
        const ApiException('Invalid credentials',
            kind: ApiExceptionKind.badResponse),
      );

      await expectLater(
        provider.login('ana@example.com', 'wrong'),
        throwsA(
          isA<ApiException>().having(
              (ApiException e) => e.message, 'message', 'Invalid credentials'),
        ),
      );
      expect(provider.isLoading, isFalse);
      expect(provider.isAuthenticated, isFalse);
    });
  });

  group('register', () {
    test('toggles isLoading around a successful call', () async {
      when(() => authService.register('Ana', 'ana@example.com', 'pw12345'))
          .thenAnswer((_) async => loggedInUser);

      final Future<void> future =
          provider.register('Ana', 'ana@example.com', 'pw12345');
      expect(provider.isLoading, isTrue);
      await future;

      expect(provider.isLoading, isFalse);
      // Registering does not itself sign the user in.
      expect(provider.isAuthenticated, isFalse);
    });

    test('propagates failure and still clears isLoading', () async {
      when(() => authService.register(any(), any(), any())).thenThrow(
        const ApiException('Email already in use',
            kind: ApiExceptionKind.badResponse),
      );

      await expectLater(
        provider.register('Ana', 'ana@example.com', 'pw12345'),
        throwsA(isA<ApiException>()),
      );
      expect(provider.isLoading, isFalse);
    });
  });

  group('tryAutoLogin', () {
    test('no stored token resolves straight to unauthenticated', () async {
      await provider.tryAutoLogin();

      expect(provider.status, AuthStatus.unauthenticated);
      verifyNever(() => authService.getProfile(token: any(named: 'token')));
    });

    test('a valid stored token resolves to authenticated', () async {
      await tokenStorage.write('stored-token');
      when(() => authService.getProfile(token: 'stored-token'))
          .thenAnswer((_) async => loggedInUser);

      await provider.tryAutoLogin();

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.user, loggedInUser);
    });

    test('an expired/deleted-user token clears storage and sets unauthenticated',
        () async {
      await tokenStorage.write('stale-token');
      when(() => authService.getProfile(token: 'stale-token')).thenThrow(
        const ApiException('Not authorized', kind: ApiExceptionKind.badResponse),
      );

      await provider.tryAutoLogin();

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.user, isNull);
      expect(tokenStorage.cachedToken, isNull);
    });
  });

  group('logout', () {
    test('clears storage and resets to unauthenticated', () async {
      when(() => authService.login(any(), any()))
          .thenAnswer((_) async => loggedInUser);
      await provider.login('ana@example.com', 'pw12345');
      expect(provider.isAuthenticated, isTrue);

      await provider.logout();

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.user, isNull);
      expect(tokenStorage.cachedToken, isNull);
    });
  });
}
