import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlbbtoolkit/core/storage/local_storage.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_repository.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_account.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<RegRepository> repo([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    return RegRepository(LocalStorage(prefs));
  }

  /// 直接读取落盘的完整记录（含墓碑）。
  Future<Map<String, dynamic>> stored(RegRepository r) async {
    final prefs = await SharedPreferences.getInstance();
    return jsonDecode(prefs.getString(RegRepository.key)!)
        as Map<String, dynamic>;
  }

  test('buildExportJson：生成 v2 导出结构', () async {
    final r = await repo();
    final json = r.buildExportJson([
      RegAccount(id: 'a1', name: '逍遥生', lv: 89, sectKey: 'xiaoyao'),
    ]);
    expect(json, contains('"app": "天工阁"'));
    expect(json, contains('"type": "reg-accts"'));
    expect(json, contains('"ver": 2'));
    expect(json, contains('"exportedAt"'));
    expect(json, contains('"name": "逍遥生"'));
    expect(json, contains('"sect": "xiaoyao"'));
  });

  test('parseImportJson：兼容 accts / a / 纯数组，拒绝非法根', () async {
    final r = await repo();
    final fromObj = r.parseImportJson(
      '{"app":"天工阁","type":"reg-accts","ver":2,"accts":[{"name":"甲","sect":"wudang","lv":90}]}',
    );
    expect(fromObj, hasLength(1));
    expect(fromObj.first['name'], '甲');
    // 同步码 payload 结构
    expect(r.parseImportJson('{"v":2,"a":[{"name":"丙"}]}'), hasLength(1));
    // 纯数组
    expect(r.parseImportJson('[{"name":"乙","sect":"shaolin"}]'), hasLength(1));
    // 非法根
    expect(() => r.parseImportJson('{"foo":1}'), throwsFormatException);
    expect(() => r.parseImportJson('not json'), throwsFormatException);
  });

  test('newRegAccountId：32 位十六进制且不重复', () async {
    final ids = {for (var i = 0; i < 200; i++) newRegAccountId()};
    expect(ids, hasLength(200));
    for (final id in ids) {
      expect(id, matches(RegExp(r'^[0-9a-f]{32}$')));
    }
  });

  test('load：v1 数据自动迁移到 v2 并补 updatedAt', () async {
    final r = await repo({
      RegRepository.legacyKey: jsonEncode({
        'accts': [
          {
            'id': 'a1',
            'name': '甲',
            'lv': 89,
            'sect': 'wudang',
            'cur': 5,
            'runs': [
              {'s': 1, 'e': 2},
            ],
          },
        ],
        'sel': 'a1',
      }),
    });

    final loaded = r.load();
    expect(loaded.accts, hasLength(1));
    expect(loaded.accts.first.name, '甲');
    expect(loaded.accts.first.updatedAt, greaterThan(0));
    expect(loaded.sel, 'a1');

    // 迁移异步落盘 v2，且写成功后删除 v1。
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(RegRepository.legacyKey), isNull);
    final v2 =
        jsonDecode(prefs.getString(RegRepository.key)!) as Map<String, dynamic>;
    expect(v2['v'], 2);
    expect(v2['accts'], hasLength(1));
  });

  test('save：内容未变不刷新 updatedAt；变化才刷新', () async {
    // 注入时钟：updatedAt 是毫秒级，用真实时钟会因「两次 save 落在同一毫秒」而偶发失败。
    var clock = 1000;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final r = RegRepository(LocalStorage(prefs), clock: () => clock);

    await r.save([
      RegAccount(id: 'a1', name: '甲', lv: 89, sectKey: 'xiaoyao'),
    ], null);
    expect(r.load().accts.single.updatedAt, 1000);

    // 同样内容再存一次 → 时间戳不变（幂等，避免无意义漂移）
    clock = 2000;
    await r.save(r.load().accts, null);
    expect(r.load().accts.single.updatedAt, 1000);

    // 改了等级 → 刷新到当次时钟
    clock = 3000;
    await r.save([r.load().accts.single.copyWith(lv: 90)], null);
    expect(r.load().accts.single.updatedAt, 3000);
    expect(r.load().accts.single.lv, 90);
  });

  test('save：消失的账号转成墓碑，load 不再返回但落盘保留 d', () async {
    final r = await repo();
    await r.save([
      RegAccount(id: 'a1', name: '甲', lv: 89, sectKey: 'xiaoyao'),
    ], null);
    await r.save(const [], null);

    expect(r.load().accts, isEmpty);
    final raw = await stored(r);
    final accts = (raw['accts'] as List).cast<Map<String, dynamic>>();
    expect(accts, hasLength(1));
    expect(accts.single['id'], 'a1');
    expect(accts.single['d'], isA<int>());
  });

  test('buildSyncCode / parseSyncCode：往返一致，容忍折行 / 缺前缀 / 裸 JSON', () async {
    final r = await repo();
    final code = r.buildSyncCode([
      RegAccount(
        id: 'a1',
        name: '逍遥生',
        lv: 89,
        sectKey: 'xiaoyao',
        curMs: 123,
        runs: [RegRun(startMs: 1, endMs: 2)],
        updatedAt: 7,
      ),
    ]);
    expect(code.startsWith(RegRepository.syncCodePrefix), isTrue);

    final parsed = r.parseSyncCode(code);
    expect(parsed, hasLength(1));
    expect(parsed.first['name'], '逍遥生');
    expect(parsed.first['u'], 7);
    expect(parsed.first['runs'], hasLength(1));

    // 聊天窗口折行（含空白）不影响解析
    final wrapped = code.replaceAllMapped(RegExp('.{20}'), (m) => '${m[0]}\n');
    expect(r.parseSyncCode(wrapped), hasLength(1));
    // 前缀被截掉也能解析
    expect(
      r.parseSyncCode(code.substring(RegRepository.syncCodePrefix.length)),
      hasLength(1),
    );
    // 直接粘贴 JSON 文本
    expect(r.parseSyncCode('[{"name":"乙"}]'), hasLength(1));
    // 非法输入
    expect(() => r.parseSyncCode('这不是同步码'), throwsFormatException);
    expect(() => r.parseSyncCode('   '), throwsFormatException);
  });

  test('importAccounts：判重、跳过非法、未知门派回退逍遥、等级钳制', () async {
    final r = await repo();
    await r.save([
      RegAccount(id: 'a1', name: '已有号', lv: 89, sectKey: 'xiaoyao'),
    ], null);

    final res = await r.importAccounts([
      {'name': '已有号', 'sect': 'xiaoyao'}, // 重复（姓名+门派）→ 跳过
      {'name': '', 'sect': 'shaolin'}, // 空名 → 跳过
      {'name': '新号', 'sect': 'not-a-sect', 'lv': 30}, // 未知门派回退逍遥
      {
        'name': '新号2',
        'sect': 'tianlong',
        'lv': 200,
        'cur': 123,
        'runs': [
          {'s': 1, 'e': 2},
          {'s': 'bad'}, // 非法 run → 过滤
        ],
      },
    ]);

    expect(res.added, 2);
    expect(res.updated, 0);
    expect(res.skipped, 2);
    expect(res.accts, hasLength(3));
    final n1 = res.accts.firstWhere((a) => a.name == '新号');
    expect(n1.sectKey, 'xiaoyao'); // 回退
    expect(n1.lv, 30);
    final n2 = res.accts.firstWhere((a) => a.name == '新号2');
    expect(n2.sectKey, 'tianlong');
    expect(n2.lv, 119); // 200 → 119
    expect(n2.curMs, 123);
    expect(n2.runs, hasLength(1));
    // 结果已落盘
    expect(r.load().accts, hasLength(3));
  });

  test('importAccounts：回归记录取并集、时间戳新者胜，且重复导入幂等', () async {
    final r = await repo();
    await r.save([
      RegAccount(
        id: 'a1',
        name: '甲',
        lv: 89,
        sectKey: 'xiaoyao',
        runs: [RegRun(startMs: 100, endMs: 200)],
      ),
    ], null);

    final raw = [
      {
        'id': 'a1',
        'name': '甲',
        'sect': 'xiaoyao',
        'cur': 555,
        'u': 99999999999999, // 时间戳远大于本机 → 外部胜
        'runs': [
          {'s': 100, 'e': 250}, // 同一轮（同起点）取较大 endMs
          {'s': 300, 'e': 400}, // 外部独有的另一轮 → 并入
        ],
      },
    ];

    final res = await r.importAccounts(raw);
    expect(res.added, 0);
    expect(res.updated, 1);
    final a = res.accts.single;
    expect(a.curMs, 555);
    expect(a.runs, [
      RegRun(startMs: 100, endMs: 250),
      RegRun(startMs: 300, endMs: 400),
    ]);

    // 再导入同一份数据 → 无变更（幂等）
    final again = await r.importAccounts(raw);
    expect(again.updated, 0);
    expect(again.added, 0);
    expect(again.skipped, 1);
  });

  test('importAccounts：已删除账号不会被外部旧数据复活，时间更新才复活', () async {
    final r = await repo();
    await r.save([
      RegAccount(id: 'a1', name: '甲', lv: 89, sectKey: 'xiaoyao'),
    ], null);
    await r.save(const [], null); // 删除 → 墓碑
    expect(r.load().accts, isEmpty);

    // 外部是更旧（u=1）的副本 → 墓碑胜出，不复活
    final old = await r.importAccounts([
      {'id': 'a1', 'name': '甲', 'sect': 'xiaoyao', 'u': 1},
    ]);
    expect(old.accts, isEmpty);
    expect(old.added, 0);
    expect(old.skipped, 1);

    // 外部是明确更新的副本 → 复活
    final newer = await r.importAccounts([
      {'id': 'a1', 'name': '甲', 'sect': 'xiaoyao', 'u': 99999999999999},
    ]);
    expect(newer.accts, hasLength(1));
    expect(newer.updated, 1);
    expect(r.load().accts, hasLength(1));
  });
}
