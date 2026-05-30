import 'package:shelf_router/shelf_router.dart';
import '../../database/database.dart';
import '../../repositories/weight_repository.dart';
import '../../server/json_response.dart';

/// Weight recording plugin server API.
/// Auto-mounted at /api/weight/ by the server.
Router createWeightRoutes(AppDatabase db) {
  final router = Router();

  // GET /api/weight/<birdId> — list weights for a bird
  router.get('/<birdId>', (req, String birdId) async {
    final list = await db.getByBird(int.parse(birdId));
    return jsonList(list
        .map((w) => {
              'id': w.id,
              'birdId': w.birdId,
              'weightG': w.weightG,
              'recordedAt': w.recordedAt.toIso8601String(),
              'recordedBy': w.recordedBy,
              'isFasting': w.isFasting,
              'notes': w.notes,
            })
        .toList());
  });

  // GET /api/weight/<birdId>/latest — latest weight
  router.get('/<birdId>/latest', (req, String birdId) async {
    final w = await db.getLatestByBird(int.parse(birdId));
    if (w == null) return jsonError('暂无记录', statusCode: 404);
    return jsonItem({
      'id': w.id,
      'birdId': w.birdId,
      'weightG': w.weightG,
      'recordedAt': w.recordedAt.toIso8601String(),
    });
  });

  // POST /api/weight/ — add a weight record
  router.post('/', (req) async {
    final body = await parseBody(req);
    final birdId = body['birdId'] as int?;
    final weightG = (body['weightG'] as num?)?.toDouble();
    final recordedAtStr = body['recordedAt'] as String?;
    if (birdId == null) return jsonError('鹦鹉ID不能为空');
    if (weightG == null) return jsonError('体重不能为空');
    final w = await db.addWeight(
      birdId: birdId,
      weightG: weightG,
      recordedAt: recordedAtStr != null ? DateTime.parse(recordedAtStr) : DateTime.now(),
      recordedBy: body['recordedBy'] as int?,
      isFasting: body['isFasting'] as bool? ?? false,
      notes: body['notes'] as String?,
    );
    return jsonItem({'id': w.id, 'birdId': w.birdId, 'weightG': w.weightG});
  });

  return router;
}
