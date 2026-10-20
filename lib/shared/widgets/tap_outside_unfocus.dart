import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/widgets.dart';

/// 让「点击输入框以外的区域」收起键盘、释放焦点（全站生效，含移动端）。
///
/// Flutter 默认只在桌面 / Web 上这样做：移动端触摸 [EditableText] 以外的
/// 区域不会失焦（见 `_EditableTextTapOutsideAction` 中对
/// `PointerDeviceKind.touch` 的显式忽略）。这里覆盖
/// [EditableTextTapOutsideIntent] / [EditableTextTapUpOutsideIntent]，把两端
/// 行为统一为「点击外部即失焦」：
///
/// - 按下（outside）只记录坐标，不立即失焦；
/// - 抬起（outside）时，若与按下点距离不超过 [kTouchSlop]（判定为点击而非
///   拖动），且该输入框仍持有焦点，才让它失焦。
///
/// 之所以不在按下时就失焦：键盘展开时用户常会滑动列表，按下即失焦会一碰就
/// 收键盘。挂在 App 根部即可覆盖所有输入框（包括各页面内联的裸 [TextField]），
/// 无需逐个改。
class TapOutsideUnfocus extends StatefulWidget {
  const TapOutsideUnfocus({super.key, required this.child});

  final Widget child;

  @override
  State<TapOutsideUnfocus> createState() => _TapOutsideUnfocusState();
}

class _TapOutsideUnfocusState extends State<TapOutsideUnfocus> {
  /// 各指针「在输入框外按下」的位置（指针 id → 坐标）。
  ///
  /// 一次点击会通知树中每个输入框（每个输入框都注册了自己的 tap region），
  /// 故按指针 id 归并；抬起后不立即删除，否则先收到通知的输入框会把记录删掉，
  /// 真正持有焦点的框就查不到了。下次按下会覆盖同 id 记录，另设上限避免
  /// 长会话中 id 持续递增导致无界增长。
  static const int _maxTrackedPointers = 16;

  final Map<int, Offset> _downPositions = <int, Offset>{};

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        EditableTextTapOutsideIntent:
            CallbackAction<EditableTextTapOutsideIntent>(
              onInvoke: (intent) {
                _downPositions[intent.pointerDownEvent.pointer] =
                    intent.pointerDownEvent.position;
                if (_downPositions.length > _maxTrackedPointers) {
                  _downPositions.remove(_downPositions.keys.first);
                }
                return null;
              },
            ),
        EditableTextTapUpOutsideIntent:
            CallbackAction<EditableTextTapUpOutsideIntent>(
              onInvoke: (intent) {
                final down = _downPositions[intent.pointerUpEvent.pointer];
                // 无对应的外部按下（例如从框内拖到框外松手），不处理。
                if (down == null) return null;
                // 抬手明显偏离按下点 = 滑动而非点击，保持焦点以便继续输入。
                if ((intent.pointerUpEvent.position - down).distance >
                    kTouchSlop) {
                  return null;
                }
                // 树中每个输入框都会收到通知，只有仍持有焦点的那个才该失焦
                // （焦点可能已被另一个输入框接管）。
                if (!intent.focusNode.hasFocus) return null;
                intent.focusNode.unfocus();
                return null;
              },
            ),
      },
      child: widget.child,
    );
  }
}
