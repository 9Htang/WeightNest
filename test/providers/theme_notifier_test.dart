import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/theme/theme_notifier.dart';

/// ── ThemeModeNotifier 测试 ───────────────────────────────────────────────
///
/// 验证主题状态机：初始值、setTheme 切换、SharedPreferences 持久化。
///
/// 注意：构造函数异步调用 `_load()` 但未 await，测试需 pump 一个微任务
/// 让加载完成。每个测试自包含 notifier，不共享状态，避免 SharedPreferences
/// 静态缓存导致的跨测试污染。

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('初始状态', () {
    test('无持久化值时默认为 system', () {
      SharedPreferences.setMockInitialValues({});
      final notifier = ThemeModeNotifier();
      expect(notifier.state, ThemeMode.system);
      notifier.dispose();
    });

    test('有持久化值时（dark）异步加载后为 dark', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final notifier = ThemeModeNotifier();
      // 等待构造函数中 _load() 的异步 SharedPreferences 读取完成
      await Future.delayed(const Duration(milliseconds: 10));
      expect(notifier.state, ThemeMode.dark);
      notifier.dispose();
    });

    test('持久化值无效时回退为 system', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'invalid_mode'});
      final notifier = ThemeModeNotifier();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(notifier.state, ThemeMode.system);
      notifier.dispose();
    });
  });

  group('setTheme', () {
    test('切换到 light', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = ThemeModeNotifier();
      await notifier.setTheme(ThemeMode.light);
      expect(notifier.state, ThemeMode.light);
      notifier.dispose();
    });

    test('切换到 dark', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = ThemeModeNotifier();
      await notifier.setTheme(ThemeMode.dark);
      expect(notifier.state, ThemeMode.dark);
      notifier.dispose();
    });

    test('切换回 system', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = ThemeModeNotifier();
      await notifier.setTheme(ThemeMode.dark);
      await notifier.setTheme(ThemeMode.system);
      expect(notifier.state, ThemeMode.system);
      notifier.dispose();
    });

    test('切换后持久化到 SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = ThemeModeNotifier();
      await notifier.setTheme(ThemeMode.dark);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
      notifier.dispose();
    });
  });

  group('跨实例持久化', () {
    test('一个实例保存后，新实例能读到', () async {
      SharedPreferences.setMockInitialValues({});
      final first = ThemeModeNotifier();
      await first.setTheme(ThemeMode.light);
      first.dispose();

      // 新实例（模拟 app 重启）
      final restarted = ThemeModeNotifier();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(restarted.state, ThemeMode.light);
      restarted.dispose();
    });
  });
}
