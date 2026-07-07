import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/providers/premium_provider.dart';
import '../../lib/services/license_service.dart';

/// ── PremiumNotifier 测试 ─────────────────────────────────────────────────
///
/// 验证 Pro 状态机：初始 free、setPro、deactivate、clearAppOnly。
///
/// PremiumNotifier 依赖 LicenseService（单例），其 Pro 状态持久化到
/// SharedPreferences。测试间需重置 LicenseService 缓存 + mock prefs。

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PremiumNotifier notifier;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LicenseService.resetCacheForTest();
    await LicenseService().init();
    notifier = PremiumNotifier();
  });

  tearDown(() {
    notifier.dispose();
    LicenseService.resetCacheForTest();
  });

  group('初始状态', () {
    test('默认为 free', () {
      expect(notifier.state, PremiumStatus.free);
      expect(notifier.isPro, isFalse);
    });
  });

  group('setPro', () {
    test('调用后状态变为 pro', () {
      notifier.setPro();
      expect(notifier.state, PremiumStatus.pro);
      expect(notifier.isPro, isTrue);
    });
  });

  group('deactivate', () {
    test('从 pro 调用 deactivate 后变为 free', () async {
      notifier.setPro();
      expect(notifier.isPro, isTrue);
      await notifier.deactivate();
      expect(notifier.state, PremiumStatus.free);
      expect(notifier.isPro, isFalse);
    });
  });

  group('clearAppOnly', () {
    test('从 pro 调用 clearAppOnly 后变为 free', () async {
      notifier.setPro();
      expect(notifier.isPro, isTrue);
      await notifier.clearAppOnly();
      expect(notifier.state, PremiumStatus.free);
    });
  });

  group('构造时读取已持久化的 Pro 状态', () {
    test('已激活（prefs 中 premium_active=true）→ 初始为 pro', () async {
      // 通过 LicenseService 激活并持久化
      final svc = LicenseService();
      await svc.init();
      // 直接写 prefs 模拟已激活状态
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('premium_active', true);
      LicenseService.resetCacheForTest();
      await svc.init();
      expect(svc.isPro, isTrue);

      notifier.dispose();
      notifier = PremiumNotifier();
      expect(notifier.state, PremiumStatus.pro);
    });
  });
}
