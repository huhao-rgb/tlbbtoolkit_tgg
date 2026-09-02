import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_async_view.dart';
import '../../domain/entities/home_item.dart';
import '../providers/home_providers.dart';
import '../widgets/home_item_card.dart';

/// 首页（一级 tab 页面）。
///
/// 页面自身不包含 Scaffold/AppBar：
/// 顶部信息条与底部 tabbar 由 shell 框架（`AppShellNavigation`）统一提供。
/// 宽屏下列表自适应为多列网格（`LayoutBuilder`）。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(homeItemsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(homeItemsProvider.future),
      child: AppAsyncView<List<HomeItem>>(
        value: items,
        onRetry: () => ref.read(homeItemsProvider.notifier).retry(),
        dataBuilder: (context, data) {
          if (data.isEmpty) {
            return const _EmptyView();
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              // 按宽度自适应列数：每列约 420 宽，至少 1 列。
              final crossAxisCount =
                  (constraints.maxWidth / 420).floor().clamp(1, 3);
              if (crossAxisCount <= 1) {
                // 窄屏保持单列列表。
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: data.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      HomeItemCard(item: data[index]),
                );
              }
              // 宽屏用网格。
              return GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.6,
                ),
                itemCount: data.length,
                itemBuilder: (context, index) =>
                    HomeItemCard(item: data[index]),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Center(child: Text('暂无数据')),
      ],
    );
  }
}
