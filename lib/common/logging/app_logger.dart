import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  static AppLogger? _instance;
  late final Logger _logger;

  // Singleton pattern
  AppLogger._internal() {
    _logger = Logger(
      filter: ProductionFilter(),
      printer: PrettyPrinter(methodCount: 2, errorMethodCount: 8, lineLength: 120, colors: true, printEmojis: true),
      output: ConsoleOutput(),
    );
  }

  static AppLogger get instance {
    _instance ??= AppLogger._internal();
    return _instance!;
  }

  // Convenience getters
  static Logger get logger => instance._logger;

  // Log methods
  static void trace(String message, {dynamic error, StackTrace? stackTrace}) {
    instance._logger.t(message, error: error, stackTrace: stackTrace);
  }

  static void debug(String message, {dynamic error, StackTrace? stackTrace}) {
    instance._logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(String message, {dynamic error, StackTrace? stackTrace}) {
    instance._logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    instance._logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    instance._logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void wtf(String message, {dynamic error, StackTrace? stackTrace}) {
    instance._logger.f(message, error: error, stackTrace: stackTrace);
  }

  // Development vs Production filter
  static void setLogLevel(Level level) {
    Logger.level = level;
  }

  // Initialize logger for the app
  static void initialize() {
    if (kDebugMode) {
      setLogLevel(Level.debug);
      info('AppLogger initialized in DEBUG mode');
    } else {
      setLogLevel(Level.warning);
      info('AppLogger initialized in PRODUCTION mode');
    }
  }
}

// Global logger instance for easy access
final logger = AppLogger.logger;
