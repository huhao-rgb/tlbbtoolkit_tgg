import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;
import 'package:win32/win32.dart';

class DiskSpace {
  const DiskSpace({required this.available, required this.total});

  final int available;
  final int total;

  double get usedFraction => total <= 0 ? 0 : (total - available) / total;
}

/// 读取安装目录所在磁盘的可用空间；拿不到时返回 null（UI 显示 “—”）。
Future<DiskSpace?> readDiskSpace(String path) async {
  try {
    if (Platform.isWindows) return _readWindows(path);
    return await _readPosix(path);
  } on Object {
    return null;
  }
}

DiskSpace? _readWindows(String path) {
  final root = p.rootPrefix(p.absolute(path));
  final freePtr = calloc<Uint64>();
  final totalPtr = calloc<Uint64>();
  try {
    final result = using(
      (arena) =>
          GetDiskFreeSpaceEx(arena.pcwstr(root), freePtr, totalPtr, nullptr),
    );
    if (!result.value) return null;
    return DiskSpace(available: freePtr.value, total: totalPtr.value);
  } finally {
    free(freePtr);
    free(totalPtr);
  }
}

Future<DiskSpace?> _readPosix(String path) async {
  final dir = Directory(path).existsSync() ? path : p.dirname(path);
  final result = await Process.run('df', ['-k', '-P', dir]);
  if (result.exitCode != 0) return null;
  final lines = const LineSplitter().convert(result.stdout as String);
  if (lines.length < 2) return null;
  final columns = lines[1].split(RegExp(r'\s+'));
  if (columns.length < 4) return null;
  final total = int.tryParse(columns[1]);
  final available = int.tryParse(columns[3]);
  if (total == null || available == null) return null;
  return DiskSpace(available: available * 1024, total: total * 1024);
}
