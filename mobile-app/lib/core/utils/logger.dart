import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Minimal logging facade.
///
/// Production code must not call `print` (enforced by `analysis_options.yaml`):
/// it writes to stdout on every build mode and cannot be filtered. This routes
/// through `dart:developer`, which the DevTools logging view understands, and
/// silences everything below [error] in release builds.
class AppLogger {
  const AppLogger._();

  static const String _name = 'turfwar';

  static void debug(String message) {
    if (kReleaseMode) return;
    developer.log(message, name: _name, level: 500);
  }

  static void info(String message) {
    if (kReleaseMode) return;
    developer.log(message, name: _name, level: 800);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
