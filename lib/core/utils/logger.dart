import 'package:flutter/foundation.dart';

/// 简易日志工具。
///
/// 默认仅在 debug 模式输出，release 构建自动静默。
/// 后续可平滑替换为 package:logger / 三方日志服务。
class Logger {
  const Logger._();

  static const Logger instance = Logger._();

  static bool get _enabled => kDebugMode;

  void debug(String tag, String message) {
    if (_enabled) {
      // ignore: avoid_print
      print('[$tag] $message');
    }
  }

  void info(String tag, String message) => debug(tag, message);

  void error(String tag, Object error, [StackTrace? stackTrace]) {
    if (_enabled) {
      // ignore: avoid_print
      print('[$tag][ERROR] $error');
      if (stackTrace != null) {
        // ignore: avoid_print
        print(stackTrace);
      }
    }
  }
}
