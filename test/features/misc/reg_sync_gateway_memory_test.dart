import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/misc/data/reg_sync_gateway_memory.dart';
import 'package:tlbbtoolkit/features/misc/domain/reg_sync_gateway.dart';

void main() {
  late RegSyncGatewayMemory gw;

  setUp(() => gw = RegSyncGatewayMemory());

  test('fetch：不存在的记录返回 null（不是异常）', () async {
    expect(await gw.fetch('nope'), isNull);
  });

  test('push：expectedRev 0 表示新建，rev 从 1 开始', () async {
    final rev = await gw.push(syncId: 's1', expectedRev: 0, blob: 'blob-1');
    expect(rev, 1);
    expect((await gw.fetch('s1'))!.blob, 'blob-1');

    // 记录已存在时再以 rev 0 新建 → 冲突（实际为 1）
    await expectLater(
      gw.push(syncId: 's1', expectedRev: 0, blob: 'blob-x'),
      throwsA(
        isA<RegSyncConflictException>()
            .having((e) => e.expectedRev, 'expectedRev', 0)
            .having((e) => e.actualRev, 'actualRev', 1),
      ),
    );
    expect((await gw.fetch('s1'))!.blob, 'blob-1'); // 冲突不改数据
  });

  test('push：rev 不匹配抛冲突并带出实际 rev', () async {
    await gw.push(syncId: 's1', expectedRev: 0, blob: 'a'); // rev 1
    await gw.push(syncId: 's1', expectedRev: 1, blob: 'b'); // rev 2

    await expectLater(
      gw.push(syncId: 's1', expectedRev: 1, blob: 'c'),
      throwsA(
        isA<RegSyncConflictException>()
            .having((e) => e.expectedRev, 'expectedRev', 1)
            .having((e) => e.actualRev, 'actualRev', 2),
      ),
    );

    // 对不存在的记录用非 0 rev 写入 → 同样冲突（实际 0）
    await expectLater(
      gw.push(syncId: 'ghost', expectedRev: 3, blob: 'x'),
      throwsA(
        isA<RegSyncConflictException>().having(
          (e) => e.actualRev,
          'actualRev',
          0,
        ),
      ),
    );
  });

  test('remove：删除后 fetch 返回 null；重复删除不报错', () async {
    await gw.push(syncId: 's1', expectedRev: 0, blob: 'a');
    await gw.remove('s1');
    expect(await gw.fetch('s1'), isNull);
    await gw.remove('s1'); // 幂等
    expect(gw.recordCount, 0);
  });

  test('offline：所有请求抛 RegSyncUnavailableException', () async {
    await gw.push(syncId: 's1', expectedRev: 0, blob: 'a');
    gw.offline = true;

    await expectLater(
      gw.fetch('s1'),
      throwsA(isA<RegSyncUnavailableException>()),
    );
    await expectLater(
      gw.push(syncId: 's1', expectedRev: 1, blob: 'b'),
      throwsA(isA<RegSyncUnavailableException>()),
    );
    await expectLater(
      gw.remove('s1'),
      throwsA(isA<RegSyncUnavailableException>()),
    );
  });
}
