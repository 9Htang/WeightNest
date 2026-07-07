import 'package:flutter_test/flutter_test.dart';
import '../../lib/database/database.dart';
import '../../lib/repositories/user_repository.dart';
import '../test_helpers/test_clock.dart';
import '../test_helpers/test_factories.dart';

/// ── UserRepository 测试 ──────────────────────────────────────────────────
///
/// 验证用户 CRUD：创建、查询、更新、删除、用户名查找。

final _fakeNow = DateTime(2025, 6, 15, 12, 0, 0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    await setTestClockWithPrefs(_fakeNow);
    db = await setUpTestDb();
  });

  tearDown(() async {
    await tearDownTestDb(db);
    await resetTestClock();
  });

  group('createUser', () {
    test('创建用户并返回（含自增 id）', () async {
      final user = await db.createUser('admin', '管理员', 'hash123');
      expect(user.id, greaterThan(0));
      expect(user.username, 'admin');
      expect(user.displayName, '管理员');
      expect(user.passwordHash, 'hash123');
      expect(user.role, 'keeper');
    });

    test('自定义角色', () async {
      final user =
          await db.createUser('manager', '经理', 'hash', role: 'manager');
      expect(user.role, 'manager');
    });
  });

  group('getAllUsers / getUserById', () {
    test('空表返回空列表', () async {
      expect(await db.getAllUsers(), isEmpty);
    });

    test('创建后可查询到', () async {
      final created = await db.createUser('admin', '管理员', 'hash');
      final all = await db.getAllUsers();
      expect(all.length, 1);
      expect(all.first.id, created.id);

      final byId = await db.getUserById(created.id);
      expect(byId, isNotNull);
      expect(byId!.username, 'admin');
    });

    test('不存在的 id → null', () async {
      expect(await db.getUserById(99999), isNull);
    });
  });

  group('getByUsername', () {
    test('按用户名查找', () async {
      await db.createUser('admin', '管理员', 'hash');
      final user = await db.getByUsername('admin');
      expect(user, isNotNull);
      expect(user!.displayName, '管理员');
    });

    test('不存在的用户名 → null', () async {
      expect(await db.getByUsername('nobody'), isNull);
    });
  });

  group('updateUser', () {
    test('更新 displayName', () async {
      final created = await db.createUser('admin', '管理员', 'hash');
      final updated = await db.updateUser(created.id, displayName: '新名字');
      expect(updated.displayName, '新名字');
    });

    test('更新 role', () async {
      final created = await db.createUser('admin', '管理员', 'hash');
      final updated = await db.updateUser(created.id, role: 'manager');
      expect(updated.role, 'manager');
    });

    test('isActive=false → 设置 deletedAt', () async {
      final created = await db.createUser('admin', '管理员', 'hash');
      final updated = await db.updateUser(created.id, isActive: false);
      expect(updated.deletedAt, isNotNull);
    });

    test('isActive=true → 清除 deletedAt', () async {
      final created = await db.createUser('admin', '管理员', 'hash');
      await db.updateUser(created.id, isActive: false);
      final reactivated = await db.updateUser(created.id, isActive: true);
      expect(reactivated.deletedAt, isNull);
    });
  });

  group('removeUser', () {
    test('删除后查询不到', () async {
      final created = await db.createUser('admin', '管理员', 'hash');
      await db.removeUser(created.id);
      expect(await db.getUserById(created.id), isNull);
    });

    test('删除不存在的 id → 不抛异常', () async {
      await db.removeUser(99999);
    });
  });
}
