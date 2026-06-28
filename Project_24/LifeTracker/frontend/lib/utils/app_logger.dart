import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void debug(Object? message) {
    if (kDebugMode) {
      debugPrint(message?.toString());
    }
  }
}
