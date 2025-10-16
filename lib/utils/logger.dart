import 'dart:developer' as developer;

class Logger {
  static const String _tag = 'AlarmApp';
  
  static void debug(String message) {
    developer.log('🐛 $message', name: _tag, level: 500);
  }
  
  static void info(String message) {
    developer.log('ℹ️ $message', name: _tag, level: 800);
  }
  
  static void warning(String message) {
    developer.log('⚠️ $message', name: _tag, level: 900);
  }
  
  static void error(String message, [Object? error]) {
    developer.log('❌ $message', name: _tag, level: 1000, error: error);
  }
}