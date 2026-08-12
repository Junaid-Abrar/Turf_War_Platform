import 'package:firebase_messaging/firebase_messaging.dart';

import '../../features/auth/services/auth_service.dart';
import '../config/app_config.dart';
import '../network/api_exception.dart';
import '../utils/logger.dart';

/// Registers the device with FCM and keeps the backend's copy of the token
/// current.
///
/// Previously this built its own HTTP request, re-read the auth token from
/// secure storage and logged via `print`. It now delegates to [AuthService], so
/// the bearer token comes from the shared interceptor.
class NotificationService {
  final AuthService _authService;
  final FirebaseMessaging _fcm;

  bool _initialised = false;

  NotificationService(this._authService, {FirebaseMessaging? messaging})
      : _fcm = messaging ?? FirebaseMessaging.instance;

  /// Safe to call more than once — login and auto-login both trigger it.
  Future<void> init() async {
    // Demo builds run on the web where FCM registration needs a VAPID key and a
    // service worker; skip rather than fail loudly in front of a visitor.
    if (AppConfig.demoMode) {
      AppLogger.info('Demo mode: skipping FCM registration');
      return;
    }
    if (_initialised) {
      await _syncToken();
      return;
    }
    _initialised = true;

    try {
      final NotificationSettings settings = await _fcm.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        AppLogger.info('Notification permission not granted');
        return;
      }

      await _syncToken();

      _fcm.onTokenRefresh.listen(_sendToken);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.info(
          'Foreground message: ${message.notification?.title ?? message.messageId}',
        );
      });
    } catch (e, s) {
      // Push is a nice-to-have; a failure here must never block sign-in.
      AppLogger.error('Notification setup failed', e, s);
    }
  }

  Future<void> _syncToken() async {
    final String? token = await _fcm.getToken();
    if (token != null) await _sendToken(token);
  }

  Future<void> _sendToken(String token) async {
    try {
      await _authService.updateFcmToken(token);
      AppLogger.debug('FCM token synced with backend');
    } on ApiException catch (e) {
      AppLogger.error('Could not sync FCM token: ${e.message}');
    }
  }
}
