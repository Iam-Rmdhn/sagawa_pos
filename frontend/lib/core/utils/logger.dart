import 'package:flutter/material.dart';

class AppLogger {
  static const bool _isDebug = true;

  static void log(String message, {String tag = 'APP'}) {
    if (_isDebug) {
      debugPrint('[$tag] $message');
    }
  }

  static void error(String message, {String tag = 'ERROR', Object? error}) {
    if (_isDebug) {
      debugPrint('[$tag] $message');
      if (error != null) {
        debugPrint('Error details: $error');
      }
    }
  }

  static void info(String message, {String tag = 'INFO'}) {
    if (_isDebug) {
      debugPrint('[$tag] $message');
    }
  }

  static void warning(String message, {String tag = 'WARNING'}) {
    if (_isDebug) {
      debugPrint('[$tag] $message');
    }
  }
}
