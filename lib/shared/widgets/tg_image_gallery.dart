import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app/theme/design_tokens.dart';
import 'tg_icon.dart';

/// 画廊单图数据。
class TgGalleryImage {
  const TgGalleryImage({required this.url, this.caption, this.errorIcon});

  /// 图片地址（网络图，与缩略图同一地址时走同一缓存）。
  final String url;

  /// 底部说明文字（如图片所属商品标题）。
  final String? caption;

  /// 加载失败时占位 icon 资产名（如 `paw` / `user`）；默认 `info`。
  final String? errorIcon;
}

/// 打开全屏图片画廊（非 Dialog 卡片样式）。
///
/// - 黑底全屏 + [PageView] 左右滑动浏览多图，顶栏页码「n / m」与关闭按钮；
/// - 双指捏合放大 / 缩小（0.5x ~ 5x，可缩到比屏幕更小便于查看整图），
///   双击放大 / 双击还原，放大后单指拖动平移；
/// - 未放大时上下滑动跟手拖动画廊，松手超过阈值（或快速甩动）关闭，否则回弹；
/// - 传入 [sourceRect]（点击缩略图的全局矩形）时播放「Hero」飞入动画：
///   缩略图从原位放大飞到屏幕中央；点击关闭按钮时反向飞回原位再关闭。
///
/// 通过 root navigator 压栈（与 showTgModal 一致），覆盖整个应用窗口
/// （含桌面侧栏 / 顶栏），返回的 Future 在画廊关闭时完成。
Future<void> showTgImageGallery(
  BuildContext context, {
  required List<TgGalleryImage> images,
  int initialIndex = 0,
  Rect? sourceRect,
  String? title,
}) {
  final imgs = images.where((e) => e.url.isNotEmpty).toList(growable: false);
  if (imgs.isEmpty) return Future.value();
  final idx = initialIndex.clamp(0, imgs.length - 1);
  return Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => TgImageGallery(
        images: imgs,
        initialIndex: idx,
        sourceRect: sourceRect,
        title: title,
      ),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// 全屏图片画廊（内部实现，见 [showTgImageGallery]）。
class TgImageGallery extends StatefulWidget {
  const TgImageGallery({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.sourceRect,
    this.title,
  });

  final List<TgGalleryImage> images;
  final int initialIndex;

  /// 触发入口缩略图的全局矩形（Hero 飞入起点 / 关闭飞回终点）。
  final Rect? sourceRect;

  /// 顶栏标题（如「商品图片预览」）。
  final String? title;

  @override
  State<TgImageGallery> createState() => _TgImageGalleryState();
}

class _TgImageGalleryState extends State<TgImageGallery>
    with TickerProviderStateMixin {
  static const double _kDismissRatio = 0.2; // 拖动超过屏高 20% 关闭
  static const double _kFlingPxPerSec = 700; // 快速甩动也关闭

  late final PageController _pageController;
  late int _index;
  bool _physicsEnabled = true; // 缩放中禁用 PageView 左右翻页

  // 上下滑动关闭
  late final AnimationController _dismissCtrl;
  double _dismissDy = 0;
  double _dismissFrom = 0;
  double _dismissTo = 0;
  bool _dismissingOut = false;

  // Hero 飞入 / 飞出
  late final AnimationController _heroCtrl;
  bool _heroVisible = false;
  bool _heroOut = false;
  bool _closing = false;
  late Rect? _heroSrc;
  Rect _heroRect = Rect.zero;
  int _heroIndex = 0;
  double _blackOpacity = 0;

  Size _pageArea = Size.zero;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _heroIndex = _index;
    _heroSrc = widget.sourceRect;
    _pageController = PageController(initialPage: _index);

    _dismissCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(_onDismissTick)
      ..addStatusListener(_onDismissStatus);

    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(_onHeroTick)
      ..addStatusListener(_onHeroStatus);

    WidgetsBinding.instance.addPostFrameCallback((_) => _startOpening());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _dismissCtrl.dispose();
    _heroCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 打开动画：黑底淡入 +（有 sourceRect 时）缩略图飞入
  // ---------------------------------------------------------------------------

  void _startOpening() {
    if (!mounted) return;
    if (_heroSrc != null) {
      setState(() {
        _heroVisible = true;
        _heroOut = false;
        _heroRect = _heroSrc!;
      });
    }
    _heroCtrl.forward(from: 0);
  }

  void _onHeroTick() {
    final v = _heroCtrl.value;
    final t = _heroOut ? 1 - v : v; // 飞入 0→1；飞出 1→0
    setState(() {
      _blackOpacity = t;
      final src = _heroSrc;
      if (src != null) {
        _heroRect = Rect.lerp(
          src,
          _heroTargetRect(),
          Curves.easeInOutCubic.transform(t),
        )!;
      }
    });
  }

  void _onHeroStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_heroOut) {
      Navigator.of(context).pop();
    } else {
      setState(() => _heroVisible = false);
    }
  }

  /// 目标矩形：页面区域内最大的居中正方形（商品图为方形裁切，与
  /// 页面内 BoxFit.contain 的呈现位置一致，保证飞行结束无缝衔接）。
  Rect _heroTargetRect() {
    final area = _pageArea;
    if (area == Size.zero) return _heroSrc ?? Rect.zero;
    final side = math.min(area.width, area.height);
    return Rect.fromCenter(
      center: area.center(Offset.zero),
      width: side,
      height: side,
    );
  }

  // ---------------------------------------------------------------------------
  // 上下滑动关闭
  // ---------------------------------------------------------------------------

  void _onDismissDrag(double dy) {
    if (_dismissingOut || _closing || _heroVisible) return;
    setState(() => _dismissDy += dy);
  }

  void _onDismissEnd({required double velocity, required double totalDy}) {
    if (_dismissingOut || _closing || _heroVisible) return;
    final h = MediaQuery.sizeOf(context).height;
    final shouldClose =
        totalDy.abs() > h * _kDismissRatio || velocity.abs() > _kFlingPxPerSec;
    _dismissFrom = _dismissDy;
    _dismissTo = shouldClose
        ? (totalDy > 0 ? h * 1.2 : -h * 1.2)
        : 0;
    _dismissingOut = shouldClose;
    _dismissCtrl.forward(from: 0);
  }

  void _onDismissTick() {
    final t = Curves.easeOutCubic.transform(_dismissCtrl.value);
    setState(() {
      _dismissDy = _dismissFrom + (_dismissTo - _dismissFrom) * t;
    });
  }

  void _onDismissStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _dismissingOut) {
      Navigator.of(context).pop();
    }
  }

  // ---------------------------------------------------------------------------
  // 关闭
  // ---------------------------------------------------------------------------

  void _close() {
    if (_closing || _dismissingOut || _heroVisible) return;
    _closing = true;
    final src = widget.sourceRect;
    if (src != null) {
      setState(() {
        _heroOut = true;
        _heroVisible = true;
        _heroIndex = _index;
        _heroSrc = src;
        _heroRect = _heroTargetRect();
      });
      _heroCtrl.forward(from: 0);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onZoomChanged(bool zoomed) {
    final next = !zoomed;
    if (_physicsEnabled == next) return;
    setState(() => _physicsEnabled = next);
  }

  // ---------------------------------------------------------------------------
  // 构建
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final h = size.height;
    final progress = h <= 0
        ? 0.0
        : (_dismissDy.abs() / (h * 0.45)).clamp(0.0, 1.0);
    final fade = _heroSrc == null ? _blackOpacity : 1.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          _pageArea = constraints.biggest;
          return Stack(
            fit: StackFit.expand,
            children: [
              // 黑底：随飞入/飞出淡入淡出，随下滑关闭渐隐
              ColoredBox(
                color: Colors.black.withValues(alpha: _blackOpacity * (1 - progress * 0.96)),
              ),
              // 画廊主体（Hero 飞行期间隐藏，避免提前露出目标图）
              if (!_heroVisible)
                Opacity(
                  opacity: fade,
                  child: Transform.translate(
                    offset: Offset(0, _dismissDy),
                    child: Transform.scale(
                      scale: 1 - progress * 0.08,
                      child: _buildGallery(),
                    ),
                  ),
                ),
              // Hero 飞行覆盖层
              if (_heroVisible && _heroSrc != null)
                Positioned.fromRect(
                  rect: _heroRect,
                  child: IgnorePointer(child: _buildFlightImage()),
                ),
              // 顶栏 / 页码 / 关闭 + 底部说明（飞行与关闭动画期间隐藏）
              if (!_heroVisible && !_closing)
                Opacity(
                  opacity: fade * (1 - progress),
                  child: _buildChrome(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGallery() {
    final imgs = widget.images;
    return PageView.builder(
      controller: _pageController,
      physics: _physicsEnabled
          ? const PageScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemCount: imgs.length,
      onPageChanged: (i) => setState(() => _index = i),
      itemBuilder: (context, i) {
        final img = imgs[i];
        return _ZoomableGalleryPage(
          key: ValueKey('gallery-page-$i'),
          url: img.url,
          errorIcon: img.errorIcon,
          onZoomChanged: _onZoomChanged,
          onDismissDrag: _onDismissDrag,
          onDismissEnd: _onDismissEnd,
        );
      },
    );
  }

  Widget _buildFlightImage() {
    final img = widget.images[_heroIndex];
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        img.url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: 1600,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const ColoredBox(color: Colors.black26),
        errorBuilder: (_, _, _) => ColoredBox(
          color: Colors.black26,
          child: Center(
            child: TgIcon(
              img.errorIcon ?? 'info',
              size: 30,
              color: Colors.white38,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChrome() {
    final imgs = widget.images;
    final caption = imgs[_index].caption;
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title ?? '图片预览',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: TgFonts.serif,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Text(
                    '${_index + 1} / ${imgs.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _GalleryCloseButton(
                  key: const Key('tg-gallery-close'),
                  onTap: _close,
                ),
              ],
            ),
          ),
          if (caption != null && caption.isNotEmpty)
            Positioned(
              left: 24,
              right: 24,
              bottom: 26,
              child: Text(
                caption,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.5,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 画廊顶栏关闭按钮（白色半透明圆钮）。
class _GalleryCloseButton extends StatelessWidget {
  const _GalleryCloseButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white10,
      shape: const CircleBorder(
        side: BorderSide(color: Colors.white24, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        hoverColor: Colors.white12,
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Center(child: TgIcon('x', size: 14, color: Colors.white)),
        ),
      ),
    );
  }
}

/// 单个画廊页：双指捏合缩放 + 单指平移 + 双击缩放 + 未放大时上下滑动关闭。
class _ZoomableGalleryPage extends StatefulWidget {
  const _ZoomableGalleryPage({
    super.key,
    required this.url,
    required this.onZoomChanged,
    required this.onDismissDrag,
    required this.onDismissEnd,
    this.errorIcon,
  });

  final String url;
  final String? errorIcon;
  final ValueChanged<bool> onZoomChanged;
  final ValueChanged<double> onDismissDrag;
  final void Function({required double velocity, required double totalDy})
      onDismissEnd;

  @override
  State<_ZoomableGalleryPage> createState() => _ZoomableGalleryPageState();
}

class _ZoomableGalleryPageState extends State<_ZoomableGalleryPage> {
  /// 最小缩放：可缩到比屏幕更小（0.5x），便于查看整图与周围留白。
  static const double _kMinScale = 0.5;
  static const double _kMaxScale = 5.0;

  double _scale = 1.0;
  Offset _offset = Offset.zero;

  // 手势起点快照（捏合锚点计算用）
  double _startScale = 1.0;
  Offset _startOffset = Offset.zero;
  Offset _startFocal = Offset.zero;

  bool _zoomed = false;
  Size _box = Size.zero;
  double _dragDy = 0;
  Offset? _doubleTapFocal;

  @override
  Widget build(BuildContext context) {
    // Listener 负责接收桌面端指针信号（鼠标滚轮缩放）；触控板捏合走
    // GestureDetector 的 onScale*（ScaleGestureRecognizer 处理 PointerPanZoom）。
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: _onScaleEnd,
        onDoubleTapDown: (d) => _doubleTapFocal = d.localPosition,
        onDoubleTap: _onDoubleTap,
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _box = constraints.biggest;
              return Transform.translate(
                offset: _offset,
                child: Transform.scale(
                  key: const Key('gallery-page-zoom'),
                  scale: _scale,
                  child: _buildImage(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _zoomByWheel(event);
    }
  }

  /// 鼠标滚轮 / 触控板双指滚动缩放：上滚放大、下滚缩小，以光标为锚点。
  void _zoomByWheel(PointerScrollEvent event) {
    final dy = event.scrollDelta.dy;
    if (dy == 0 || _box == Size.zero) return;
    // 按滚动量连续缩放（指数步进），并限制单步幅度避免跳变
    final factor = math.exp(-dy * 0.12).clamp(0.72, 1.4);
    _applyZoom(_scale * factor, event.localPosition);
  }

  Widget _buildImage() {
    return Image.network(
      widget.url,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: 2000,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : const Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white38,
                ),
              ),
            ),
      errorBuilder: (_, _, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TgIcon(widget.errorIcon ?? 'info', size: 56, color: Colors.white30),
            const SizedBox(height: 10),
            const Text(
              '图片加载失败',
              style: TextStyle(fontSize: 12, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  void _onScaleStart(ScaleStartDetails d) {
    _startScale = _scale;
    _startOffset = _offset;
    _startFocal = d.localFocalPoint;
    _dragDy = 0;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (_box == Size.zero) return;
    if (d.pointerCount >= 2) {
      // 双指捏合：以手势起点焦点为锚点缩放
      final newScale = (_startScale * d.scale).clamp(_kMinScale, _kMaxScale);
      final c = _box.center(Offset.zero);
      final newOffset = (newScale - 1).abs() < 0.0001
          ? Offset.zero
          : _clampOffset(
              d.localFocalPoint -
                  c -
                  (_startFocal - _startOffset - c) * (newScale / _startScale),
              newScale,
              _box,
            );
      setState(() {
        _scale = newScale;
        _offset = newOffset;
      });
    } else if (_scale > 1.01) {
      // 放大后单指拖动平移（边界收敛）
      setState(() {
        _offset = _clampOffset(_offset + d.focalPointDelta, _scale, _box);
      });
    } else {
      // 未放大：上下拖动 → 交给画廊做关闭手势
      final dy = d.focalPointDelta.dy;
      if (dy != 0) {
        _dragDy += dy;
        widget.onDismissDrag(dy);
      }
    }
  }

  void _onScaleEnd(ScaleEndDetails d) {
    final zoomed = _scale > 1.01;
    if (zoomed != _zoomed) {
      _zoomed = zoomed;
      widget.onZoomChanged(_zoomed);
    }
    if (!_zoomed) {
      widget.onDismissEnd(
        velocity: d.velocity.pixelsPerSecond.dy,
        totalDy: _dragDy,
      );
    }
  }

  void _onDoubleTap() {
    final focal = _doubleTapFocal ?? _box.center(Offset.zero);
    _applyZoom(_scale > 1.01 ? 1.0 : 2.5, focal);
  }

  /// 以视图内 [focal] 为锚点，将缩放设为 [targetScale]
  /// （缩放前后 focal 下的图像内容保持不动）。
  void _applyZoom(double targetScale, Offset focal) {
    if (_box == Size.zero) return;
    final clamped = targetScale.clamp(_kMinScale, _kMaxScale);
    final c = _box.center(Offset.zero);
    final Offset newOffset;
    if ((clamped - 1).abs() < 0.0001) {
      newOffset = Offset.zero;
    } else {
      // 当前 focal 下的场景点：s = c + (focal - offset - c) / scale
      final sceneFromCenter = (focal - _offset - c) / _scale;
      // 让该场景点仍落在 focal：offset' = focal - c - s' * clamped
      newOffset = _clampOffset(
        focal - c - sceneFromCenter * clamped,
        clamped,
        _box,
      );
    }
    _setZoom(clamped, newOffset);
  }

  void _setZoom(double scale, Offset offset) {
    setState(() {
      _scale = scale;
      _offset = offset;
    });
    final zoomed = scale > 1.01;
    if (zoomed != _zoomed) {
      _zoomed = zoomed;
      widget.onZoomChanged(_zoomed);
    }
  }

  Offset _clampOffset(Offset off, double scale, Size box) {
    if (scale <= 1.0) return Offset.zero;
    final maxX = box.width * (scale - 1) / 2;
    final maxY = box.height * (scale - 1) / 2;
    return Offset(off.dx.clamp(-maxX, maxX), off.dy.clamp(-maxY, maxY));
  }
}
