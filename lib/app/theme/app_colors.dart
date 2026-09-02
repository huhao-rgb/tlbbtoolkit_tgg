import 'package:flutter/material.dart';

/// 应用配色。
///
/// 这里只定义少量语义化颜色，主题整体仍以
/// `ColorScheme.fromSeed` 生成，避免配色硬编码分散在各页面。
abstract final class AppColors {
  const AppColors._();

  /// 品牌主色（种子色）。
  static const Color primary = Color(0xFF3D5AFE);

  /// 深色模式种子色。
  static const Color primaryDark = Color(0xFF8FA3FF);

  /// 浅色模式页面背景。
  static const Color background = Color(0xFFF5F6FA);

  static const Color textPrimary = Color(0xFF1F2937);

  static const Color textSecondary = Color(0xFF6B7280);
}
