import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../features/auth/services/auth_service.dart';
import '../core/notification_service.dart'; // Import

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final NotificationService _notificationService = NotificationService(); // Add

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;

  // Login Action
  Future<void> login(String email, String password) async {
    try {
      UserModel user = await _authService.login(email, password);
      _user = user;
      
      // Save Token Securely
      if (user.token != null) {
        await _storage.write(key: 'auth_token', value: user.token);
      }
      
      // Sync FCM Token
      _notificationService.init();
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Register Action
  Future<void> register(String name, String email, String password) async {
    try {
      // For now, registration just creates account. User still needs to login.
      await _authService.register(name, email, password);
    } catch (e) {
      rethrow;
    }
  }

  // Auto Login Action
  Future<bool> tryAutoLogin() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return false;

    try {
      final user = await _authService.getUserProfile(token);
      _user = user;
      
      // Sync FCM Token
      _notificationService.init();
      
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Logout Action
  Future<void> logout() async {
    _user = null;
    await _storage.delete(key: 'auth_token');
    notifyListeners();
  }
}
