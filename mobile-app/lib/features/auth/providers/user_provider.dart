import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/logger.dart';
import '../../../models/user_model.dart';
import '../services/auth_service.dart';

/// Where the app is in the sign-in lifecycle.
///
/// The router keys its redirect off this: [unknown] keeps the splash screen up
/// while the stored token is validated, so there is no flash of the login screen
/// for an already-signed-in user.
enum AuthStatus { unknown, authenticated, unauthenticated }

class UserProvider extends ChangeNotifier {
  final AuthService _authService;
  final TokenStorage _tokenStorage;
  final NotificationService _notificationService;

  UserProvider({
    required AuthService authService,
    required TokenStorage tokenStorage,
    required NotificationService notificationService,
  })  : _authService = authService,
        _tokenStorage = tokenStorage,
        _notificationService = notificationService;

  UserModel? _user;
  AuthStatus _status = AuthStatus.unknown;
  bool _isLoading = false;

  UserModel? get user => _user;
  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final UserModel user = await _authService.login(email, password);
      final String? token = user.token;
      if (token == null || token.isEmpty) {
        throw const ApiException(
          'Login succeeded but no session token was returned.',
          kind: ApiExceptionKind.unknown,
        );
      }

      await _tokenStorage.write(token);
      _user = user;
      _status = AuthStatus.authenticated;
      notifyListeners();

      // Fire-and-forget: push registration must not delay entering the app.
      unawaited(_notificationService.init());
    } finally {
      _setLoading(false);
    }
  }

  /// Creates the account. The backend does not return a token on register, so
  /// the user is sent back to the login screen afterwards.
  Future<void> register(String name, String email, String password) async {
    _setLoading(true);
    try {
      await _authService.register(name, email, password);
    } finally {
      _setLoading(false);
    }
  }

  /// Validates any stored token on app start.
  ///
  /// A token that is expired, or whose user has since been deleted, comes back
  /// as 401 — the ApiClient's unauthorized hook already clears it, and this
  /// simply resolves to [AuthStatus.unauthenticated].
  Future<void> tryAutoLogin() async {
    final String? token = await _tokenStorage.read();
    if (token == null || token.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      _user = await _authService.getProfile(token: token);
      _status = AuthStatus.authenticated;
      notifyListeners();
      unawaited(_notificationService.init());
    } on ApiException catch (e) {
      AppLogger.info('Auto-login failed: ${e.message}');
      await _tokenStorage.clear();
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Clears the session. Called both from the profile screen and automatically
  /// by [ApiClient] on any 401.
  Future<void> logout() async {
    await _tokenStorage.clear();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
