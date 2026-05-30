import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warn, error }

class AppLogger {
  const AppLogger._();

  static void log(LogLevel level, String source, String message,
      [Object? error, StackTrace? stack]) {
    final prefix = level.name.toUpperCase();
    final errorPart = error != null ? ' | $error' : '';
    final stackPart = stack != null ? '\n${stack.toString().split('\n').take(8).join('\n')}' : '';
    final line = '[$prefix] $source: $message$errorPart$stackPart';

    if (kDebugMode) {
      switch (level) {
        case LogLevel.error:
          developer.log(line, name: source, level: 1000, error: error, stackTrace: stack);
          break;
        case LogLevel.warn:
          developer.log(line, name: source, level: 900);
          break;
        default:
          developer.log(line, name: source);
      }
    }
    // TODO: forward to Sentry/Crashlytics in release mode
  }

  static void debug(String source, String message) =>
      log(LogLevel.debug, source, message);
  static void info(String source, String message) =>
      log(LogLevel.info, source, message);
  static void warn(String source, String message, [Object? error]) =>
      log(LogLevel.warn, source, message, error);
  static void error(String source, String message,
          [Object? error, StackTrace? stack]) =>
      log(LogLevel.error, source, message, error, stack);
}
