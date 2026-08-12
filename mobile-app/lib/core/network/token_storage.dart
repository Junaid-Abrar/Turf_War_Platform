import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Single owner of the persisted auth token.
///
/// Before Phase 4 every provider and service constructed its own
/// `FlutterSecureStorage` and re-read `'auth_token'` by string key. Centralising
/// it here means the key is written once and the token can be cached in memory,
/// so the auth interceptor does not hit the platform keystore on every request.
class TokenStorage {
  static const String _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage;
  String? _cached;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Token held in memory, if it has been read or written this session.
  String? get cachedToken => _cached;

  Future<String?> read() async {
    _cached ??= await _storage.read(key: _tokenKey);
    return _cached;
  }

  Future<void> write(String token) async {
    _cached = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: _tokenKey);
  }
}
