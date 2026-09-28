import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'music_file_store.g.dart';

/// 应用支持目录下存放导入音频的子目录名。
const String _musicDirName = 'music';

/// 音频落盘端口：把用户选中的外部文件复制进应用自己的目录。
///
/// **为什么必须复制**：桌面/移动端沙盒对「用户选中文件」的授权只活在一次
/// 进程内，重启后原路径变成无权读取（macOS 表现为 AVPlayer
/// `Failed to set playerItem`，对应 `MusicPlayerState.unavailable`）。
/// 复制进应用目录后路径永久有效，重启照常播放。
abstract interface class MusicFileStore {
  /// 复制 [sourcePath]，返回**永久可读**的路径。
  ///
  /// 无法复制时（Web 的 blob URL、源文件已不在、IO/权限失败）
  /// 原样返回 [sourcePath]，由调用方按「仅本次会话可用」处理。
  Future<String> import(String sourcePath);

  /// 删除 [import] 落盘的副本（列表删曲目时回收磁盘）。
  ///
  /// **绝不碰用户的原始文件**：只有位于应用目录内的路径才会被删除，
  /// 外部路径（Web blob URL、复制失败时的回退路径）一律返回 false。
  Future<bool> remove(String path);
}

/// 基于 path_provider 的实现：落盘到 `<应用支持目录>/music/`。
class LocalMusicFileStore implements MusicFileStore {
  LocalMusicFileStore({Future<Directory> Function()? directory})
    : _resolveDirectory = directory ?? _applicationMusicDir;

  /// 目录解析可注入（测试给临时目录，真机给应用支持目录）。
  final Future<Directory> Function() _resolveDirectory;

  static Future<Directory> _applicationMusicDir() async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}/$_musicDirName');
  }

  @override
  Future<String> import(String sourcePath) async {
    // Web：file_selector 给的是 blob/object URL，没有可复制的文件。
    if (kIsWeb) return sourcePath;
    try {
      final source = File(sourcePath);
      if (!source.existsSync()) return sourcePath;
      final dir = await _resolveDirectory();
      if (!dir.existsSync()) await dir.create(recursive: true);

      final target = _targetFor(dir, source);
      // 已导入过（同名且大小一致）→ 直接复用，不重复占盘。
      if (!target.existsSync()) await source.copy(target.path);
      return target.path;
    } on Object {
      // 复制失败就退回原路径：至少本次会话还能播，
      // 重启后失效由 `MusicPlayerState.unavailable` 兜底提示。
      return sourcePath;
    }
  }

  @override
  Future<bool> remove(String path) async {
    if (kIsWeb) return false;
    try {
      final dir = await _resolveDirectory();
      final file = File(path);
      if (!_isInside(dir, file) || !file.existsSync()) return false;
      await file.delete();
      return true;
    } on Object {
      // 删不掉（占用中 / 无权限）不该影响列表，交给系统回收。
      return false;
    }
  }

  /// 选出目标文件。
  ///
  /// - 目标名不存在 → 用原名；
  /// - 已存在且大小与源一致 → 判定为同一份，复用该路径（去重）；
  /// - 已存在但大小不同 → 同名不同曲，加 ` (n)` 序号避免互相覆盖。
  File _targetFor(Directory dir, File source) {
    final name = _basename(source.path);
    var candidate = File('${dir.path}/$name');
    if (!candidate.existsSync() || _sameSize(candidate, source)) {
      return candidate;
    }
    final dot = name.lastIndexOf('.');
    final stem = dot > 0 ? name.substring(0, dot) : name;
    final extension = dot > 0 ? name.substring(dot) : '';
    for (var index = 1; ; index++) {
      candidate = File('${dir.path}/$stem ($index)$extension');
      if (!candidate.existsSync() || _sameSize(candidate, source)) {
        return candidate;
      }
    }
  }

  static bool _sameSize(File a, File b) {
    try {
      return a.lengthSync() == b.lengthSync();
    } on Object {
      return false;
    }
  }

  static String _basename(String path) => path.split(RegExp(r'[/\\]')).last;

  /// 路径是否位于应用音频目录内（比较前统一分隔符，兼容 Windows）。
  static bool _isInside(Directory dir, File file) {
    String normalize(String value) => value.replaceAll('\\', '/');
    final dirPath = normalize(dir.absolute.path);
    final filePath = normalize(file.absolute.path);
    return filePath.startsWith(dirPath.endsWith('/') ? dirPath : '$dirPath/');
  }
}

/// 音频落盘器的依赖注入。
@Riverpod(keepAlive: true)
MusicFileStore musicFileStore(Ref ref) => LocalMusicFileStore();
