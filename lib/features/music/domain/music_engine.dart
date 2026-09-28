/// 音频播放引擎端口（实现见 data 层，当前基于 audioplayers）。
///
/// 只暴露播放器所需的最小能力，便于在测试中用假实现替换真实插件。
abstract interface class MusicEngine {
  /// 播放本地 [path]，按 [volume]（0..1）与 [loop]（单曲循环）起播。
  ///
  /// 文件不可读等失败情况以异常抛出，由调用方决定跳过/标记。
  Future<void> play(String path, {required double volume, required bool loop});

  /// 暂停当前播放（保留进度）。
  Future<void> pause();

  /// 继续播放已暂停的曲目。
  Future<void> resume();

  /// 停止播放并清空音源。
  Future<void> stop();

  /// 调整音量（0..1）。
  Future<void> setVolume(double volume);

  /// 切换单曲循环。
  Future<void> setLoop(bool loop);

  /// 跳转到 [position]（进度条拖动/点击）。
  Future<void> seek(Duration position);

  /// 当前播放位置变化（实现按帧上报，订阅方负责节流）。
  ///
  /// 契约：本流**不携带错误**，错误统一由 [onError] 给出。
  Stream<Duration> get onPositionChanged;

  /// 当前音源总时长可用或变化时触发（换曲、加载完成后各一次）。
  ///
  /// 契约：本流**不携带错误**，错误统一由 [onError] 给出。
  Stream<Duration> get onDurationChanged;

  /// 播放失败（音源无法加载 / 解码失败 / 无权读取）时触发。
  ///
  /// 必须单独暴露：macOS / iOS 后端在 `setSource` 失败时**不会**让 [play]
  /// 报错（插件只往事件流塞一个 error，方法通道照样返回成功），
  /// 因此无法靠 try/catch 感知起播失败。
  Stream<Object> get onError;

  /// 当前曲目自然播放结束（非循环模式下）时触发。
  ///
  /// 契约：本流**不携带错误**，错误统一由 [onError] 给出。
  Stream<void> get onCompleted;

  /// 释放底层资源。
  void dispose();
}
