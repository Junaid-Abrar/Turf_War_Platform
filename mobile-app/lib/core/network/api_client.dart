import 'dart:io';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../utils/logger.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// The app's single HTTP entry point.
///
/// Every service goes through this class rather than building its own headers,
/// decoding its own JSON and throwing its own bare `Exception`. Three
/// interceptors handle what used to be copy-pasted into each service:
///
///  * **auth** — injects `Authorization: Bearer <token>` from [TokenStorage].
///  * **error** — maps `DioException` onto [ApiException], reading the backend's
///    `{ success: false, error: "..." }` envelope for the message.
///  * **401** — invokes [onUnauthorized] so the app can force a logout when a
///    token expires or the account is deleted, instead of every screen having to
///    detect that case itself.
class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Called once per 401 response. Wired to `UserProvider.logout` in `main.dart`.
  Future<void> Function()? onUnauthorized;

  ApiClient({
    required TokenStorage tokenStorage,
    Dio? dio,
    String? baseUrl,
  })  : _tokenStorage = tokenStorage,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
                connectTimeout: AppConfig.requestTimeout,
                receiveTimeout: AppConfig.requestTimeout,
                sendTimeout: AppConfig.requestTimeout,
                contentType: Headers.jsonContentType,
                // Let the error interceptor decide what a non-2xx means rather
                // than having Dio throw before we can read the error envelope.
                validateStatus: (status) => status != null && status < 400,
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  /// Exposed so tests can install a mock adapter.
  Dio get dio => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String? token = await _tokenStorage.read();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    AppLogger.debug('→ ${options.method} ${options.path}');
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final ApiException mapped = _mapError(error);
    AppLogger.error(
      '← ${error.requestOptions.method} ${error.requestOptions.path} '
      'failed (${mapped.statusCode ?? mapped.kind.name}): ${mapped.message}',
    );

    if (mapped.isUnauthorized && onUnauthorized != null) {
      await onUnauthorized!();
    }

    handler.reject(
      DioException(
        requestOptions: error.requestOptions,
        response: error.response,
        type: error.type,
        error: mapped,
      ),
    );
  }

  ApiException _mapError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          'The server took too long to respond. Please try again.',
          kind: ApiExceptionKind.timeout,
        );

      case DioExceptionType.cancel:
        return const ApiException(
          'Request cancelled.',
          kind: ApiExceptionKind.cancelled,
        );

      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return const ApiException(
            'Cannot reach the server. Check your connection.',
            kind: ApiExceptionKind.network,
          );
        }
        return ApiException(
          error.message ?? 'Something went wrong.',
          kind: ApiExceptionKind.unknown,
        );

      case DioExceptionType.badCertificate:
        return const ApiException(
          'The server certificate could not be verified.',
          kind: ApiExceptionKind.network,
        );

      case DioExceptionType.badResponse:
        final int? status = error.response?.statusCode;
        return ApiException(
          _messageFromBody(error.response?.data) ?? _defaultMessage(status),
          statusCode: status,
          kind: ApiExceptionKind.badResponse,
        );
    }
  }

  /// The backend answers every failure with `{ success: false, error: "..." }`
  /// (see `middleware/errorHandler.js`), but a proxy or crash can return HTML,
  /// so this tolerates anything that is not the expected shape.
  String? _messageFromBody(dynamic body) {
    if (body is Map) {
      final dynamic message = body['error'] ?? body['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return null;
  }

  String _defaultMessage(int? status) {
    if (status == null) return 'Something went wrong.';
    if (status == 401) return 'Your session has expired. Please log in again.';
    if (status == 403) return 'You do not have permission to do that.';
    if (status == 404) return 'Not found.';
    if (status >= 500) return 'Server error. Please try again shortly.';
    return 'Request failed ($status).';
  }

  // --- Verbs ------------------------------------------------------------
  //
  // Each returns the decoded JSON body as a Map. Callers pull `data` out of the
  // envelope themselves, since some endpoints (login) put fields at the top
  // level alongside `data`.

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: queryParameters));

  Future<Map<String, dynamic>> post(String path, {Object? body}) =>
      _send(() => _dio.post<dynamic>(path, data: body));

  Future<Map<String, dynamic>> put(String path, {Object? body}) =>
      _send(() => _dio.put<dynamic>(path, data: body));

  Future<Map<String, dynamic>> patch(String path, {Object? body}) =>
      _send(() => _dio.patch<dynamic>(path, data: body));

  Future<Map<String, dynamic>> delete(String path) =>
      _send(() => _dio.delete<dynamic>(path));

  /// Multipart upload, used for venue images.
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, dynamic> fields,
    required String fileField,
    required String filePath,
  }) async {
    final FormData formData = FormData.fromMap({
      ...fields,
      fileField: await MultipartFile.fromFile(filePath),
    });
    return _send(
      () => _dio.post<dynamic>(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      ),
    );
  }

  /// Runs a request and normalises both the success and failure paths, so no
  /// caller ever sees a `DioException`.
  Future<Map<String, dynamic>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final Response<dynamic> response = await request();
      final dynamic data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data == null || (data is String && data.isEmpty)) {
        return <String, dynamic>{};
      }
      throw const ApiException(
        'Unexpected response from server.',
        kind: ApiExceptionKind.unknown,
      );
    } on DioException catch (e) {
      // The error interceptor has already attached the translated exception.
      if (e.error is ApiException) throw e.error as ApiException;
      throw _mapError(e);
    }
  }
}

/// Pulls the `data` array out of a list envelope, tolerating a missing key.
List<dynamic> unwrapList(Map<String, dynamic> body) {
  final dynamic data = body['data'];
  return data is List ? data : const <dynamic>[];
}

/// Pulls the `data` object out of a single-resource envelope.
Map<String, dynamic> unwrapObject(Map<String, dynamic> body) {
  final dynamic data = body['data'];
  if (data is Map<String, dynamic>) return data;
  throw const ApiException(
    'Unexpected response from server.',
    kind: ApiExceptionKind.unknown,
  );
}
