import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/database/database.dart';
import '../../lib/providers.dart';
import '../../lib/repositories/bird_repository.dart';
import '../../lib/repositories/room_repository.dart';
import '../../lib/repositories/species_repository.dart';
import '../test_helpers/test_providers.dart';

/// ── 核心 FutureProvider 测试 ─────────────────────────────────────────────
///
/// 验证 providers.dart 中的核心 FutureProvider 在空库/有数据时的返回形状。

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    container = createProviderContainer();
  });

  tearDown(() {
    disposeProviderContainer(container);
  });

  group('allBirdsProvider', () {
    test('空库 → 空列表', () async {
      final birds = await container.read(allBirdsProvider.future);
      expect(birds, isEmpty);
    });

    test('有鸟 → 返回列表', () async {
      final db = providerDb(container);
      final species = await db.createSpecies('虎皮');
      await db.createBird(
        name: '小蓝',
        speciesId: species.id,
        birthDate: DateTime(2024, 1, 1),
      );
      // 重新读取（invalidate 触发刷新）
      container.invalidate(allBirdsProvider);
      final birds = await container.read(allBirdsProvider.future);
      expect(birds.length, 1);
      expect(birds.first.bird.name, '小蓝');
    });
  });

  group('allSpeciesProvider', () {
    test('空库 → 空列表', () async {
      final species = await container.read(allSpeciesProvider.future);
      expect(species, isEmpty);
    });

    test('有品种 → 返回列表', () async {
      final db = providerDb(container);
      await db.createSpecies('玄凤');
      await db.createSpecies('牡丹');
      container.invalidate(allSpeciesProvider);
      final species = await container.read(allSpeciesProvider.future);
      expect(species.length, 2);
    });
  });

  group('allRoomsProvider', () {
    test('空库 → 空列表', () async {
      final rooms = await container.read(allRoomsProvider.future);
      expect(rooms, isEmpty);
    });

    test('有房间 → 返回列表', () async {
      final db = providerDb(container);
      await db.createRoom('房间A');
      await db.createRoom('房间B');
      container.invalidate(allRoomsProvider);
      final rooms = await container.read(allRoomsProvider.future);
      expect(rooms.length, 2);
    });
  });
}
