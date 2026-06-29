import 'package:flutter/foundation.dart';

class LoggerService {
  const LoggerService();
  void info(String message) { if (kDebugMode) debugPrint('INFO: $message'); }
  void warning(String message) { if (kDebugMode) debugPrint('WARN: $message'); }
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('ERROR: $message');
      if (error != null) debugPrint(error.toString());
      if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
    }
  }
}
