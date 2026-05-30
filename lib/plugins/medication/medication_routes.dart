import 'package:shelf_router/shelf_router.dart';
import '../../database/database.dart';
import '../../server/json_response.dart';
import 'medication_repository.dart';

/// Medication plugin server API routes.
/// Auto-mounted at /api/medication/ by the server.
Router createMedicationRoutes(AppDatabase db) {
  final router = Router();

  // GET /api/medication/ — list active medications for a bird
  router.get('/', (req) async {
    final birdId = req.url.queryParameters['birdId'];
    if (birdId != null) {
      final list = await db.getMedicationsByBird(int.parse(birdId));
      return jsonList(list.map((m) => {
        'id': m.id, 'birdId': m.birdId, 'drugName': m.drugName,
        'drugType': m.drugType, 'dosage': m.dosage,
        'timesPerDay': m.timesPerDay,
        'startDate': m.startDate.toIso8601String(),
        'endDate': m.endDate?.toIso8601String(),
        'active': m.active,
      }).toList());
    }
    return jsonResponse({'error': 'birdId required'});
  });

  // GET /api/medication/logs — today's medication tasks for a bird
  router.get('/logs', (req) async {
    final birdIdStr = req.url.queryParameters['birdId'];
    if (birdIdStr == null) return jsonError('birdId required');
    final list = await db.getTodayLogs(int.parse(birdIdStr));
    return jsonList(list.map((d) => {
      'id': d.log.id, 'medicationId': d.medication.id,
      'drugName': d.medication.drugName, 'dosage': d.medication.dosage,
      'scheduledTime': d.log.scheduledTime.toIso8601String(),
      'givenAt': d.log.givenAt?.toIso8601String(),
      'skipped': d.log.skipped, 'status': d.statusLabel,
      'timeLabel': d.timeLabel,
    }).toList());
  });

  // POST /api/medication/ — add a medication plan
  router.post('/', (req) async {
    final body = await parseBody(req);
    final birdId = body['birdId'] as int?;
    final drugName = body['drugName'] as String?;
    final dosage = body['dosage'] as String?;
    if (birdId == null || drugName == null || dosage == null) {
      return jsonError('birdId, drugName, dosage 不能为空');
    }
    final med = await db.addMedication(
      birdId: birdId,
      drugName: drugName,
      dosage: dosage,
      drugType: body['drugType'] as String? ?? '其他',
      timesPerDay: body['timesPerDay'] as int? ?? 1,
      endDate: body['endDate'] != null ? DateTime.parse(body['endDate'] as String) : null,
      notes: body['notes'] as String?,
    );
    return jsonItem({
      'id': med.id, 'drugName': med.drugName, 'dosage': med.dosage,
      'timesPerDay': med.timesPerDay,
    });
  });

  // POST /api/medication/logs/<id>/give — mark dose as given
  router.post('/logs/<id>', (req, String id) async {
    final body = await parseBody(req);
    final action = body['action'] as String?;
    if (action == 'give') {
      await db.giveMedication(int.parse(id), userId: body['userId'] as int?);
    } else if (action == 'skip') {
      await db.skipMedication(int.parse(id));
    }
    return jsonResponse({'success': true});
  });

  return router;
}
