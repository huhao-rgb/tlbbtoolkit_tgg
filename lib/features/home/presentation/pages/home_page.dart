import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_async_view.dart';
import '../../../settings/settings_routes.dart';
import '../../domain/entities/home_item.dart';
import '../providers/home_providers.dart';
import '../widgets/home_item_card.dart';

/// 首页。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(homeItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('工具箱'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设置',
            onPressed: () => const SettingsRoute().push(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(homeItemsProvider.future),
        child: AppAsyncView<List<HomeItem>>(
          value: items,
          onRetry: () => ref.read(homeItemsProvider.notifier).retry(),
          dataBuilder: (context, data) {
            if (data.isEmpty) {
              return const _EmptyView();
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => HomeItemCard(item: data[index]),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('暂无数据'));
  }
}
