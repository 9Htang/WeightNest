import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';
import '../utils/app_version.dart';
import '../repositories/species_repository.dart';
import '../repositories/room_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/bird_repository.dart';
import '../repositories/weight_repository.dart';
import '../repositories/task_repository.dart';
import 'json_response.dart';

Router createApiRouter(AppDatabase db) {
  final router = Router();

  // ====== 品种 ======
  router.get('/species', (req) async {
    final list = await db.getAllSpecies();
    return jsonList(list
        .map((s) => {
              'id': s.id, 'name': s.name,
              'nestlingEndDays': s.nestlingEndDays,
              'juvenileEndDays': s.juvenileEndDays,
              'adultWeighIntervalDays': s.adultWeighIntervalDays,
            }).toList());
  });

  router.post('/species', (req) async {
    final body = await parseBody(req);
    final name = body['name'] as String?;
    if (name == null || name.isEmpty) return jsonError('名称不能为空');
    final s = await db.createSpecies(
      name,
      nestlingEndDays: body['nestlingEndDays'] as int? ?? 45,
      juvenileEndDays: body['juvenileEndDays'] as int? ?? 120,
      adultWeighIntervalDays: body['adultWeighIntervalDays'] as int? ?? 7,
    );
    return jsonItem({'id': s.id, 'name': s.name});
  });

  // ====== 房间 ======
  router.get('/rooms', (req) async {
    final list = await db.getAllRooms();
    return jsonList(list
        .map((r) => {
              'id': r.id, 'name': r.name,
              'sortOrder': r.sortOrder,
              'assignedUserId': r.assignedUserId,
            }).toList());
  });

  router.post('/rooms', (req) async {
    final body = await parseBody(req);
    final name = body['name'] as String?;
    if (name == null || name.isEmpty) return jsonError('房间名不能为空');
    final r = await db.createRoom(name,
        assignedUserId: body['assignedUserId'] as int?);
    return jsonItem({'id': r.id, 'name': r.name, 'sortOrder': r.sortOrder});
  });

  router.put('/rooms/<id>', (req, String id) async {
    final body = await parseBody(req);
    final r = await db.updateRoom(int.parse(id),
        name: body['name'] as String?,
        sortOrder: body['sortOrder'] as int?,
        assignedUserId: body['assignedUserId'] as int?);
    return jsonItem({'id': r.id, 'name': r.name});
  });

  router.delete('/rooms/<id>', (req, String id) async {
    await db.removeRoom(int.parse(id));
    return jsonResponse({'success': true});
  });

  // ====== 鹦鹉 ======
  router.get('/birds', (req) async {
    final list = await db.getAllWithDetails();
    return jsonList(list
        .map((b) => {
              'id': b.bird.id, 'name': b.bird.name,
              'ringNumber': b.bird.ringNumber,
              'speciesId': b.bird.speciesId,
              'speciesName': b.species.name,
              'roomId': b.bird.roomId,
              'roomName': b.room?.name,
              'gender': b.bird.gender,
              'birthDate': b.bird.birthDate.toIso8601String(),
              'ageDays': b.ageDays, 'growthStage': b.growthStage,
              'sortOrder': b.bird.sortOrder, 'status': b.bird.status,
              'notes': b.bird.notes,
            }).toList());
  });

  router.get('/birds/<id>', (req, String id) async {
    final b = await db.getBirdById(int.parse(id));
    if (b == null) return jsonError('鹦鹉不存在', statusCode: 404);
    return jsonItem({
      'id': b.id, 'name': b.name, 'ringNumber': b.ringNumber,
      'speciesId': b.speciesId, 'roomId': b.roomId,
      'gender': b.gender,
      'birthDate': b.birthDate.toIso8601String(),
      'sortOrder': b.sortOrder, 'status': b.status, 'notes': b.notes,
    });
  });

  router.post('/birds', (req) async {
    final body = await parseBody(req);
    final name = body['name'] as String?;
    final speciesId = body['speciesId'] as int?;
    final birthDateStr = body['birthDate'] as String?;
    if (name == null || name.isEmpty) return jsonError('名称不能为空');
    if (speciesId == null) return jsonError('品种不能为空');
    if (birthDateStr == null) return jsonError('出生日期不能为空');
    final b = await db.createBird(
      name: name, speciesId: speciesId,
      birthDate: DateTime.parse(birthDateStr),
      roomId: body['roomId'] as int?,
      ringNumber: body['ringNumber'] as String?,
      gender: body['gender'] as String? ?? '未知',
      notes: body['notes'] as String?,
    );
    return jsonItem({'id': b.id, 'name': b.name});
  });

  router.put('/birds/<id>', (req, String id) async {
    final body = await parseBody(req);
    final b = await db.updateBird(int.parse(id),
        name: body['name'] as String?,
        speciesId: body['speciesId'] as int?,
        roomId: body['roomId'] as int?,
        birthDate: body['birthDate'] != null
            ? DateTime.parse(body['birthDate'] as String)
            : null,
        gender: body['gender'] as String?,
        sortOrder: body['sortOrder'] as int?,
        status: body['status'] as String?,
        notes: body['notes'] as String?);
    return jsonItem({'id': b.id, 'name': b.name});
  });

  router.delete('/birds/<id>', (req, String id) async {
    await db.removeBird(int.parse(id));
    return jsonResponse({'success': true});
  });

  // ====== 体重 ======
  router.get('/weights/<birdId>', (req, String birdId) async {
    final list = await db.getByBird(int.parse(birdId));
    return jsonList(list
        .map((w) => {
              'id': w.id, 'birdId': w.birdId,
              'weightG': w.weightG,
              'recordedAt': w.recordedAt.toIso8601String(),
              'recordedBy': w.recordedBy,
              'isFasting': w.isFasting, 'notes': w.notes,
            }).toList());
  });

  router.get('/weights/<birdId>/latest', (req, String birdId) async {
    final w = await db.getLatestByBird(int.parse(birdId));
    if (w == null) return jsonError('暂无记录', statusCode: 404);
    return jsonItem({
      'id': w.id, 'birdId': w.birdId, 'weightG': w.weightG,
      'recordedAt': w.recordedAt.toIso8601String(),
    });
  });

  router.post('/weights', (req) async {
    final body = await parseBody(req);
    final birdId = body['birdId'] as int?;
    final weightG = (body['weightG'] as num?)?.toDouble();
    final recordedAtStr = body['recordedAt'] as String?;
    if (birdId == null) return jsonError('鹦鹉ID不能为空');
    if (weightG == null) return jsonError('体重不能为空');
    final w = await db.addWeight(
      birdId: birdId, weightG: weightG,
      recordedAt: recordedAtStr != null
          ? DateTime.parse(recordedAtStr) : DateTime.now(),
      recordedBy: body['recordedBy'] as int?,
      isFasting: body['isFasting'] as bool? ?? false,
      notes: body['notes'] as String?,
    );
    return jsonItem({'id': w.id, 'birdId': w.birdId, 'weightG': w.weightG});
  });

  // ====== 任务 ======
  router.get('/tasks/today', (req) async {
    final userId = req.url.queryParameters['userId'];
    final list = await db.getTodayTasks(
        userId != null ? int.tryParse(userId) : null);
    return jsonList(list.map((t) => {
      'id': t.task.id, 'birdId': t.bird.id,
      'birdName': t.bird.name, 'speciesName': t.species?.name,
      'dueDate': t.task.dueDate.toIso8601String(), 'status': t.task.status,
    }).toList());
  });

  router.get('/tasks/overdue', (req) async {
    final list = await db.getOverdueTasks();
    return jsonList(list.map((t) => {
      'id': t.task.id, 'birdId': t.bird.id,
      'birdName': t.bird.name, 'status': t.task.status,
      'dueDate': t.task.dueDate.toIso8601String(),
    }).toList());
  });

  router.post('/tasks/<id>/complete', (req, String id) async {
    final body = await parseBody(req);
    final userId = body['userId'] as int?;
    if (userId == null) return jsonError('用户ID不能为空');
    await db.completeTask(int.parse(id), userId);
    return jsonResponse({'success': true});
  });

  router.post('/tasks/generate', (req) async {
    final count = await db.generateTodayTasks();
    return jsonResponse({'success': true, 'generated': count});
  });

  // ====== 用户 ======
  router.get('/users', (req) async {
    final list = await db.getAllUsers();
    return jsonList(list.map((u) => {
      'id': u.id, 'username': u.username,
      'displayName': u.displayName, 'role': u.role,
    }).toList());
  });

  // ====== 健康检查 ======
  router.get('/health', (req) =>
      jsonResponse({'status': 'ok', 'version': appVersion}));

  return router;
}
