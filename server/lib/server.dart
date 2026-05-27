import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:uuid/uuid.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;

const _uuid = Uuid();
final _validTokens = <String>{};
String _serverPin = '1234';
late final Database _db;

void main(List<String> args) async {
  final port = int.tryParse(args.isNotEmpty ? args[0] : '8080') ?? 8080;
  if (args.length > 1) _serverPin = args[1];

  // SQLite 数据库
  final dbPath = p.join(Directory.current.path, 'weightnest_server.db');
  _db = sqlite3.open(dbPath);

  _initDb();

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

void _initDb() {
  _db.execute('PRAGMA journal_mode=WAL');

  _db.execute('''
    CREATE TABLE IF NOT EXISTS species (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uuid TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      nestling_end_days INTEGER DEFAULT 45,
      juvenile_end_days INTEGER DEFAULT 120,
      adult_weigh_interval_days INTEGER DEFAULT 7,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now')),
      deleted_at TEXT
    )
  ''');

  _db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uuid TEXT UNIQUE NOT NULL,
      username TEXT NOT NULL,
      display_name TEXT NOT NULL,
      password_hash TEXT DEFAULT '',
      role TEXT DEFAULT 'keeper',
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now')),
      deleted_at TEXT
    )
  ''');

  _db.execute('''
    CREATE TABLE IF NOT EXISTS rooms (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uuid TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      sort_order INTEGER DEFAULT 0,
      assigned_user_id INTEGER,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now')),
      deleted_at TEXT
    )
  ''');

  _db.execute('''
    CREATE TABLE IF NOT EXISTS birds (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uuid TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      ring_number TEXT,
      species_id INTEGER NOT NULL,
      room_id INTEGER,
      birth_date TEXT NOT NULL,
      gender TEXT DEFAULT '未知',
      sort_order INTEGER DEFAULT 0,
      status TEXT DEFAULT '正常',
      notes TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now')),
      deleted_at TEXT
    )
  ''');

  _db.execute('''
    CREATE TABLE IF NOT EXISTS weight_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uuid TEXT UNIQUE NOT NULL,
      bird_id INTEGER NOT NULL,
      weight_g REAL NOT NULL,
      recorded_at TEXT NOT NULL,
      recorded_by INTEGER,
      is_fasting INTEGER DEFAULT 1,
      notes TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now'))
    )
  ''');

  _db.execute('''
    CREATE TABLE IF NOT EXISTS synced_ops (
      op_id TEXT UNIQUE NOT NULL,
      processed_at TEXT DEFAULT (datetime('now'))
    )
  ''');

  _db.execute('''
    CREATE TABLE IF NOT EXISTS change_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      entity_type TEXT NOT NULL,
      entity_uuid TEXT NOT NULL,
      data TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now'))
    )
  ''');

  _db.execute('''
    CREATE TABLE IF NOT EXISTS devices (
      device_id TEXT PRIMARY KEY,
      connected_at TEXT DEFAULT (datetime('now'))
    )
  ''');
}

// ─── 认证 ───

Future<Response> _handleConnect(Request req) async {
  final body = jsonDecode(await req.readAsString());
  final pin = body['pin'] as String?;
  final deviceId = body['deviceId'] as String?;

  if (pin != _serverPin) {
    return Response.forbidden('{"error":"PIN 错误"}');
  }

  final token = _uuid.v4();
  _validTokens.add(token);

  _db.execute(
    'INSERT OR REPLACE INTO devices (device_id, connected_at) VALUES (?, datetime(\'now\'))',
    [deviceId ?? 'unknown'],
  );

  return Response.ok(jsonEncode({'token': token}));
}

// ─── 同步操作 ───

Future<Response> _handleSync(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{}');
  final ops = jsonDecode(await req.readAsString()) as List;
  final successOps = <String>[];

  for (final op in ops) {
    final opId = op['opId'] as String;
    try {
      final existing = _db.select('SELECT 1 FROM synced_ops WHERE op_id = ?', [opId]);
      if (existing.isNotEmpty) {
        successOps.add(opId);
        continue;
      }

      _applyOp(op);
      _db.execute('INSERT INTO synced_ops (op_id) VALUES (?)', [opId]);
      successOps.add(opId);
    } catch (e) {
      print('同步失败 $opId: $e');
    }
  }

  return Response.ok(jsonEncode({'successOps': successOps}));
}

void _applyOp(Map<String, dynamic> op) {
  final action = op['action'] as String;
  final entityType = op['entityType'] as String;
  final entityUuid = op['entityUuid'] as String;
  final payload = op['payload'] as Map<String, dynamic>? ?? {};

  switch (action) {
    case 'add_weight':
      _db.execute('''
        INSERT INTO weight_records (uuid, bird_id, weight_g, recorded_at, recorded_by, is_fasting)
        VALUES (?, ?, ?, ?, ?, ?)
      ''', [
        entityUuid,
        payload['birdId'],
        payload['weightG'],
        payload['recordedAt'],
        op['userId'],
        payload['isFasting'] == true ? 1 : 0,
      ]);
      break;

    case 'create_bird':
      _db.execute('''
        INSERT INTO birds (uuid, name, species_id, room_id, birth_date, gender, ring_number)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      ''', [
        entityUuid, payload['name'], payload['speciesId'] ?? 1,
        payload['roomId'], payload['birthDate'],
        payload['gender'] ?? '未知', payload['ringNumber'],
      ]);
      break;

    case 'update_bird':
      _db.execute('UPDATE birds SET name = ?, ring_number = ?, updated_at = datetime(\'now\') WHERE id = ?',
          [payload['name'], payload['ringNumber'], payload['id']]);
      break;

    case 'create_room':
      _db.execute('INSERT INTO rooms (uuid, name) VALUES (?, ?)',
          [entityUuid, payload['name']]);
      break;

    case 'create_species':
      _db.execute('INSERT INTO species (uuid, name) VALUES (?, ?)',
          [entityUuid, payload['name']]);
      break;

    case 'create_user':
      _db.execute('INSERT INTO users (uuid, username, display_name, role) VALUES (?, ?, ?, ?)',
          [entityUuid, payload['username'], payload['displayName'], payload['role'] ?? 'keeper']);
      break;
  }

  // 写入变更日志
  _db.execute('INSERT INTO change_log (entity_type, entity_uuid, data) VALUES (?, ?, ?)',
      [entityType, entityUuid, jsonEncode(payload)]);
}

// ─── 增量拉取 ───

Future<Response> _handleChanges(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{}');
  final since = int.tryParse(req.url.queryParameters['since'] ?? '0') ?? 0;
  final sinceDate = DateTime.fromMillisecondsSinceEpoch(since).toIso8601String();

  final result = _db.select('''
    SELECT entity_type, entity_uuid, data, created_at
    FROM change_log
    WHERE created_at > ?
    ORDER BY created_at ASC
    LIMIT 200
  ''', [sinceDate]);

  final changes = <Map<String, dynamic>>[];
  for (final row in result) {
    changes.add({
      'entityType': row[0],
      'entityUuid': row[1],
      'data': jsonDecode(row[2] as String),
      'createdAt': row[3],
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
