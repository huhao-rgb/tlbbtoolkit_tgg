import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../gen/assets.gen.dart';

/// 天工阁线性图标（设计稿 `svg_icons/` → `assets/icons/`，flutter_gen 生成）的渲染封装。
///
/// 按资产名（如 `calc`、`pct`…，对应文件名去掉 `.svg`）取 SVG 渲染；
/// 通过 colorFilter 按 `currentColor` 语义着色（与主题色一致）。
class TgIcon extends StatelessWidget {
  const TgIcon(this.name, {super.key, this.size = 20, this.color});

  /// SVG 资产名（文件名，如 `calc` / `chev-l`）。
  final String name;

  final double size;

  /// 着色；为空则用 SVG 自带色。
  final Color? color;

  /// 资产名 → flutter_gen 生成的路径。
  static final Map<String, String> _paths = {
    'book': Assets.icons.book,
    'calc': Assets.icons.calc,
    'chev-l': Assets.icons.chevL,
    'chev': Assets.icons.chev,
    'flame': Assets.icons.flame,
    'gem': Assets.icons.gem,
    'home': Assets.icons.home,
    'info': Assets.icons.info,
    'mark': Assets.icons.mark,
    'moon': Assets.icons.moon,
    'paw': Assets.icons.paw,
    'pct': Assets.icons.pct,
    'search': Assets.icons.search,
    'shield': Assets.icons.shield,
    'slider': Assets.icons.slider,
    'spark': Assets.icons.spark,
    'sun': Assets.icons.sun,
    'sword': Assets.icons.sword,
    'x': Assets.icons.x,
  };

  @override
  Widget build(BuildContext context) {
    final path = _paths[name];
    if (path == null) {
      // 找不到资产名时回退为占位（不应发生）。
      return Icon(Icons.circle, size: size, color: color);
    }
    return SvgPicture.asset(
      path,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
