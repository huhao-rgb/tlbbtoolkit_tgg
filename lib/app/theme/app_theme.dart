import 'package:flutter/material.dart';
import 'package:tlbbtoolkit/app/theme/design_tokens.dart';
import 'package:tlbbtoolkit/app/theme/tg_fade_slide_transitions.dart';

/// 天工阁 ThemeData 构建（深 / 浅）
///
/// 用法：
/// ```dart
/// MaterialApp(
///   theme: TgTheme.light,
///   darkTheme: TgTheme.dark,
///   themeMode: ThemeMode.dark, // 深色为基准主题
/// )
/// ```
///
/// 全量设计令牌请通过 ThemeExtension 读取：
/// ```dart
/// final c = context.tg;           // TgColors
/// Container(color: c.card, ...);
/// ```
abstract final class TgTheme {
  /// 深色（基准主题）
  static ThemeData get dark => _build(TgColors.dark);

  /// 浅色（暖纸面变体）
  static ThemeData get light => _build(TgColors.light);

  static ThemeData _build(TgColors c) {
    final isDark = c.brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: c.brightness,
      // 品牌金 = primary；金底上的墨色 = onPrimary
      primary: c.gold,
      onPrimary: TgTokens.btnInk,
      primaryContainer: c.goldTint(.14),
      onPrimaryContainer: c.gold2,
      secondary: c.goldDp,
      onSecondary: TgTokens.btnInk,
      secondaryContainer: c.card2,
      onSecondaryContainer: c.t1,
      tertiary: c.blue,
      onTertiary: isDark ? const Color(0xFF0A1428) : Colors.white,
      tertiaryContainer: c.tintOf(c.blue, .14),
      onTertiaryContainer: c.tagBlue,
      error: c.red,
      onError: c.onErrorC,
      errorContainer: c.tintOf(c.red, .14),
      onErrorContainer: c.tagRed,
      surface: c.bg,
      onSurface: c.t1,
      onSurfaceVariant: c.t2,
      surfaceContainerHighest: c.card2,
      surfaceContainerHigh: c.card,
      surfaceContainer: c.card,
      surfaceContainerLow: c.inset,
      surfaceContainerLowest: c.inset2,
      surfaceDim: c.bg,
      surfaceBright: c.card,
      outline: c.borderHi,
      outlineVariant: c.border,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: isDark ? TgTokens.lT1 : TgTokens.dT1,
      onInverseSurface: isDark ? TgTokens.lBg : TgTokens.dBg,
      inversePrimary: isDark ? TgTokens.lGold : TgTokens.dGold,
      surfaceTint: Colors.transparent, // 关闭 M3 表面染色，保持卡片纯色
    );

    return ThemeData(
      useMaterial3: true,
      // 路由 push/pop 统一为原型 fadein：opacity 0→1 + translateY 8px→0，ease
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: TgFadeSlideTransitionsBuilder(),
          TargetPlatform.iOS: TgFadeSlideTransitionsBuilder(),
          TargetPlatform.linux: TgFadeSlideTransitionsBuilder(),
          TargetPlatform.macOS: TgFadeSlideTransitionsBuilder(),
          TargetPlatform.windows: TgFadeSlideTransitionsBuilder(),
          TargetPlatform.fuchsia: TgFadeSlideTransitionsBuilder(),
        },
      ),
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      extensions: [c],
      splashColor: c.goldTint(.10),
      highlightColor: c.goldTint(.06),

      // ---------- 文字 ----------
      // 衬线角色（hero/h1/大数字/品牌）保留 TgType 自带的 Noto Serif SC；
      // 其余无衬线角色显式指定 Noto Sans SC（不能用 apply 全局覆盖，否则会冲掉衬线）。
      textTheme: TextTheme(
        // 38/30 hero 大标题（serif · 字距4）
        displayLarge: TgType.hero.copyWith(color: c.t1),
        displayMedium: TgType.heroMobile.copyWith(color: c.t1),
        // 26 等级徽章 / 大数字（serif）
        displaySmall: TgType.display26.copyWith(color: c.t1),
        // 21 统计数字（sans · tabular）
        headlineLarge: TgType.stat21(c.gold2)
            .copyWith(fontFamily: TgFonts.sans),
        // 24 页面标题（serif · 字距1）
        headlineMedium: TgType.pageH1.copyWith(color: c.t1),
        headlineSmall: TgType.stat21(c.gold2)
            .copyWith(fontFamily: TgFonts.sans),
        // 19 品牌名 / 兽魂评分（serif）
        titleLarge: TgType.score19.copyWith(color: c.t1),
        // 14.5 卡片标题（sans）
        titleMedium: TgType.cardTitle.copyWith(
          color: c.t1,
          fontFamily: TgFonts.sans,
        ),
        // 13.5 按钮 / 导航项（sans）
        titleSmall: TgType.button.copyWith(
          color: c.t1,
          fontFamily: TgFonts.sans,
        ),
        // 15 步进器数字 / 操作按钮（sans）
        bodyLarge: TgType.control15.copyWith(
          color: c.t1,
          fontFamily: TgFonts.sans,
        ),
        // 14 正文（sans）
        bodyMedium: TgType.body14.copyWith(
          color: c.t1,
          fontFamily: TgFonts.sans,
        ),
        // 12.5 label（sans）
        bodySmall: TgType.label.copyWith(color: c.t2, fontFamily: TgFonts.sans),
        // 13.5 按钮文字（sans）
        labelLarge: TgType.button.copyWith(
          color: c.t1,
          fontFamily: TgFonts.sans,
        ),
        // 11.5 注释 / 表头（sans）
        labelMedium: TgType.note.copyWith(
          color: c.t3,
          fontFamily: TgFonts.sans,
        ),
        // 11 tag / 页脚（sans）
        labelSmall: TgType.tag.copyWith(color: c.t3, fontFamily: TgFonts.sans),
      ),

      // ---------- 顶栏 ----------
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: c.t1,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TgType.topTitle.copyWith(color: c.t1),
        iconTheme: IconThemeData(size: 20, color: c.t2),
      ),

      // ---------- 图标 / 分隔线 ----------
      iconTheme: IconThemeData(size: 20, color: c.t2),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),

      // ---------- 输入框：h42 · r11 · inset 底 · 聚焦金描边 ----------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.inset,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 10,
        ),
        constraints: const BoxConstraints(minHeight: 42),
        hintStyle: TgType.body14.copyWith(color: c.t3),
        border: OutlineInputBorder(
          borderRadius: TgRadius.input,
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: TgRadius.input,
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: TgRadius.input,
          borderSide: BorderSide(color: c.gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: TgRadius.input,
          borderSide: BorderSide(color: c.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: TgRadius.input,
          borderSide: BorderSide(color: c.red, width: 1.5),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.gold,
        selectionColor: c.goldTint(.28),
        selectionHandleColor: c.gold,
      ),

      // ---------- 按钮 ----------
      // 主按钮为金色渐变，使用组件库中的 TgGradientButton；
      // ElevatedButton 主题提供同色系扁平回退。
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.gold,
          foregroundColor: TgTokens.btnInk,
          elevation: 0,
          minimumSize: const Size(64, 41),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: TgType.button.copyWith(
            color: TgTokens.btnInk,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: TgRadius.btn),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: c.t2,
              minimumSize: const Size(64, 41),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              side: BorderSide(color: c.borderHi),
              textStyle: TgType.button.copyWith(color: c.t2),
              shape: RoundedRectangleBorder(borderRadius: TgRadius.btn),
            ).copyWith(
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.hovered) ? c.t1 : c.t2,
              ),
              side: WidgetStateProperty.resolveWith(
                (states) => BorderSide(
                  color: states.contains(WidgetState.hovered)
                      ? c.goldTint(.45)
                      : c.borderHi,
                ),
              ),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.gold,
          textStyle: TgType.button.copyWith(color: c.gold),
        ),
      ),

      // ---------- chip：胶囊 · tag 底 ----------
      chipTheme: ChipThemeData(
        backgroundColor: c.inset,
        selectedColor: c.goldTint(.12),
        labelStyle: TgType.row13.copyWith(color: c.t1),
        secondaryLabelStyle: TgType.row13.copyWith(color: c.gold2),
        side: BorderSide(color: c.border),
        shape: const StadiumBorder(), // 胶囊（999px）
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),

      // ---------- 开关（46×26 视觉规格见 TgSwitch 组件） ----------
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.gold : c.t3,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.goldTint(.14)
              : c.inset2,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.goldTint(.45)
              : c.borderHi,
        ),
        trackOutlineWidth: const WidgetStatePropertyAll(1),
      ),

      // ---------- 其他 ----------
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.gold,
        linearTrackColor: c.inset,
        circularTrackColor: c.inset,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.card2,
        contentTextStyle: TgType.row13.copyWith(color: c.t1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: TgRadius.card),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.inset2,
          borderRadius: TgRadius.input,
          border: Border.all(color: c.borderHi),
        ),
        textStyle: TgType.tag.copyWith(color: c.t2),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.gold
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(TgTokens.btnInk),
        side: BorderSide(color: c.borderHi),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(c.sbThumb),
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(99),
      ),
    );
  }
}
