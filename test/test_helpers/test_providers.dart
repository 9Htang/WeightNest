import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lib/core/plugin_registry.dart';
import '../../lib/database/database.dart';
import '../../lib/plugins/weight/weight_plugin.dart';
import '../../lib/providers.dart';

/// ── Provider 测试基础设施 ────────────────────────────────────────────────
///
/// 封装 [ProviderContainer] 在测试环境下的创建/销毁逻辑。
///
/// 与 [setUpTestDb]（来自 test_factories.dart）对应：后者用于直接调用仓储
/// 方法的测试，本 helper 用于通过 Riverpod provider 间接访问 DB 的测试。
///
/// **用法**：
/// ```dart
/// late ProviderContainer container;
///
/// setUp(() async {
///   await setTestClock(fakeNow);
///   container = createProviderContainer();
/// });
///
/// tearDown(() async {
///   disposeProviderContainer(container);
///   await resetTestClock();
/// });
/// ```

/// 创建测试用 [ProviderContainer]，自动注入内存 DB 并注册核心插件。
///
/// 调用方负责在 [tearDown] 中调用 [disposeProviderContainer]。
ProviderContainer createProviderContainer({
  List<Override> overrides = const [],
}) {
  final db = AppDatabase.test();
  pluginRegistry.setDatabase(db);

  // 幂等注册 WeightPlugin（与 setUpTestDb 逻辑一致）
  bool hasWeight = false;
  for (final p in pluginRegistry.plugins) {
    if (p.id == 'weights') {
      hasWeight = true;
      break;
    }
  }
  if (!hasWeight) {
    pluginRegistry.register(WeightPlugin());
  }

  return ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      ...overrides,
    ],
  );
}

/// 获取注入到 [createProviderContainer] 的 DB 实例。
///
/// 在需要直接 seed 数据（如插入品种/鸟）时使用。
AppDatabase providerDb(ProviderContainer container) =>
    container.read(databaseProvider);

/// 销毁 [ProviderContainer] 并重置全局 [pluginRegistry]。
///
/// 注意：DB 关闭由 [databaseProvider] 的 onDispose 回调自动处理。
void disposeProviderContainer(ProviderContainer container) {
  container.dispose();
  pluginRegistry.reset();
}
