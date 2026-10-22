import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

/// 把主程序 Release 目录打成 payload.zip，供安装器解压。
///
/// 用法（在 installer/ 下）：
///   fvm dart run tool/package_payload.dart \
///     --input ../build/windows/x64/runner/Release \
///     --output assets/payload/payload.zip
Future<void> main(List<String> args) async {
  final options = _parse(args);
  final input = Directory(
    p.absolute(options['input'] ?? '../build/windows/x64/runner/Release'),
  );
  final output = p.absolute(options['output'] ?? 'assets/payload/payload.zip');

  if (!input.existsSync()) {
    stderr.writeln('找不到主程序产物目录：${input.path}');
    exitCode = 1;
    return;
  }

  final target = File(output);
  target.parent.createSync(recursive: true);
  if (target.existsSync()) target.deleteSync();

  var lastReported = -10;
  final encoder = ZipFileEncoder();
  await encoder.zipDirectory(
    input,
    filename: output,
    // 内层不再压缩：外层 NSIS LZMA 会压缩整个目录，内层再 deflate 只会
    // 让安装时多一次解压。store(0) 让安装器只需按字节拷贝。
    level: ZipFileEncoder.store,
    onProgress: (percent) {
      final rounded = percent.round();
      if (rounded >= lastReported + 10) {
        lastReported = rounded;
        stdout.writeln('压缩中… $rounded%');
      }
    },
  );

  final size = target.lengthSync();
  stdout.writeln(
    'payload.zip 已生成：$output'
    '（${(size / 1024 / 1024).toStringAsFixed(1)} MB）',
  );
}

Map<String, String> _parse(List<String> args) {
  final result = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (!arg.startsWith('--')) continue;
    final eq = arg.indexOf('=');
    if (eq > 0) {
      result[arg.substring(2, eq)] = arg.substring(eq + 1);
    } else if (i + 1 < args.length) {
      result[arg.substring(2)] = args[++i];
    }
  }
  return result;
}
