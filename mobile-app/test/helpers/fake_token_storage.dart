import 'package:mobile_app/core/network/token_storage.dart';

/// In-memory stand-in for the platform keystore, which is unavailable in tests.
///
/// Shared by [api_client_test.dart] and the provider tests rather than
/// duplicated — [TokenStorage] itself has no test seam (it wraps
/// `FlutterSecureStorage` directly), so every suite that needs a token store
/// fakes the whole class via `implements`.
class FakeTokenStorage implements TokenStorage {
  String? _token;

  FakeTokenStorage([this._token]);

  @override
  String? get cachedToken => _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
