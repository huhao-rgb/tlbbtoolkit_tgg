import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 一条错误记录（不可变）。
@immutable
class ErrorLogEntry {
  const ErrorLogEntry({
    required this.at,
    required this.context,
    required this.error,
    this.stack,
  });

  /// 发生时间（本地时区）。
  final DateTime at;

  /// 来源标记，如 `flutter` / `platform` / `zone` / 自定义业务标签。
  final String context;

  /// `error.toString()`（已截断）。
  final String error;

  /// 堆栈（已截断，可能为 null）。
  final String? stack;

  Map<String, Object?> toJson() => {
    'at': at.toIso8601String(),
    'ctx': context,
    'err': error,
    'st': stack,
  };

  /// 解析单条记录；结构不符返回 null（不让坏日志拖垮读取）。
  static ErrorLogEntry? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final at = DateTime.tryParse(raw['at'] as String? ?? '');
    final error = raw['err'];
    if (at == null || error is! String) return null;
    final ctx = raw['ctx'];
    final stack = raw['st'];
    return ErrorLogEntry(
      at: at,
      context: ctx is String && ctx.isNotEmpty ? ctx : 'app',
      error: error,
      stack: stack is String && stack.isNotEmpty ? stack : null,
    );
  }

  /// 导出为人类可读的多行文本。
  String toText() {
    final buffer = StringBuffer()
      ..writeln('[${at.toIso8601String()}] ($context) $error');
    if (stack != null) buffer.writeln(stack);
    return buffer.toString();
  }
}

/// 本机错误日志：**只在内存与本地存储里**，不联网、不上报。
///
/// 设计目标是在「不集成崩溃统计 SDK」的前提下，让 release 包里的异常至少
/// 留下可导出的现场：
/// - 内存环形缓冲最多 [maxEntries] 条（旧记录先丢）；
/// - 每次记录后异步落盘到 SharedPreferences，下次启动可继续查看；
/// - 所有写入都吞异常：日志本身绝不能成为新的崩溃源。
///
/// 读取入口：设置页「关于 → 诊断日志」复制文本。
class ErrorLog {
  ErrorLog({
    this.maxEntries = 20,
    this.maxErrorLength = 2000,
    this.maxStackLength = 6000,
  });

  /// 全局单例（App 运行时使用）。
  static final ErrorLog instance = ErrorLog();

  /// SharedPreferences 存储键（带版本号，便于将来换格式）。
  static const String storageKey = 'tgg-error-log-v1';

  final int maxEntries;
  final int maxErrorLength;
  final int maxStackLength;

  final List<ErrorLogEntry> _entries = [];
  SharedPreferences? _prefs;
  bool _saving = false;
  bool _dirty = false;

  /// 最近的记录，新的在前。
  List<ErrorLogEntry> get entries => List.unmodifiable(_entries.reversed);

  bool get isEmpty => _entries.isEmpty;

  /// 绑定本地存储并载入历史记录（App 启动时调用一次）。
  Future<void> attach(SharedPreferences prefs) async {
    _prefs = prefs;
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final loaded = <ErrorLogEntry>[];
      for (final item in decoded) {
        final entry = ErrorLogEntry.fromJson(item);
        if (entry != null) loaded.add(entry);
      }
      _entries
        ..clear()
        ..addAll(loaded.take(maxEntries));
    } on FormatException {
      // 历史日志损坏：忽略，不覆盖用户数据。
    }
  }

  /// 记录一条错误。同步返回，落盘异步且不影响调用方。
  void record(Object error, StackTrace? stack, {String context = 'app'}) {
    final entry = ErrorLogEntry(
      at: DateTime.now(),
      context: context,
      error: _truncate(error.toString(), maxErrorLength),
      stack: stack == null ? null : _truncate(stack.toString(), maxStackLength),
    );

    _entries.add(entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }

    // release 也保留一行现场（debugPrint 不会被 tree-shake），便于 logcat 定位。
    debugPrint('[ErrorLog][${entry.context}] ${entry.error}');
    unawaited(_persist());
  }

  /// 导出全部记录为文本；无记录时返回空串。
  String exportText() {
    if (_entries.isEmpty) return '';
    final buffer = StringBuffer()
      ..writeln('天工阁 · 诊断日志')
      ..writeln('共 ${_entries.length} 条（仅保存在本机）')
      ..writeln();
    for (final entry in _entries.reversed) {
      buffer.writeln(entry.toText());
    }
    return buffer.toString().trimRight();
  }

  /// 清空内存与本地记录。
  Future<void> clear() async {
    _entries.clear();
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.remove(storageKey);
    } on Object {
      // 清理失败不影响使用。
    }
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    // 正在写入时只标脏，等本轮写完再补一次：直接返回会把紧随其后的
    // 新记录（如连续两条错误）漏掉。
    if (_saving) {
      _dirty = true;
      return;
    }
    _saving = true;
    try {
      do {
        _dirty = false;
        final payload = [for (final entry in _entries) entry.toJson()];
        await prefs.setString(storageKey, jsonEncode(payload));
      } while (_dirty);
    } on Object {
      // 落盘失败（配额/平台异常）只影响日志持久化，绝不能冒泡。
    } finally {
      _saving = false;
    }
  }

  static String _truncate(String value, int max) =>
      value.length <= max ? value : '${value.substring(0, max)}…（已截断）';
}
