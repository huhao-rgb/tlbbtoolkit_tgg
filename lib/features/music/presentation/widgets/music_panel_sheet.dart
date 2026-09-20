import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import 'music_popover_panel.dart';

/// sheet 弹层遮罩（与 `tg_modal` 的深色遮罩同值，保持全站弹层一致）。
const _sheetBarrier = Color(0xA807090D);

/// 列表最大高度：比桌面弹层（264）放宽一些，手机上一屏内更好挑歌。
const double _sheetListMaxHeight = 320;

/// 移动端（窄窗口 + 触屏）从底部弹出「怀旧音律」面板。
///
/// 桌面弹层靠 `CompositedTransformFollower` 锚定信息栏按钮，位置依赖目标
/// 已绘制的位置，窄屏/旋转后容易被推到屏幕外；因此移动端布局（< 1024，
/// 与 shell 的断点一致）改用底部 sheet：整宽贴底、可下拉关闭、点遮罩关闭。
///
/// 用 `useRootNavigator` 推到根 Navigator：shell 的分支 Navigator 在顶栏
/// 之下，若推在分支内，面板会被悬浮信息栏/底栏盖住。
Future<void> showMusicPanelSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: _sheetBarrier,
    builder: (context) => const _MusicSheet(),
  );
}

/// 底部面板 chrome：拖拽手柄 + 整宽卡片（顶圆角）+ 底部安全区。
///
/// 内容复用桌面弹层的 [MusicPanelContent]，两端只有外壳不同。
class _MusicSheet extends StatelessWidget {
  const _MusicSheet();

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    final insets = MediaQuery.paddingOf(context);
    final maxListHeight = math.min(
      _sheetListMaxHeight,
      MediaQuery.sizeOf(context).height * .45,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tg.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        border: Border.all(color: tg.borderHi, width: 1),
        // 向上投影（桌面弹层是向下投影）
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 46,
            offset: Offset(0, -18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DragHandle(),
          MusicPanelContent(maxListHeight: maxListHeight),
          // 底部安全区（Home indicator / 手势条）
          SizedBox(height: math.max(insets.bottom, 12)),
        ],
      ),
    );
  }
}

/// 拖拽手柄（下拉关闭提示；`showModalBottomSheet` 默认 enableDrag）。
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final tg = context.tg;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: tg.borderHi,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
