import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/user_model.dart';
import '../../../core/api_constants.dart';

class AuthService {
  final String _authUrl = '${ApiConstants.baseUrl}${ApiConstants.authEndpoint}';

  // Helper for headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'bypass-tunnel-reminder': 'true', // Bypasses LocalTunnel warning
  };

  // Register User
  Future<UserModel> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$_authUrl${ApiConstants.registerEndpoint}'),
      headers: _headers,
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'password': password.trim(),
        'role': 'user',
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return UserModel.fromJson(body['data']);
    } else {
      throw Exception(body['error'] ?? 'Registration failed');
    }
  }

  // Login User
  Future<UserModel> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_authUrl${ApiConstants.loginEndpoint}'),
      headers: _headers,
      body: jsonEncode({
        'email': email.trim(), // Trim whitespace
        'password': password.trim(), // Trim whitespace
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return UserModel.fromJson(body['user'], token: body['token']);
    } else {
      throw Exception(body['error'] ?? 'Login failed');
    }
  }
}
