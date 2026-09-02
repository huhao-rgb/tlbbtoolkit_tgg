import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 统一的异步视图组件。
///
/// 根据 [AsyncValue] 的状态渲染 loading / error / data，
/// 避免每个页面重复编写状态分支。`skipLoadingOnRefresh` 保持默认，
/// 因此下拉刷新时不会闪回 loading 视图。
class AppAsyncView<T> extends StatelessWidget {
  const AppAsyncView({
    super.key,
    required this.value,
    required this.dataBuilder,
    this.errorBuilder,
    this.loadingBuilder,
    this.onRetry,
  });

  final AsyncValue<T> value;

  /// 数据就绪时的构建回调。
  final Widget Function(BuildContext context, T data) dataBuilder;

  /// 自定义错误视图，默认提供"错误信息 + 重试按钮"。
  final Widget Function(BuildContext context, Object error, StackTrace? stackTrace)?
      errorBuilder;

  /// 自定义 loading 视图，默认提供居中 [CircularProgressIndicator]。
  final Widget Function(BuildContext context)? loadingBuilder;

  /// 错误视图上的重试回调，为空时不显示重试按钮。
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (data) => dataBuilder(context, data),
      loading: () => loadingBuilder?.call(context) ?? const _LoadingView(),
      error: (error, stackTrace) => errorBuilder?.call(context, error, stackTrace) ??
          _ErrorView(message: '$error', onRetry: onRetry),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
