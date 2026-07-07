import 'package:flutter_test/flutter_test.dart';
import '../lib/app.dart';

/// ── App 启动烟雾测试 ─────────────────────────────────────────────────────
///
/// 最低成本保障：验证 WeightNestApp 至少能构造，堵住"连 app 都起不来"的
/// 回归。不进行 pumpWidget，以避免触发 initState 中的平台插件调用
/// （ReceiveSharingIntent、MethodChannel 等）——这些需在 device 上测试。
///
/// 完整 widget 交互测试见 test/widgets/（待后续阶段补充）。

void main() {
  test('WeightNestApp can be constructed', () {
    expect(() => WeightNestApp(), returnsNormally);
  });
}
