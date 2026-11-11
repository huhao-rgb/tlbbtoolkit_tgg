import 'package:flutter/foundation.dart';

import 'package:tlbbtoolkit/core/utils/error_log.dart';

/// 安装全局错误处理器：让 release 包里的未捕获异常至少进入 [ErrorLog]。
///
/// 覆盖两条通道：
/// - [FlutterError.onError]：框架内（build / layout / paint）同步异常；
/// - [PlatformDispatcher.onError]：引擎 / 插件抛到根 zone 的异步异常。
///
/// 同步 zone 异常由 `main()` 里的 `runZonedGuarded` 兜底（见 `lib/main.dart`）。
/// 这里**不上报网络**，与隐私政策「不集成统计/崩溃 SDK」保持一致。
void installGlobalErrorHandlers(ErrorLog log) {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    // 保留默认输出，方便 debug 时仍能看到红屏信息。
    previous?.call(details);
    log.record(details.exception, details.stack, context: 'flutter');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    log.record(error, stack, context: 'platform');
    // true = 已处理，避免系统再次把异常抛给默认处理器（release 下会直接终止）。
    return true;
  };
}
