import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../features/auth/services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Register Action
  Future<void> register(String name, String email, String password) async {
    try {
      // For now, registration just creates account. User still needs to login.
      // Or we can auto-login here if the API returned a token (which ours doesn't yet).
      await _authService.register(name, email, password);
    } catch (e) {
      rethrow;
    }
  }

  // Logout Action
  Future<void> logout() async {
    _user = null;
    await _storage.delete(key: 'auth_token');
    notifyListeners();
  }
}
