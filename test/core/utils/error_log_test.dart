import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlbbtoolkit/core/utils/error_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> makePrefs([
    Map<String, Object> initial = const {},
  ]) {
    SharedPreferences.setMockInitialValues(initial);
    return SharedPreferences.getInstance();
  }

  group('ErrorLog', () {
    test('记录后按新→旧导出，并异步落盘到本地', () async {
      final prefs = await makePrefs();
      final log = ErrorLog();
      await log.attach(prefs);

      log.record(StateError('boom'), StackTrace.current, context: 'flutter');
      log.record(ArgumentError('bad'), null, context: 'zone');
      // 落盘是 unawaited 的，让出一次事件循环即可完成。
      await Future<void>.delayed(Duration.zero);

      final text = log.exportText();
      expect(text, contains('boom'));
      expect(text, contains('bad'));
      expect(text, contains('(zone)'));
      expect(log.entries.first.error, contains('bad'), reason: '新的在前');

      final raw = prefs.getString(ErrorLog.storageKey);
      expect(raw, isNotNull);
      expect(raw, contains('boom'));

      // 重新 attach 应恢复历史记录。
      final restored = ErrorLog();
      await restored.attach(prefs);
      expect(restored.entries, hasLength(2));
      expect(restored.exportText(), contains('boom'));
    });

    test('超过上限时丢弃最旧记录', () async {
      final log = ErrorLog(maxEntries: 3);
      for (var i = 0; i < 5; i++) {
        log.record('e$i', null);
      }
      expect(log.entries, hasLength(3));
      expect(log.entries.map((e) => e.error), ['e4', 'e3', 'e2']);
    });

    test('历史日志损坏时忽略而不是抛异常', () async {
      final prefs = await makePrefs({ErrorLog.storageKey: '{not-json'});
      final log = ErrorLog();
      await log.attach(prefs);
      expect(log.isEmpty, isTrue);
    });

    test('历史日志里结构不符的条目被跳过', () async {
      final prefs = await makePrefs({
        ErrorLog.storageKey:
            '[{"at":"2026-01-01T00:00:00.000","err":"ok"},'
            '{"at":"bad"},42]',
      });
      final log = ErrorLog();
      await log.attach(prefs);
      expect(log.entries, hasLength(1));
      expect(log.entries.single.error, 'ok');
    });

    test('clear 同时清空内存与本地存储', () async {
      final prefs = await makePrefs();
      final log = ErrorLog();
      await log.attach(prefs);
      log.record('boom', null);
      await Future<void>.delayed(Duration.zero);
      expect(prefs.getString(ErrorLog.storageKey), isNotNull);

      await log.clear();
      expect(log.isEmpty, isTrue);
      expect(prefs.getString(ErrorLog.storageKey), isNull);
    });

    test('超长错误与堆栈被截断，避免单条撑爆存储', () async {
      final log = ErrorLog(maxErrorLength: 10, maxStackLength: 5);
      log.record('x' * 100, StackTrace.fromString('y' * 100));
      final entry = log.entries.single;
      expect(entry.error.length, lessThan(30));
      expect(entry.stack!.length, lessThan(30));
      expect(entry.error, contains('已截断'));
    });
  });
}
