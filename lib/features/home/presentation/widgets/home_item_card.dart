import 'package:flutter/material.dart';

import '../../domain/entities/home_item.dart';

/// 首页条目卡片。
class HomeItemCard extends StatelessWidget {
  const HomeItemCard({super.key, required this.item});

  final HomeItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            item.isFavorite ? Icons.star : Icons.widgets_outlined,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(item.title),
        subtitle: item.subtitle.isEmpty ? null : Text(item.subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: 跳转到对应工具详情页
        },
      ),
    );
  }
}
