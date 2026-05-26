import 'package:drift/drift.dart';
import '../database/database.dart';

extension UserRepository on AppDatabase {
  Future<List<User>> getAll() => select(users).get();

  Future<User?> getById(int id) =>
      (select(users)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<User?> getByUsername(String username) =>
      (select(users)..where((t) => t.username.equals(username))).getSingleOrNull();

  Future<User> create(String username, String displayName, String passwordHash,
      {String role = 'keeper'}) async {
    await into(users).insert(UsersCompanion.insert(
      username: username,
      displayName: displayName,
      passwordHash: passwordHash,
      role: Value(role),
    ));
    final rows = await customSelect('SELECT last_insert_rowid() as id').get();
    return (await getById(rows.first.read<int>('id')))!;
  }

  Future<User> updateFields(int id, {String? displayName, String? role}) async {
    final list = await (update(users)..where((t) => t.id.equals(id)))
        .writeReturning(UsersCompanion(
      displayName: displayName != null ? Value(displayName) : const Value.absent(),
      role: role != null ? Value(role) : const Value.absent(),
    ));
    return list.first;
  }

  Future<void> remove(int id) =>
      (delete(users)..where((t) => t.id.equals(id))).go();
}
