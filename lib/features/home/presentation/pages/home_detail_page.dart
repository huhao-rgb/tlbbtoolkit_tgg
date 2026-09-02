import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/responsive/breakpoints.dart';
import '../providers/home_providers.dart';

/// 首页条目的二级详情页。
///
/// 由 shell 框架的公共信息条展示标题与返回按钮，
/// 本页只负责内容区（不包含 AppBar）。
class HomeDetailPage extends ConsumerWidget {
  const HomeDetailPage({super.key, required this.id});

  /// 条目 id（来自路由 `detail/:id`）。
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 从首页数据中查找对应条目。
    final items = ref.watch(homeItemsProvider);
    final item = items.value?.where((e) => '${e.id}' == id).firstOrNull;

    return DesktopContentConstraint(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: item == null
            ? const Center(child: Text('未找到该工具'))
            : Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            item.isFavorite
                                ? Icons.star
                                : Icons.widgets_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Text(
                        '这是「${item.title}」的详情页。\n'
                        '当前处于二级页面，信息条左上角会出现返回按钮。',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
