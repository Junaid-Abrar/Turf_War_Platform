/// A network failure that has already been translated into something a widget
/// can show to a user.
///
/// Services never throw raw `Exception('...')` or leak `DioException` upward:
/// [ApiClient] maps every failure mode onto one of these, so presentation code
/// has a single type to catch and a [message] that is safe to display.
class ApiException implements Exception {
  /// Human-readable message, taken from the backend's `{ success: false, error }`
  /// envelope when present, otherwise derived from the failure kind.
  final String message;

  /// HTTP status code, or null for failures that never reached the server
  /// (timeouts, DNS errors, cancellation).
  final int? statusCode;

  final ApiExceptionKind kind;

  const ApiException(this.message, {this.statusCode, required this.kind});

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;

  /// True when retrying the same request could plausibly succeed.
  bool get isRetryable =>
      kind == ApiExceptionKind.timeout ||
      kind == ApiExceptionKind.network ||
      (statusCode != null && statusCode! >= 500);

  @override
  String toString() => message;
}

enum ApiExceptionKind {
  /// Connect/receive/send timed out.
  timeout,

  /// No route to host, DNS failure, socket closed.
  network,

  /// Server responded with a non-2xx status.
  badResponse,

  /// Request was cancelled before completion.
  cancelled,

  /// Anything else, including a malformed response body.
  unknown,
}
