import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/core/network/api_exception.dart';
import 'package:mobile_app/core/network/token_storage.dart';

/// In-memory stand-in for the platform keystore, which is unavailable in tests.
class _FakeTokenStorage implements TokenStorage {
  String? _token;

  _FakeTokenStorage([this._token]);

  @override
  String? get cachedToken => _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late _FakeTokenStorage storage;
  late ApiClient client;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test.local/api'));
    adapter = DioAdapter(dio: dio);
    storage = _FakeTokenStorage('stored-token');
    client = ApiClient(tokenStorage: storage, dio: dio);
  });

  group('auth interceptor', () {
    test('attaches the stored bearer token', () async {
      String? seenHeader;
      adapter.onGet(
        '/venues',
        (server) => server.reply(200, <String, dynamic>{
          'success': true,
          'data': <dynamic>[],
        }),
      );

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (RequestOptions options, RequestInterceptorHandler h) {
            seenHeader = options.headers['Authorization'] as String?;
            h.next(options);
          },
        ),
      );

      await client.get('/venues');
      expect(seenHeader, 'Bearer stored-token');
    });

    test('omits the header when no token is stored', () async {
      final _FakeTokenStorage empty = _FakeTokenStorage();
      final Dio bareDio = Dio(BaseOptions(baseUrl: 'http://test.local/api'));
      final DioAdapter bareAdapter = DioAdapter(dio: bareDio);
      final ApiClient bareClient =
          ApiClient(tokenStorage: empty, dio: bareDio);

      String? seenHeader = 'unset';
      bareAdapter.onGet(
        '/venues',
        (server) => server.reply(200, <String, dynamic>{
          'success': true,
          'data': <dynamic>[],
        }),
      );
      bareDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (RequestOptions options, RequestInterceptorHandler h) {
            seenHeader = options.headers['Authorization'] as String?;
            h.next(options);
          },
        ),
      );

      await bareClient.get('/venues');
      expect(seenHeader, isNull);
    });
  });

  group('error mapping', () {
    test('reads the backend error envelope', () async {
      adapter.onPost(
        '/bookings',
        (server) => server.reply(400, <String, dynamic>{
          'success': false,
          'error': 'Slot already booked',
        }),
        data: <String, dynamic>{'venueId': 'v1'},
      );

      expect(
        () => client.post('/bookings', body: <String, dynamic>{'venueId': 'v1'}),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.message, 'message',
                  'Slot already booked')
              .having((ApiException e) => e.statusCode, 'statusCode', 400)
              .having((ApiException e) => e.kind, 'kind',
                  ApiExceptionKind.badResponse),
        ),
      );
    });

    test('falls back to a status-based message when the body is not JSON',
        () async {
      adapter.onGet(
        '/venues',
        (server) => server.reply(502, '<html>Bad Gateway</html>'),
      );

      expect(
        () => client.get('/venues'),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.message, 'message',
                  contains('Server error'))
              .having((ApiException e) => e.isRetryable, 'isRetryable', true),
        ),
      );
    });

    test('maps a connection timeout', () async {
      adapter.onGet(
        '/venues',
        (server) => server.throws(
          0,
          DioException.connectionTimeout(
            timeout: const Duration(seconds: 1),
            requestOptions: RequestOptions(path: '/venues'),
          ),
        ),
      );

      expect(
        () => client.get('/venues'),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.kind, 'kind',
                  ApiExceptionKind.timeout)
              .having((ApiException e) => e.isRetryable, 'isRetryable', true),
        ),
      );
    });

    test('maps a socket failure to a network error', () async {
      adapter.onGet(
        '/venues',
        (server) => server.throws(
          0,
          DioException.connectionError(
            requestOptions: RequestOptions(path: '/venues'),
            reason: 'no route',
            error: const SocketException('failed'),
          ),
        ),
      );

      expect(
        () => client.get('/venues'),
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.kind,
            'kind',
            ApiExceptionKind.network,
          ),
        ),
      );
    });
  });

  group('401 handling', () {
    test('invokes onUnauthorized so the session can be cleared', () async {
      int logoutCalls = 0;
      client.onUnauthorized = () async {
        logoutCalls++;
        await storage.clear();
      };

      adapter.onGet(
        '/auth/me',
        (server) => server.reply(401, <String, dynamic>{
          'success': false,
          'error': 'Not authorized',
        }),
      );

      await expectLater(
        client.get('/auth/me'),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.isUnauthorized, 'isUnauthorized',
                  true),
        ),
      );

      expect(logoutCalls, 1);
      expect(storage.cachedToken, isNull);
    });
  });

  group('envelope helpers', () {
    test('unwrapList tolerates a missing data key', () {
      expect(unwrapList(<String, dynamic>{'success': true}), isEmpty);
      expect(
        unwrapList(<String, dynamic>{
          'data': <dynamic>[1, 2],
        }),
        hasLength(2),
      );
    });

    test('unwrapObject throws when data is not an object', () {
      expect(
        () => unwrapObject(<String, dynamic>{'data': 'nope'}),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
