import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class LogService {
  LogService._();

  static final LogService _instance = LogService._();

  factory LogService() => _instance;

  static final Logger _logger = Logger(
    level: kDebugMode ? Level.debug : Level.warning,
    printer: kDebugMode ? PrettyPrinter() : SimplePrinter(),
  );

  void debug(String message, {String? tag}) {
    _logger.d('[$tag] $message');
  }

  void info(String message, {String? tag}) {
    _logger.i('[$tag] $message');
  }

  void warn(String message, {String? tag}) {
    _logger.w('[$tag] $message');
  }

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _logger.e('[$tag] $message', error: error, stackTrace: stackTrace);
  }
}
