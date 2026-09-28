import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/music/data/music_file_store.dart';

void main() {
  late Directory library;
  late Directory sourceDir;
  late LocalMusicFileStore store;

  setUp(() {
    library = Directory.systemTemp.createTempSync('music-library-');
    sourceDir = Directory.systemTemp.createTempSync('music-source-');
    store = LocalMusicFileStore(directory: () async => library);
  });

  tearDown(() {
    library.deleteSync(recursive: true);
    sourceDir.deleteSync(recursive: true);
  });

  /// 造一个源文件（模拟用户从「文档/音乐」里选的歌）。
  File makeSource(String name, {int bytes = 16}) {
    final file = File('${sourceDir.path}/$name');
    file.writeAsBytesSync(List<int>.filled(bytes, 7));
    return file;
  }

  test('把外部文件复制进应用目录，返回副本路径（原文件保持不动）', () async {
    final source = makeSource('燕燕何其多 - 微蓝乐队.mp3');

    final imported = await store.import(source.path);

    expect(imported, '${library.path}/燕燕何其多 - 微蓝乐队.mp3');
    expect(imported, isNot(source.path));
    expect(File(imported).readAsBytesSync(), source.readAsBytesSync());
    expect(source.existsSync(), isTrue);
  });

  test('目标目录不存在时自动创建', () async {
    final source = makeSource('a.mp3');

    final imported = await store.import(source.path);

    expect(library.existsSync(), isTrue);
    expect(File(imported).existsSync(), isTrue);
  });

  test('重复导入同一文件：复用副本，不重复占盘', () async {
    final source = makeSource('a.mp3');

    final first = await store.import(source.path);
    final second = await store.import(source.path);

    expect(second, first);
    expect(library.listSync(), hasLength(1));
  });

  test('同名不同内容：加序号，互不覆盖', () async {
    final first = makeSource('a.mp3', bytes: 16);
    final second = File('${sourceDir.path}/nested/a.mp3')
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.filled(32, 9));

    final importedFirst = await store.import(first.path);
    final importedSecond = await store.import(second.path);

    expect(importedFirst, '${library.path}/a.mp3');
    expect(importedSecond, '${library.path}/a (1).mp3');
    expect(library.listSync(), hasLength(2));
  });

  test('源文件已不在：原样返回路径（交给 unavailable 兜底）', () async {
    final missing = '${sourceDir.path}/gone.mp3';

    expect(await store.import(missing), missing);
    expect(library.listSync(), isEmpty, reason: '不该留下空壳副本');
  });

  test('目录解析失败不抛异常，回退原路径', () async {
    final source = makeSource('a.mp3');
    final broken = LocalMusicFileStore(
      directory: () async => throw const FileSystemException('no permission'),
    );

    expect(await broken.import(source.path), source.path);
  });

  group('remove：只回收应用目录内的副本', () {
    test('删副本文件', () async {
      final imported = await store.import(makeSource('a.mp3').path);

      expect(await store.remove(imported), isTrue);
      expect(File(imported).existsSync(), isFalse);
    });

    test('外部原文件绝不动', () async {
      final source = makeSource('a.mp3');

      expect(await store.remove(source.path), isFalse);
      expect(source.existsSync(), isTrue);
    });

    test('副本已不在 / 路径不存在时返回 false', () async {
      expect(await store.remove('${library.path}/gone.mp3'), isFalse);
    });

    test('目录解析失败不抛异常', () async {
      final broken = LocalMusicFileStore(
        directory: () async => throw const FileSystemException('no permission'),
      );

      expect(await broken.remove('${library.path}/a.mp3'), isFalse);
    });
  });
}
