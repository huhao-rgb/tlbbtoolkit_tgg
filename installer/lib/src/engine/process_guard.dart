import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;
import 'package:win32/win32.dart';

/// 检测 / 关闭正在运行的目标程序，避免安装或卸载时文件被占用。
abstract class ProcessGuard {
  Future<List<int>> findRunning(String exeName);

  Future<bool> closeAll(String exeName);

  Future<bool> isRunning(String exeName) async =>
      (await findRunning(exeName)).isNotEmpty;
}

class NoopProcessGuard implements ProcessGuard {
  const NoopProcessGuard();

  @override
  Future<List<int>> findRunning(String exeName) async => const [];

  @override
  Future<bool> closeAll(String exeName) async => true;

  @override
  Future<bool> isRunning(String exeName) async => false;
}

ProcessGuard createProcessGuard() {
  if (Platform.isWindows) return const WindowsProcessGuard();
  return const PosixProcessGuard();
}

/// Windows：Toolhelp32 快照枚举进程，OpenProcess + TerminateProcess 关闭。
class WindowsProcessGuard implements ProcessGuard {
  const WindowsProcessGuard();

  @override
  Future<List<int>> findRunning(String exeName) async {
    final target = p.basename(exeName).toLowerCase();
    final pids = <int>[];
    final snapshot = _toolhelp.createSnapshot(
      0x00000002,
      0,
    ); // TH32CS_SNAPPROCESS
    if (snapshot == -1) return pids;

    final entry = calloc<_ProcessEntry32W>();
    try {
      entry.ref.dwSize = sizeOf<_ProcessEntry32W>();
      var ok = _toolhelp.processFirst(snapshot, entry);
      while (ok != 0) {
        final name = _readExeName(entry.ref);
        if (name.toLowerCase() == target) {
          pids.add(entry.ref.th32ProcessID);
        }
        ok = _toolhelp.processNext(snapshot, entry);
      }
    } finally {
      free(entry);
      CloseHandle(HANDLE(Pointer<Void>.fromAddress(snapshot)));
    }
    return pids;
  }

  @override
  Future<bool> closeAll(String exeName) async {
    var closed = 0;
    for (final processId in await findRunning(exeName)) {
      if (processId == pid) continue;
      final opened = OpenProcess(PROCESS_TERMINATE, false, processId);
      final handle = opened.value;
      if (handle.address == 0) continue;
      try {
        if (TerminateProcess(handle, 1).value) closed++;
      } finally {
        CloseHandle(handle);
      }
    }
    // 给系统一点时间释放文件句柄。
    if (closed > 0) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    return closed > 0;
  }

  @override
  Future<bool> isRunning(String exeName) async =>
      (await findRunning(exeName)).isNotEmpty;

  String _readExeName(_ProcessEntry32W entry) {
    final units = <int>[];
    for (var i = 0; i < 260; i++) {
      final unit = entry.szExeFile[i];
      if (unit == 0) break;
      units.add(unit);
    }
    return String.fromCharCodes(units);
  }
}

/// macOS / Linux 预览用：按进程名匹配，SIGTERM 关闭。
class PosixProcessGuard implements ProcessGuard {
  const PosixProcessGuard();

  @override
  Future<List<int>> findRunning(String exeName) async {
    final name = p.basenameWithoutExtension(exeName);
    final result = await Process.run('pgrep', ['-x', name]);
    if (result.exitCode != 0) return const [];
    return const LineSplitter()
        .convert(result.stdout as String)
        .map(int.tryParse)
        .whereType<int>()
        .toList();
  }

  @override
  Future<bool> closeAll(String exeName) async {
    final pids = await findRunning(exeName);
    for (final processId in pids) {
      if (processId != pid) Process.killPid(processId, ProcessSignal.sigterm);
    }
    if (pids.isNotEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    return pids.isNotEmpty;
  }

  @override
  Future<bool> isRunning(String exeName) async =>
      (await findRunning(exeName)).isNotEmpty;
}

// ---------------------------------------------------------------------------
// win32 包没有导出 Toolhelp32，这里直接绑定，避免用 tasklist 弹控制台窗口。
// ---------------------------------------------------------------------------

final class _ProcessEntry32W extends Struct {
  @Uint32()
  external int dwSize;

  @Uint32()
  external int cntUsage;

  @Uint32()
  external int th32ProcessID;

  @IntPtr()
  external int th32DefaultHeapID;

  @Uint32()
  external int th32ModuleID;

  @Uint32()
  external int cntThreads;

  @Uint32()
  external int th32ParentProcessID;

  @Int32()
  external int pcPriClassBase;

  @Uint32()
  external int dwFlags;

  @Array(260)
  external Array<Uint16> szExeFile;
}

typedef _CreateSnapshotNative = IntPtr Function(Uint32, Uint32);
typedef _CreateSnapshotDart = int Function(int, int);
typedef _Process32Native = Int32 Function(IntPtr, Pointer<_ProcessEntry32W>);
typedef _Process32Dart = int Function(int, Pointer<_ProcessEntry32W>);

final class _Toolhelp32 {
  _Toolhelp32() : _lib = DynamicLibrary.open('kernel32.dll');

  final DynamicLibrary _lib;

  late final _CreateSnapshotDart createSnapshot = _lib
      .lookupFunction<_CreateSnapshotNative, _CreateSnapshotDart>(
        'CreateToolhelp32Snapshot',
      );

  late final _Process32Dart processFirst = _lib
      .lookupFunction<_Process32Native, _Process32Dart>('Process32FirstW');

  late final _Process32Dart processNext = _lib
      .lookupFunction<_Process32Native, _Process32Dart>('Process32NextW');
}

_Toolhelp32? _toolhelpCache;
_Toolhelp32 get _toolhelp => _toolhelpCache ??= _Toolhelp32();
