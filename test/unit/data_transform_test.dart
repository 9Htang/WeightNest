import 'package:flutter_test/flutter_test.dart';
import '../../lib/utils/uuid.dart';

/// ── UUID 工具函数单元测试 ────────────────────────────────────────────────
///
/// 验证 genUuid / genShortId 的格式与唯一性。

void main() {
  group('genUuid', () {
    test('返回 UUID v4 格式（8-4-4-4-12 hex）', () {
      final id = genUuid();
      // v4 格式：xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx，y ∈ [89ab]
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
            .hasMatch(id),
        isTrue,
        reason: 'genUuid 应返回标准 UUID v4，实际: $id',
      );
    });

    test('多次调用返回不同值（唯一性）', () {
      final ids = <String>{};
      for (int i = 0; i < 1000; i++) {
        ids.add(genUuid());
      }
      expect(ids.length, 1000, reason: '1000 次 genUuid 应全部唯一');
    });
  });

  group('genShortId', () {
    test('长度为 8', () {
      final id = genShortId();
      expect(id.length, 8);
    });

    test('只含 hex 字符', () {
      final id = genShortId();
      expect(RegExp(r'^[0-9a-f]{8}$').hasMatch(id), isTrue,
          reason: 'genShortId 应为 8 位 hex，实际: $id');
    });

    test('多次调用返回不同值（唯一性）', () {
      final ids = <String>{};
      for (int i = 0; i < 1000; i++) {
        ids.add(genShortId());
      }
      // 短 ID 碰撞概率极低（16^8 ≈ 43 亿），1000 次应全部唯一
      expect(ids.length, 1000);
    });
  });
}
