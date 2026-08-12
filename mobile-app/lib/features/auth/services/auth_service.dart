import '../../../core/network/api_client.dart';
import '../../../models/user_model.dart';

/// Auth endpoints. Header construction, token injection, JSON decoding and
/// error translation all live in [ApiClient]; this class only knows the paths
/// and the response shapes.
class AuthService {
  final ApiClient _api;

  const AuthService(this._api);

  Future<UserModel> register(
    String name,
    String email,
    String password,
  ) async {
    final Map<String, dynamic> body = await _api.post(
      '/auth/register',
      body: <String, dynamic>{
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'role': 'user',
      },
    );
    return UserModel.fromJson(unwrapObject(body));
  }

  Future<UserModel> login(String email, String password) async {
    final Map<String, dynamic> body = await _api.post(
      '/auth/login',
      body: <String, dynamic>{'email': email.trim(), 'password': password},
    );
    // Login is the one endpoint that puts the token beside `user` rather than
    // inside a `data` envelope.
    return UserModel.fromJson(
      body['user'] as Map<String, dynamic>? ?? <String, dynamic>{},
      token: body['token'] as String?,
    );
  }

  /// Fetches the current user using the token the interceptor attaches.
  Future<UserModel> getProfile({String? token}) async {
    final Map<String, dynamic> body = await _api.get('/auth/me');
    return UserModel.fromJson(unwrapObject(body), token: token);
  }

  Future<void> updateFcmToken(String fcmToken) async {
    await _api.put(
      '/auth/fcm-token',
      body: <String, dynamic>{'fcmToken': fcmToken},
    );
  }
}
