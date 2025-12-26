import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/api_constants.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> init() async {
    // 1. Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      
      // 2. Get Token
      String? token = await _fcm.getToken();
      if (token != null) {
        print('FCM Token: $token');
        await _sendTokenToBackend(token);
      }
    }

    // 3. Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      _sendTokenToBackend(newToken);
    });

    // 4. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      if (message.notification != null) {
        print('Message Title: ${message.notification!.title}');
      }
    });
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final authToken = await _storage.read(key: 'auth_token');
      if (authToken == null) return;

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authEndpoint}/fcm-token');
      
      await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'bypass-tunnel-reminder': 'true',
        },
        body: jsonEncode({'fcmToken': token}),
      );
      print('FCM Token sent to backend');
    } catch (e) {
      print('Error sending FCM token: $e');
    }
  }
}
