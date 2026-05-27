import 'package:drift/drift.dart';
import '../database/database.dart';
import '../utils/uuid.dart';

extension UserRepository on AppDatabase {
  Future<List<User>> getAllUsers() => select(users).get();

  Future<User?> getUserById(int id) =>
      (select(users)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<User?> getByUsername(String username) =>
      (select(users)..where((t) => t.username.equals(username))).getSingleOrNull();

  Future<User> createUser(String username, String displayName, String passwordHash,
      {String role = 'keeper'}) async {
    await into(users).insert(UsersCompanion.insert(
      uuid: genUuid(),
      username: username,
      displayName: displayName,
      passwordHash: passwordHash,
      role: Value(role),
    ));
    final rows = await customSelect('SELECT last_insert_rowid() as id').get();
    return (await getUserById(rows.first.read<int>('id')))!;
  }

  Future<User> updateUser(int id, {String? displayName, String? role}) async {
    final list = await (update(users)..where((t) => t.id.equals(id)))
        .writeReturning(UsersCompanion(
      displayName: displayName != null ? Value(displayName) : const Value.absent(),
      role: role != null ? Value(role) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    ));
    return list.first;
  }

  Future<void> removeUser(int id) =>
      (delete(users)..where((t) => t.id.equals(id))).go();
}
