import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/core/app_clock.dart';

/// ── 测试时钟控制 ──────────────────────────────────────────────────────────
///
/// 统一封装 [AppClock] 在测试环境下的 override/reset 逻辑。
///
/// **背景**：[AppClock.override] 会同步设置 `_impl`，然后尝试持久化偏移到
/// SharedPreferences —— 在纯 Dart 测试环境中后者抛 [MissingPluginException]。
/// 时钟实际上已正确设置，仅需吞掉持久化异常。
///
/// **用法**：
/// ```dart
/// final fakeNow = DateTime(2025, 6, 15, 12, 0);
/// setUp(() async {
///   await setTestClock(fakeNow);
///   // ... 其他初始化
/// });
/// tearDown(() async {
///   // ... 其他清理
///   await resetTestClock();
/// });
/// ```
///
/// 此工具消除了 `weight_math_test.dart` / `task_repository_test.dart` /
/// `operation_service_test.dart` 中重复的 `_setClock`/`_resetClock` 实现。

/// 将 [AppClock] 偏移到 [dateTime]，之后以真实速率流动。
///
/// 持久化失败（测试环境无 SharedPreferences 插件）会被静默吞掉，
/// 因为时钟的内存状态已正确设置。
Future<void> setTestClock(DateTime dateTime) async {
  try {
    await AppClock.override(dateTime);
  } on MissingPluginException {
    // SharedPreferences 在纯 Dart 测试中不可用；时钟 impl 已设置完毕。
  }
}

/// 恢复 [AppClock] 为真实时间，并清除持久化偏移。
Future<void> resetTestClock() async {
  try {
    await AppClock.reset();
  } on MissingPluginException {
    // 持久化不可用；impl 已重置。
  }
}

/// 同时初始化 SharedPreferences mock 并设置时钟的便捷方法。
///
/// 用于需要两者配合的测试（如依赖 work_hours 配置的 TaskRepository）。
Future<void> setTestClockWithPrefs(DateTime dateTime) async {
  SharedPreferences.setMockInitialValues({});
  await setTestClock(dateTime);
}
