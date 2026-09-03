import 'package:flutter/material.dart';

import '../../app/theme/design_tokens.dart';
import 'tg_icon.dart';

/// 通用自绘输入框（聚焦态：金描边 .55 + focusRing 光环）。
///
/// 供首页 hero 搜索框与表单数字输入等复用：
/// - 外层自绘 底/描边/光环，内层 TextField 清除主题装饰（避免“框中框”）；
/// - 用 Row 包裹使文字**垂直居中**（避免直接套在定高容器里文字上偏）；
/// - 可选前缀线性图标（如 'search'）。
class TgTextField extends StatefulWidget {
  const TgTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.height = 42,
    this.horizontalPadding = 13,
    this.background,
    this.radius,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  /// 前缀线性图标资源名（如 'search'）；为 null 不显示。
  final String? prefixIcon;

  /// 外框高度（含边框）。
  final double height;

  /// 左右内边距。
  final double horizontalPadding;

  /// 底色；默认表单 inset 底。
  final Color? background;

  /// 外框圆角；默认 `TgRadius.input`。
  final BorderRadius? radius;

  @override
  State<TgTextField> createState() => _TgTextFieldState();
}

class _TgTextFieldState extends State<TgTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Focus(
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: Container(
        height: widget.height,
        padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
        decoration: BoxDecoration(
          color: widget.background ?? tg.inset,
          borderRadius: widget.radius ?? TgRadius.input,
          border: Border.all(
            color: _focused ? tg.goldTint(.55) : tg.border,
            width: 1,
          ),
          boxShadow: _focused ? TgShadows.focusRing : null,
        ),
        child: Row(
          children: [
            if (widget.prefixIcon != null) ...[
              TgIcon(widget.prefixIcon!, size: 17, color: tg.t3),
              const SizedBox(width: 9),
            ],
            Expanded(
              child: TextField(
                controller: widget.controller,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                style: TgType.body14.copyWith(color: tg.t1),
                cursorColor: tg.gold,
                // 清除主题 inputDecorationTheme 默认（filled/边框/最小高/内距）
                decoration: InputDecoration(
                  isCollapsed: true,
                  isDense: true,
                  filled: false,
                  constraints: const BoxConstraints(),
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintText: widget.hintText,
                  hintStyle: TgType.body14.copyWith(color: tg.t3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
