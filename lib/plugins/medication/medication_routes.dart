import 'package:shelf_router/shelf_router.dart';
import '../../server/json_response.dart';

/// Medication plugin server API routes.
/// Auto-mounted at /api/medication/ by the server.
Router createMedicationRoutes() {
  final router = Router();

  // GET /api/medication/ — list medications
  router.get('/', (req) async {
    // TODO: wire to real database via Dependency Injection
    final medications = <Map<String, dynamic>>[];
    return jsonResponse({'medications': medications, 'count': 0});
  });

  // POST /api/medication/ — add a medication record
  router.post('/', (req) async {
    final body = await parseBody(req);
    final birdId = body['birdId'] as int?;
    final drugName = body['drugName'] as String?;
    if (birdId == null || drugName == null) {
      return jsonError('birdId 和 drugName 不能为空');
    }
    // TODO: write to database
    return jsonResponse({'success': true, 'message': '$drugName 喂药记录已添加'});
  });

  return router;
}
