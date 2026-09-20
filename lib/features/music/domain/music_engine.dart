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

  /// 当前曲目自然播放结束（非循环模式下）时触发。
  Stream<void> get onCompleted;

  /// 释放底层资源。
  void dispose();
}
