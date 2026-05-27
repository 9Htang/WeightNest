import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:uuid/uuid.dart';
import 'package:postgres/postgres.dart';

const _uuid = Uuid();
final _validTokens = <String>{};
String _serverPin = '1234';
late final Connection _db;

void main(List<String> args) async {
  final port = int.tryParse(args.isNotEmpty ? args[0] : '8080') ?? 8080;
  if (args.length > 1) _serverPin = args[1];
  final pgHost = args.length > 2 ? args[2] : 'localhost';

  _db = await Connection.open(
    Endpoint(
      host: pgHost,
      database: 'weightnest',
      username: 'postgres',
      password: 'postgres',
    ),
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );

  await _initDb();

  final app = Router()
    ..post('/auth/connect', _handleConnect)
    ..post('/sync', _handleSync)
    ..get('/changes', _handleChanges)
    ..get('/health', (_) => Response.ok('{"status":"ok"}'));

  final handler = Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addHandler(app.call);

  await io.serve(handler, '0.0.0.0', port);
  final ip = await _localIp();
  print('🦜 WeightNest 服务器已启动 → http://$ip:$port');
  print('🔑 PIN: $_serverPin');
}

Future<String> _localIp() async {
  for (final iface in await NetworkInterface.list()) {
    for (final addr in iface.addresses) {
      if (addr.type == InternetAddressType.IPv4 &&
          (addr.address.startsWith('192.168.') || addr.address.startsWith('10.'))) {
        return addr.address;
      }
    }
  }
  return '127.0.0.1';
}

// ─── 数据库初始化 ───

Future<void> _initDb() async {
  await _db.execute('''
    CREATE TABLE IF NOT EXISTS species (
      id SERIAL PRIMARY KEY, uuid TEXT UNIQUE NOT NULL, name TEXT NOT NULL,
      nestling_end_days INT DEFAULT 45, juvenile_end_days INT DEFAULT 120,
      adult_weigh_interval_days INT DEFAULT 7,
      created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW(),
      deleted_at TIMESTAMP
    )
  ''');
  await _db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY, uuid TEXT UNIQUE NOT NULL, username TEXT NOT NULL,
      display_name TEXT NOT NULL, password_hash TEXT DEFAULT '', role TEXT DEFAULT 'keeper',
      created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW(),
      deleted_at TIMESTAMP
    )
  ''');
  await _db.execute('''
    CREATE TABLE IF NOT EXISTS rooms (
      id SERIAL PRIMARY KEY, uuid TEXT UNIQUE NOT NULL, name TEXT NOT NULL,
      sort_order INT DEFAULT 0, assigned_user_id INT,
      created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW(),
      deleted_at TIMESTAMP
    )
  ''');
  await _db.execute('''
    CREATE TABLE IF NOT EXISTS birds (
      id SERIAL PRIMARY KEY, uuid TEXT UNIQUE NOT NULL, name TEXT NOT NULL,
      ring_number TEXT, species_id INT NOT NULL, room_id INT,
      birth_date TIMESTAMP NOT NULL, gender TEXT DEFAULT '未知',
      sort_order INT DEFAULT 0, status TEXT DEFAULT '正常', notes TEXT,
      created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW(),
      deleted_at TIMESTAMP
    )
  ''');
  await _db.execute('''
    CREATE TABLE IF NOT EXISTS weight_records (
      id SERIAL PRIMARY KEY, uuid TEXT UNIQUE NOT NULL, bird_id INT NOT NULL,
      weight_g REAL NOT NULL, recorded_at TIMESTAMP NOT NULL,
      recorded_by INT, is_fasting BOOLEAN DEFAULT TRUE, notes TEXT,
      created_at TIMESTAMP DEFAULT NOW(), updated_at TIMESTAMP DEFAULT NOW()
    )
  ''');
  await _db.execute('''
    CREATE TABLE IF NOT EXISTS synced_ops (
      op_id TEXT UNIQUE NOT NULL, processed_at TIMESTAMP DEFAULT NOW()
    )
  ''');
  await _db.execute('''
    CREATE TABLE IF NOT EXISTS change_log (
      id SERIAL PRIMARY KEY, entity_type TEXT NOT NULL, entity_uuid TEXT NOT NULL,
      data JSONB NOT NULL, created_at TIMESTAMP DEFAULT NOW()
    )
  ''');
  await _db.execute('''
    CREATE TABLE IF NOT EXISTS devices (
      device_id TEXT PRIMARY KEY, connected_at TIMESTAMP DEFAULT NOW()
    )
  ''');
}

// ─── 认证 ───

Future<Response> _handleConnect(Request req) async {
  final body = jsonDecode(await req.readAsString());
  final pin = body['pin'] as String?;
  final deviceId = body['deviceId'] as String?;
  if (pin != _serverPin) return Response.forbidden('{"error":"PIN 错误"}');
  final token = _uuid.v4();
  _validTokens.add(token);
  print('Auth: device=$deviceId token=$token');
  await _db.execute(
    Sql.named('INSERT INTO devices (device_id, connected_at) VALUES (@d, NOW()) '
        'ON CONFLICT (device_id) DO UPDATE SET connected_at = NOW()'),
    parameters: {'d': deviceId ?? 'unknown'},
  );
  return Response.ok(jsonEncode({'token': token}));
}

// ─── 同步 ───

Future<Response> _handleSync(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{"error":"auth"}');
  final ops = jsonDecode(await req.readAsString()) as List;
  final successOps = <String>[];

  for (final op in ops) {
    final opId = op['opId'] as String;
    try {
      final r = await _db.execute(Sql.named('SELECT 1 FROM synced_ops WHERE op_id=@id'),
          parameters: {'id': opId});
      if (r.isNotEmpty) { successOps.add(opId); continue; }
      await _applyOp(op);
      await _db.execute(Sql.named('INSERT INTO synced_ops (op_id) VALUES (@id)'),
          parameters: {'id': opId});
      successOps.add(opId);
    } catch (e) { print('同步失败 $opId: $e'); }
  }
  return Response.ok(jsonEncode({'successOps': successOps}));
}

Future<void> _applyOp(Map<String, dynamic> op) async {
  final action = op['action'] as String;
  final entityType = op['entityType'] as String;
  final entityUuid = op['entityUuid'] as String;
  final payload = op['payload'] as Map<String, dynamic>? ?? {};
  final p = (String k) => payload[k];

  switch (action) {
    case 'add_weight':
      await _db.execute(Sql.named(
          'INSERT INTO weight_records (uuid,bird_id,weight_g,recorded_at,recorded_by,is_fasting) '
          'VALUES (@a,@b,@c,@d,@e,@f)'),
        parameters: {'a': entityUuid, 'b': p('birdId'), 'c': p('weightG'),
          'd': DateTime.parse(p('recordedAt')), 'e': op['userId'], 'f': p('isFasting') ?? true});
      break;
    case 'create_bird':
      await _db.execute(Sql.named(
          'INSERT INTO birds (uuid,name,species_id,room_id,birth_date,gender,ring_number) '
          'VALUES (@a,@b,@c,@d,@e,@f,@g)'),
        parameters: {'a': entityUuid, 'b': p('name'), 'c': p('speciesId') ?? 1,
          'd': p('roomId'), 'e': DateTime.parse(p('birthDate')),
          'f': p('gender') ?? '未知', 'g': p('ringNumber')});
      break;
    case 'update_bird':
      await _db.execute(Sql.named(
          'UPDATE birds SET name=@n, ring_number=@r, updated_at=NOW() WHERE id=@id'),
        parameters: {'n': p('name'), 'r': p('ringNumber'), 'id': p('id')});
      break;
    case 'create_room':
      await _db.execute(Sql.named('INSERT INTO rooms (uuid,name) VALUES (@a,@b)'),
        parameters: {'a': entityUuid, 'b': p('name')});
      break;
    case 'create_species':
      await _db.execute(Sql.named('INSERT INTO species (uuid,name) VALUES (@a,@b)'),
        parameters: {'a': entityUuid, 'b': p('name')});
      break;
    case 'create_user':
      await _db.execute(Sql.named(
          'INSERT INTO users (uuid,username,display_name,role) VALUES (@a,@b,@c,@d)'),
        parameters: {'a': entityUuid, 'b': p('username'), 'c': p('displayName'),
          'd': p('role') ?? 'keeper'});
      break;
  }
  await _db.execute(Sql.named(
      'INSERT INTO change_log (entity_type,entity_uuid,data) VALUES (@a,@b,@c)'),
    parameters: {'a': entityType, 'b': entityUuid, 'c': jsonEncode(payload)});
}

// ─── 增量拉取 ───

Future<Response> _handleChanges(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{}');
  final since = int.tryParse(req.url.queryParameters['since'] ?? '0') ?? 0;
  final sinceDate = DateTime.fromMillisecondsSinceEpoch(since);

  final result = await _db.execute(Sql.named(
      'SELECT entity_type,entity_uuid,data,created_at FROM change_log '
      'WHERE created_at>@s ORDER BY created_at ASC LIMIT 200'),
    parameters: {'s': sinceDate});

  final changes = <Map<String, dynamic>>[];
  for (final row in result) {
    changes.add({
      'entityType': row[0], 'entityUuid': row[1],
      'data': row[2] is Map ? row[2] : jsonDecode(row[2] as String),
      'createdAt': (row[3] as DateTime).toIso8601String(),
    });
  }
  return Response.ok(jsonEncode({'changes': changes}));
}

bool _checkAuth(Request req) {
  final auth = req.headers['Authorization'] ?? '';
  final token = auth.replaceFirst('Bearer ', '');
  final ok = _validTokens.contains(token);
  print('Auth check: auth=[$auth] token=[$token] ok=$ok validCount=${_validTokens.length}');
  return ok;
}
