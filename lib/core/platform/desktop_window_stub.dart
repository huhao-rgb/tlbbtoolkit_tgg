/// Web 端占位实现：浏览器由宿主管理窗口，所有操作均为空实现。
Future<void> initDesktopWindow() async {}

Future<void> minimize() async {}

Future<void> toggleMaximize() async {}

Future<void> close() async {}

Future<void> startDragging() async {}

Future<bool> isMaximized() async => false;

void attachMaximizeListener(void Function(bool) onChanged) {}

void detachMaximizeListener() {}
