import 'dart:developer' as developer;

/// Utility class untuk logging dalam aplikasi BLE
/// 
/// Menyediakan logging yang konsisten dengan level yang berbeda
/// dan formatting yang mudah dibaca untuk debugging BLE operations
class BLELogger {
  static const String _tag = 'ESP32_BLE';
  
  /// Log level untuk filtering
  static LogLevel _currentLevel = LogLevel.debug;
  
  /// Set log level minimum yang akan ditampilkan
  static void setLogLevel(LogLevel level) {
    _currentLevel = level;
  }
  
  /// Log debug message
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }
  
  /// Log info message
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }
  
  /// Log warning message
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }
  
  /// Log error message
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }
  
  /// Internal logging method
  static void _log(LogLevel level, String message, [Object? error, StackTrace? stackTrace]) {
    if (level.index < _currentLevel.index) return;
    
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);
    final formattedMessage = '[$timestamp] [$_tag] [$levelStr] $message';
    
    developer.log(
      formattedMessage,
      name: _tag,
      error: error,
      stackTrace: stackTrace,
      level: _getLevelValue(level),
    );
  }
  
  /// Convert LogLevel ke nilai integer untuk developer.log
  static int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}

/// Enum untuk log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
}