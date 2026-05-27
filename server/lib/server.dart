import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:uuid/uuid.dart';
import 'package:qr/qr.dart';
import 'package:postgres/postgres.dart';

const _uuid = Uuid();
final _validTokens = <String>{};

// ─── 配置（环境变量 > 命令行参数 > 默认值） ───

int _serverPort() =>
    int.tryParse(Platform.environment['SERVER_PORT'] ?? '') ??
    int.tryParse(_arg(0)) ??
    8080;

String _serverPin() =>
    Platform.environment['SERVER_PIN'] ?? _arg(1) ?? '1234';

String _pgHost() =>
    Platform.environment['PG_HOST'] ?? _arg(2) ?? 'localhost';

int _pgPort() =>
    int.tryParse(Platform.environment['PG_PORT'] ?? '') ?? 5432;

String _pgDatabase() =>
    Platform.environment['PG_DATABASE'] ?? 'weightnest';

String _pgUsername() =>
    Platform.environment['PG_USERNAME'] ?? 'postgres';

String _pgPassword() =>
    Platform.environment['PG_PASSWORD'] ?? 'postgres';

String _arg(int i) => i < _rawArgs.length ? _rawArgs[i] : '';
List<String> get _rawArgs {
  try { return List<String>.from(Platform.executableArguments); } catch (_) {}
  return [];
}

late final Connection _db;

void main() async {
  final port = _serverPort();
  final pin = _serverPin();

  _db = await Connection.open(
    Endpoint(
      host: _pgHost(),
      port: _pgPort(),
      database: _pgDatabase(),
      username: _pgUsername(),
      password: _pgPassword(),
    ),
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );

  await _initDb();
  await _runMigrations();

  final app = Router()
    ..get('/qr', _handleQr)
    ..post('/auth/connect', _handleConnect)
    ..post('/sync', _handleSync)
    ..get('/changes', _handleChanges)
    ..get('/audit-log', _handleAuditLog)
    ..get('/health', (_) => Response.ok('{"status":"ok"}'));

  final handler = Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addHandler(app.call);

  await io.serve(handler, '0.0.0.0', port);
  final ip = await _localIp();
  print('🦜 WeightNest 服务器已启动 → http://$ip:$port');
  print('🔑 PIN: $pin');
  print('🗄  PG: ${_pgHost()}:${_pgPort()}/${_pgDatabase()}');
}

Future<String> _localIp() async {
  for (final iface in await NetworkInterface.list()) {
    for (final addr in iface.addresses) {
      if (addr.type == InternetAddressType.IPv4 &&
          (addr.address.startsWith('192.168.') || addr.address.startsWith('10.') || addr.address.startsWith('172.'))) {
        if (!addr.address.startsWith('172.17.')) return addr.address; // 排除 Docker 网桥
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

// ─── 数据库迁移 ───

Future<void> _runMigrations() async {
  // 为 change_log 补充审计字段
  try {
    await _db.execute('ALTER TABLE change_log ADD COLUMN IF NOT EXISTS user_id INT');
    await _db.execute('ALTER TABLE change_log ADD COLUMN IF NOT EXISTS action TEXT');
  } catch (e) {
    print('迁移警告: $e');
  }
}

// ─── 二维码页面 ───

Future<Response> _handleQr(Request req) async {
  final ip = await _localIp();
  final port = _serverPort();
  // Docker 内无法自动获取宿主机 IP，优先用参数 > 环境变量 > 自动检测
  final host = req.url.queryParameters['host'] ??
      Platform.environment['SERVER_HOST'] ??
      ip;
  final data = jsonEncode({'host': host, 'port': port});

  final qr = QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M);
  final img = QrImage(qr);

  // 手动生成 SVG
  final buf = StringBuffer();
  final size = img.moduleCount * 6 + 24;
  buf.write('<svg xmlns="http://www.w3.org/2000/svg" width="$size" height="$size" '
      'shape-rendering="crispEdges"><rect width="100%" height="100%" fill="#fff"/>');
  for (var y = 0; y < img.moduleCount; y++) {
    for (var x = 0; x < img.moduleCount; x++) {
      if (img.isDark(y, x)) {
        buf.write('<rect x="${x * 6 + 12}" y="${y * 6 + 12}" width="6" height="6" fill="#1a1a2e"/>');
      }
    }
  }
  buf.write('</svg>');
  final svg = buf.toString();

  final html = '<!DOCTYPE html><html><head><meta charset="utf-8"><title>WeightNest</title>'
      '<style>body{font-family:sans-serif;display:flex;flex-direction:column;align-items:center;'
      'justify-content:center;min-height:100vh;margin:0;background:#f5f5f5}'
      'h2{color:#333}.info{margin-top:12px;padding:8px 16px;background:#fff;'
      'border-radius:8px;font-size:14px;color:#666}</style></head><body>'
      '<h2>WeightNest</h2>'
      '$svg'
      '<div class="info">$host:$port</div>'
      '<p style="color:#999;font-size:12px">用 WeightNest App 扫码连接</p>'
      '</body></html>';

  return Response.ok(html, headers: {'Content-Type': 'text/html; charset=utf-8'});
}

// ─── 认证 ───

Future<Response> _handleConnect(Request req) async {
  final body = jsonDecode(await req.readAsString());
  final pin = body['pin'] as String?;
  final deviceId = body['deviceId'] as String?;
  if (pin != _serverPin()) return Response.forbidden('{"error":"PIN 错误"}');
  final token = _uuid.v4();
  _validTokens.add(token);
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
      'INSERT INTO change_log (entity_type,entity_uuid,data,user_id,action) VALUES (@a,@b,@c,@d,@e)'),
    parameters: {'a': entityType, 'b': entityUuid, 'c': jsonEncode(payload),
      'd': op['userId'], 'e': action});
}

// ─── 增量拉取 ───

Future<Response> _handleChanges(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{"error":"auth"}');
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

// ─── 审计日志 ───

Future<Response> _handleAuditLog(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{"error":"auth"}');

  final q = req.url.queryParameters;
  final userId = int.tryParse(q['userId'] ?? '');
  final action = q['action'];
  final entityType = q['entityType'];
  final page = int.tryParse(q['page'] ?? '1') ?? 1;
  final pageSize = (int.tryParse(q['pageSize'] ?? '50') ?? 50).clamp(1, 200);
  final startDate = q['startDate'];
  final endDate = q['endDate'];

  // 构建 WHERE 条件
  final conditions = <String>['1=1'];
  final params = <String, dynamic>{};

  if (userId != null) {
    conditions.add('cl.user_id=@userId');
    params['userId'] = userId;
  }
  if (action != null && action.isNotEmpty) {
    conditions.add('cl.action=@action');
    params['action'] = action;
  }
  if (entityType != null && entityType.isNotEmpty) {
    conditions.add('cl.entity_type=@entityType');
    params['entityType'] = entityType;
  }
  if (startDate != null && startDate.isNotEmpty) {
    conditions.add('cl.created_at>=@startDate');
    params['startDate'] = DateTime.parse(startDate);
  }
  if (endDate != null && endDate.isNotEmpty) {
    conditions.add('cl.created_at<=@endDate');
    params['endDate'] = DateTime.parse(endDate);
  }

  final whereClause = conditions.join(' AND ');
  final offset = (page - 1) * pageSize;

  // 查询总数
  final countResult = await _db.execute(
    Sql.named('SELECT COUNT(*) FROM change_log cl WHERE $whereClause'),
    parameters: params,
  );
  final total = (countResult.first.first as int?) ?? 0;

  // 查询日志（JOIN users 获取操作人姓名）
  params['limit'] = pageSize;
  params['offset'] = offset;
  final result = await _db.execute(
    Sql.named(
      'SELECT cl.id, cl.entity_type, cl.entity_uuid, cl.data, cl.action, '
      'cl.created_at, cl.user_id, COALESCE(u.display_name, \'未知\') as user_name '
      'FROM change_log cl '
      'LEFT JOIN users u ON cl.user_id = u.id '
      'WHERE $whereClause '
      'ORDER BY cl.created_at DESC '
      'LIMIT @limit OFFSET @offset'),
    parameters: params,
  );

  final items = result.map((row) => {
    'id': row[0],
    'entityType': row[1],
    'entityUuid': row[2],
    'data': row[3] is Map ? row[3] : jsonDecode(row[3] as String),
    'action': row[4],
    'createdAt': (row[5] as DateTime).toIso8601String(),
    'userId': row[6],
    'userName': row[7],
  }).toList();

  return Response.ok(jsonEncode({
    'items': items,
    'total': total,
    'page': page,
    'pageSize': pageSize,
    'totalPages': (total / pageSize).ceil(),
  }));
}

bool _checkAuth(Request req) {
  final token = (req.headers['Authorization'] ?? '').replaceFirst('Bearer ', '');
  return _validTokens.contains(token);
}
