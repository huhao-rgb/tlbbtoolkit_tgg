import 'package:flutter_test/flutter_test.dart';

import 'package:tlbbtoolkit/features/job/domain/job_wudao.dart';

/// 校验武道树数据的自洽性：`rows` 必须刚好铺满该重的节点，`edges` 必须指向
/// 存在的节点且只从上一行连到下一行（否则弹窗里会画出悬空线或错位节点）。
void main() {
  group('武道树排布不变式', () {
    for (final entry in kWudao.entries) {
      for (final school in entry.value) {
        final label = '${entry.key} · ${school.name}';
        test('$label：rows / edges 与节点数一致', () {
          for (var li = 0; li < school.layers.length; li++) {
            final layer = school.layers[li];
            final rows = layer.rows;
            if (rows == null) continue;
            expect(
              rows.fold<int>(0, (a, b) => a + b),
              layer.nodes.length,
              reason: '第 ${li + 1} 重 rows 之和应等于节点数',
            );
            for (final edge in layer.edges ?? const <List<int>>[]) {
              expect(edge.length, 2);
              expect(edge[0], inInclusiveRange(0, layer.nodes.length - 1));
              expect(edge[1], inInclusiveRange(0, layer.nodes.length - 1));
              expect(edge[0], lessThan(edge[1]), reason: '连线只能从上往下');
            }
          }
        });
      }
    }

    test('慕容两个流派都收录了 2/3/2/3 的界面排布', () {
      final schools = kWudao['murong'];
      expect(schools, isNotNull);
      for (final school in schools!) {
        expect(school.layers.length, 4);
        for (final layer in school.layers) {
          expect(layer.rows, [2, 3, 2, 3]);
          expect(layer.nodes.length, 10);
        }
      }
      // 只有一重真正画了多条连线，其余较少（与截图一致）
      expect(schools[0].layers[0].edges, hasLength(4));
      expect(schools[1].layers[0].edges, hasLength(6));
      expect(schools[0].layers[3].edges, isNull);
    });
  });
}
