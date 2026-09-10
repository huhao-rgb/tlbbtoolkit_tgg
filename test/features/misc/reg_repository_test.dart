import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlbbtoolkit/core/storage/local_storage.dart';
import 'package:tlbbtoolkit/features/misc/data/reg_repository.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_account.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<RegRepository> repo() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return RegRepository(LocalStorage(prefs));
  }

  test('buildExportJson：生成原型兼容的 JSON 结构', () async {
    final r = await repo();
    final json = r.buildExportJson([
      RegAccount(id: 'a1', name: '逍遥生', lv: 89, sectKey: 'xiaoyao'),
    ]);
    expect(json, contains('"app": "天工阁"'));
    expect(json, contains('"type": "reg-accts"'));
    expect(json, contains('"ver": 1'));
    expect(json, contains('"exportedAt"'));
    expect(json, contains('"name": "逍遥生"'));
    expect(json, contains('"sect": "xiaoyao"'));
  });

  test('parseImportJson：兼容导出对象与纯数组，拒绝非法根', () async {
    final r = await repo();
    // 导出对象结构
    final fromObj = r.parseImportJson(
      '{"app":"天工阁","type":"reg-accts","accts":[{"name":"甲","sect":"wudang","lv":90}]}',
    );
    expect(fromObj, hasLength(1));
    expect(fromObj.first['name'], '甲');
    // 纯数组
    final fromArr = r.parseImportJson('[{"name":"乙","sect":"shaolin"}]');
    expect(fromArr, hasLength(1));
    // 非法根
    expect(() => r.parseImportJson('{"foo":1}'), throwsFormatException);
    expect(() => r.parseImportJson('not json'), throwsFormatException);
  });

  test('mergeImported：按「姓名+门派」判重，非法记录跳过，未知门派回退逍遥', () async {
    final r = await repo();
    final current = [RegAccount(id: 'a1', name: '已有号', lv: 89, sectKey: 'xiaoyao')];
    final res = r.mergeImported(
      [
        {'name': '已有号', 'sect': 'xiaoyao'}, // 重复 → 跳过
        {'name': '', 'sect': 'shaolin'}, // 空名 → 跳过
        {'name': '新号', 'sect': 'not-a-sect', 'lv': 30}, // 未知门派回退逍遥，lv 钳制
        {'name': '新号2', 'sect': 'tianlong', 'lv': 200, 'cur': 123, 'runs': [
          {'s': 1, 'e': 2},
          {'s': 'bad'}, // 非法 run → 过滤
        ]},
      ],
      current: current,
    );
    expect(res.added, 2);
    expect(res.skipped, 2);
    expect(res.merged, hasLength(3));
    final n1 = res.merged.firstWhere((a) => a.name == '新号');
    expect(n1.sectKey, 'xiaoyao'); // 回退
    expect(n1.lv, 30); // clamp 10..119 内
    final n2 = res.merged.firstWhere((a) => a.name == '新号2');
    expect(n2.sectKey, 'tianlong');
    expect(n2.lv, 119); // 200 → 119
    expect(n2.curMs, 123);
    expect(n2.runs, hasLength(1));
  });
}
