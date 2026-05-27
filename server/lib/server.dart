import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
final _validTokens = <String>{};
String _serverPin = '1234'; // 默认 PIN，启动时可通过参数修改

void main(List<String> args) async {
  final port = int.tryParse(args.isNotEmpty ? args[0] : '8080') ?? 8080;
  if (args.length > 1) _serverPin = args[1];

  // 连接 PostgreSQL
  final conn = await Connection.open(
    Endpoint(
      host: 'localhost',
      database: 'weightnest',
      username: 'postgres',
      password: 'postgres',
    ),
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );

  // 建表（幂等）
  await _initDb(conn);

  // 路由
  final app = Router()
    ..post('/auth/connect', (req) => _handleConnect(req, conn))
    ..post('/sync', (req) => _handleSync(req, conn))
    ..get('/changes', (req) => _handleChanges(req, conn))
    ..get('/health', (_) => Response.ok('{"status":"ok"}'));

  final handler = Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addHandler(app.call);

  await io.serve(handler, '0.0.0.0', port);
  final ip = await _localIp();
  print('🦜 WeightNest 服务器已启动 → http://$ip:$port');
  print('🔑 服务器 PIN: $_serverPin');
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

Future<void> _initDb(Connection conn) async {
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS species (
      id SERIAL PRIMARY KEY,
      uuid TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      nestling_end_days INT DEFAULT 45,
      juvenile_end_days INT DEFAULT 120,
      adult_weigh_interval_days INT DEFAULT 7,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW(),
      deleted_at TIMESTAMP
    )
  ''');

  await conn.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      uuid TEXT UNIQUE NOT NULL,
      username TEXT NOT NULL,
      display_name TEXT NOT NULL,
      password_hash TEXT DEFAULT '',
      role TEXT DEFAULT 'keeper',
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW(),
      deleted_at TIMESTAMP
    )
  ''');

  await conn.execute('''
    CREATE TABLE IF NOT EXISTS rooms (
      id SERIAL PRIMARY KEY,
      uuid TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      sort_order INT DEFAULT 0,
      assigned_user_id INT,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW(),
      deleted_at TIMESTAMP
    )
  ''');

  await conn.execute('''
    CREATE TABLE IF NOT EXISTS birds (
      id SERIAL PRIMARY KEY,
      uuid TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      ring_number TEXT,
      species_id INT NOT NULL,
      room_id INT,
      birth_date TIMESTAMP NOT NULL,
      gender TEXT DEFAULT '未知',
      sort_order INT DEFAULT 0,
      status TEXT DEFAULT '正常',
      notes TEXT,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW(),
      deleted_at TIMESTAMP
    )
  ''');

  await conn.execute('''
    CREATE TABLE IF NOT EXISTS weight_records (
      id SERIAL PRIMARY KEY,
      uuid TEXT UNIQUE NOT NULL,
      bird_id INT NOT NULL,
      weight_g REAL NOT NULL,
      recorded_at TIMESTAMP NOT NULL,
      recorded_by INT,
      is_fasting BOOLEAN DEFAULT TRUE,
      notes TEXT,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    )
  ''');

  // 已处理操作日志表（幂等去重）
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS synced_ops (
      op_id TEXT UNIQUE NOT NULL,
      processed_at TIMESTAMP DEFAULT NOW()
    )
  ''');

  // 变更日志表（供增量拉取）
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS change_log (
      id SERIAL PRIMARY KEY,
      entity_type TEXT NOT NULL,
      entity_uuid TEXT NOT NULL,
      data JSONB NOT NULL,
      created_at TIMESTAMP DEFAULT NOW()
    )
  ''');
}

// ─── 认证 ───

Future<Response> _handleConnect(Request req, Connection conn) async {
  final body = jsonDecode(await req.readAsString());
  final pin = body['pin'] as String?;
  final deviceId = body['deviceId'] as String?;

  if (pin != _serverPin) {
    return Response.forbidden('{"error":"PIN 错误"}');
  }

  final token = _uuid.v4();
  _validTokens.add(token);

  // 记录设备
  await conn.execute(
    'INSERT INTO devices (device_id, connected_at) VALUES (@d, NOW()) '
    'ON CONFLICT (device_id) DO UPDATE SET connected_at = NOW()',
    parameters: {'d': deviceId ?? 'unknown'},
  );

  return Response.ok(jsonEncode({'token': token}));
}

// ─── 同步操作 ───

Future<Response> _handleSync(Request req, Connection conn) async {
  if (!_checkAuth(req)) return Response.forbidden('{}');
  final ops = jsonDecode(await req.readAsString()) as List;
  final successOps = <String>[];

  for (final op in ops) {
    final opId = op['opId'] as String;
    try {
      // 幂等检查
      final existing = await conn.execute(
        'SELECT 1 FROM synced_ops WHERE op_id = @opId',
        parameters: {'opId': opId},
      );
      if (existing.isEmpty) {
        await _applyOp(conn, op);
        await conn.execute(
          'INSERT INTO synced_ops (op_id) VALUES (@opId)',
          parameters: {'opId': opId},
        );
      }
      successOps.add(opId);
    } catch (e) {
      print('同步失败 $opId: $e');
    }
  }

  return Response.ok(jsonEncode({'successOps': successOps}));
}

Future<void> _applyOp(Connection conn, Map<String, dynamic> op) async {
  final action = op['action'] as String;
  final entityType = op['entityType'] as String;
  final entityUuid = op['entityUuid'] as String;
  final payload = op['payload'] as Map<String, dynamic>? ?? {};

  switch (action) {
    case 'add_weight':
      await conn.execute('''
        INSERT INTO weight_records (uuid, bird_id, weight_g, recorded_at, recorded_by, is_fasting)
        VALUES (@uuid, @birdId, @weightG, @recordedAt, @recordedBy, @isFasting)
      ''', parameters: {
        'uuid': entityUuid,
        'birdId': payload['birdId'],
        'weightG': payload['weightG'],
        'recordedAt': DateTime.parse(payload['recordedAt']),
        'recordedBy': op['userId'],
        'isFasting': payload['isFasting'] ?? true,
      });
      break;

    case 'create_bird':
      await conn.execute('''
        INSERT INTO birds (uuid, name, species_id, room_id, birth_date, gender, ring_number)
        VALUES (@uuid, @name, @speciesId, @roomId, @birthDate, @gender, @ringNumber)
      ''', parameters: {
        'uuid': entityUuid,
        'name': payload['name'],
        'speciesId': payload['speciesId'] ?? 1,
        'roomId': payload['roomId'],
        'birthDate': DateTime.parse(payload['birthDate']),
        'gender': payload['gender'] ?? '未知',
        'ringNumber': payload['ringNumber'],
      });
      break;

    case 'update_bird':
      // Last Write Wins
      await conn.execute('''
        UPDATE birds SET name = @name, ring_number = @ring, updated_at = NOW()
        WHERE id = @id
      ''', parameters: {
        'id': payload['id'],
        'name': payload['name'],
        'ring': payload['ringNumber'],
      });
      break;

    case 'create_room':
      await conn.execute(
        'INSERT INTO rooms (uuid, name) VALUES (@uuid, @name)',
        parameters: {'uuid': entityUuid, 'name': payload['name']},
      );
      break;

    case 'create_species':
      await conn.execute(
        'INSERT INTO species (uuid, name) VALUES (@uuid, @name)',
        parameters: {'uuid': entityUuid, 'name': payload['name']},
      );
      break;

    case 'create_user':
      await conn.execute('''
        INSERT INTO users (uuid, username, display_name, role)
        VALUES (@uuid, @username, @displayName, @role)
      ''', parameters: {
        'uuid': entityUuid,
        'username': payload['username'],
        'displayName': payload['displayName'],
        'role': payload['role'] ?? 'keeper',
      });
      break;
  }

  // 写入变更日志（供增量拉取）
  await conn.execute('''
    INSERT INTO change_log (entity_type, entity_uuid, data)
    VALUES (@type, @uuid, @data)
  ''', parameters: {
    'type': entityType,
    'uuid': entityUuid,
    'data': jsonEncode(payload),
  });
}

// ─── 增量拉取 ───

Future<Response> _handleChanges(Request req, Connection conn) async {
  if (!_checkAuth(req)) return Response.forbidden('{}');
  final since = int.tryParse(req.url.queryParameters['since'] ?? '0') ?? 0;
  final sinceDate = DateTime.fromMillisecondsSinceEpoch(since);

  final result = await conn.execute('''
    SELECT entity_type, entity_uuid, data, created_at
    FROM change_log
    WHERE created_at > @since
    ORDER BY created_at ASC
    LIMIT 200
  ''', parameters: {'since': sinceDate});

  final changes = <Map<String, dynamic>>[];
  for (final row in result) {
    changes.add({
      'entityType': row[0],
      'entityUuid': row[1],
      'data': row[2] is Map ? row[2] : jsonDecode(row[2] as String),
      'createdAt': (row[3] as DateTime).toIso8601String(),
    });
  }

  return Response.ok(jsonEncode({'changes': changes}));
}

// ─── 工具 ───

bool _checkAuth(Request req) {
  final auth = req.headers['Authorization'] ?? '';
  final token = auth.replaceFirst('Bearer ', '');
  return _validTokens.contains(token);
}
