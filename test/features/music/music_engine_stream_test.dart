import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/music/data/audio/audioplayers_music_engine.dart';

void main() {
  group('ignoreStreamErrors', () {
    test('错误被丢弃：订阅方不写 onError 也不会炸，事件继续送达', () async {
      final source = StreamController<int>.broadcast();
      final clean = ignoreStreamErrors(source.stream);
      final seen = <int>[];
      // 故意不写 onError：若错误漏过去，就会变成未捕获异常（本测试会失败）。
      clean.listen(seen.add);

      source.add(1);
      source.addError(StateError('音源加载失败'));
      source.add(2);
      await Future<void>.delayed(Duration.zero);

      expect(seen, [1, 2]);
      expect(source.hasListener, isTrue, reason: '出错后不应关闭订阅');

      await source.close();
    });

    test('普通事件原样透传', () async {
      final source = StreamController<String>.broadcast();
      final clean = ignoreStreamErrors(source.stream);
      final seen = <String>[];
      clean.listen(seen.add);

      source.add('a');
      await Future<void>.delayed(Duration.zero);

      expect(seen, ['a']);
      await source.close();
    });
  });
}
