import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlbbtoolkit/core/storage/local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LocalStorage> makeStorage([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    return LocalStorage(await SharedPreferences.getInstance());
  }

  group('getJson', () {
    test('键不存在时返回 null', () async {
      final storage = await makeStorage();
      expect(storage.getJson('missing'), isNull);
    });

    test('正常对象往返', () async {
      final storage = await makeStorage();
      await storage.setJson('k', {'a': 1, 'b': 'x'});
      expect(storage.getJson('k'), {'a': 1, 'b': 'x'});
    });

    test('非法 JSON 返回 null 而不是抛异常', () async {
      final storage = await makeStorage({'k': '{bad'});
      expect(storage.getJson('k'), isNull);
    });

    for (final raw in <String>[
      '[]',
      '["a"]',
      '"text"',
      '123',
      'true',
      'null',
    ]) {
      test('合法但非对象的 JSON（$raw）返回 null 而不是抛 TypeError', () async {
        final storage = await makeStorage({'k': raw});
        expect(storage.getJson('k'), isNull);
      });
    }
  });
}
