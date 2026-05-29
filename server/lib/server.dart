import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:uuid/uuid.dart';
import 'package:qr/qr.dart';
import 'package:sqlite3/sqlite3.dart';

// ─── SQLite 适配层（兼容原 postgres Sql.named 语法） ───

class Sql {
  final String sql;
  Sql.named(this.sql);
}

class PgResult extends Iterable<List<Object?>> {
  final List<List<Object?>> _rows;
  PgResult(Object rows) : _rows = _build(rows);

  static List<List<Object?>> _build(Object rows) {
    if (rows is List && rows.isEmpty) return [];
    final result = <List<Object?>>[];
    for (int i = 0; i < (rows as List).length; i++) {
      final row = rows[i];
      final converted = <Object?>[];
      for (int j = 0; j < (row as List).length; j++) {
        final v = row[j];
        if (v is String) {
          final dt = DateTime.tryParse(v);
          if (dt != null) {
            // SQLite CURRENT_TIMESTAMP 格式 "2026-05-29 09:06:00" 是 UTC
            // 客户端传来的 ISO 格式 "2026-05-29T17:06:00" 是本地时间
            converted.add(v.contains('T') ? dt : DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second));
          } else {
            converted.add(v);
          }
        } else {
          converted.add(v);
        }
      }
      result.add(converted);
    }
    return result;
  }

  @override
  bool get isEmpty => _rows.isEmpty;
  bool get isNotEmpty => _rows.isNotEmpty;
  List<Object?> get first => _rows.first;
  @override
  Iterator<List<Object?>> get iterator => _rows.iterator;
}

(String, List<dynamic>) _namedToPositional(String sql, Map<String, dynamic> params) {
  final positional = <dynamic>[];
  final converted = sql.replaceAllMapped(RegExp(r'@(\w+)'), (m) {
    var value = params[m.group(1)!];
    if (value is DateTime) value = value.toIso8601String();
    if (value is bool) value = value ? 1 : 0;
    positional.add(value);
    return '?';
  });
  return (converted, positional);
}

class Pg {
  final Database _db;
  Pg._(this._db);

  static Future<Pg> open(String path) async {
    final db = sqlite3.open(path);
    db.execute('PRAGMA journal_mode=WAL');
    db.execute('PRAGMA foreign_keys=ON');
    return Pg._(db);
  }

  Future<PgResult> execute(dynamic sql, {Map<String, dynamic>? parameters}) async {
    final sqlStr = sql is Sql ? sql.sql : sql as String;
    final params = parameters ?? {};
    if (params.isNotEmpty) {
      final (sql2, positional) = _namedToPositional(sqlStr, params);
      if (_isSelect(sql2)) {
        final stmt = _db.prepare(sql2);
        try {
          return PgResult(stmt.select(positional).rows.toList());
        } finally {
          stmt.dispose();
        }
      } else {
        final stmt = _db.prepare(sql2);
        try {
          stmt.execute(positional);
        } finally {
          stmt.dispose();
        }
        return PgResult([]);
      }
    } else {
      if (_isSelect(sqlStr)) {
        return PgResult(_db.select(sqlStr).rows.toList());
      } else {
        _db.execute(sqlStr);
        return PgResult([]);
      }
    }
  }

  bool _isSelect(String s) {
    final t = s.trimLeft().toUpperCase();
    return t.startsWith('SELECT') || t.startsWith('WITH');
  }
}

const _uuid = Uuid();
final _validTokens = <String>{};
final _qrSessions = <String, DateTime>{};
int _dataVersion = 0;

// ─── 配置（环境变量 > 命令行参数 > 默认值） ───

int _serverPort() => int.tryParse(Platform.environment['SERVER_PORT'] ?? '') ?? int.tryParse(_arg(0) ?? '') ?? 8080;
String _serverPin() => Platform.environment['SERVER_PIN'] ?? _arg(1) ?? '1234';

String? _arg(int i) => i < _rawArgs.length ? _rawArgs[i] : null;
List<String> get _rawArgs {
  try {
    return List<String>.from(Platform.executableArguments);
  } catch (_) {}
  return [];
}

String _dbPath() {
  // 优先从环境变量读取，默认项目 data/ 目录
  final env = Platform.environment['DB_PATH'];
  if (env != null && env.isNotEmpty) return env;
  // 兼容 Docker 挂载 /app/data 和本地运行
  final dir = Directory('data');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return 'data${Platform.pathSeparator}weightnest.db';
}

late final Pg _db;

void main() async {
  final port = _serverPort();
  final pin = _serverPin();

  _db = await Pg.open(_dbPath());

  await _initDb();
  await _runMigrations();
  await _initDefaults();
  await _loadDataVersion();

  final app = Router()
    ..get('/qr', _handleQr)
    ..post('/auth/connect', _handleConnect)
    ..post('/auth/qr-session', _handleQrSession)
    ..post('/auth/qr-login', _handleQrLogin)
    ..post('/sync', _handleSync)
    ..get('/changes', _handleChanges)
    ..get('/changes/stream', _handleChangesStream)
    ..get('/audit-log', _handleAuditLog)
    ..get('/data-version', (_) => Response.ok('$_dataVersion'))
    ..get('/birds', _handleBirds)
    ..get('/birds/<id>', _handleBirdDetail)
    ..get('/birds/<id>/weights', _handleBirdWeights)
    ..patch('/birds/<id>', _handleUpdateBird)
    ..post('/tasks/publish', _handlePublishTasks)
    ..get('/rooms', _handleRooms)
    ..post('/rooms', _handleCreateRoom)
    ..patch('/rooms/<id>', _handleUpdateRoom)
    ..get('/species', _handleSpecies)
    ..patch('/species/<id>', _handleUpdateSpecies)
    ..get('/users', _handleUsers)
    ..post('/users', _handleCreateUser)
    ..patch('/users/<id>', _handleUpdateUser)
    ..get('/health', (_) => Response.ok('{"status":"ok"}'));

  final handler = Pipeline().addMiddleware(corsHeaders()).addMiddleware(logRequests()).addHandler(app.call);

  await io.serve(handler, '0.0.0.0', port);
  final ip = await _localIp();
  print('🦜 WeightNest 服务器已启动 → http://$ip:$port');
  print('🔑 PIN: $pin');
  print('🗄  SQLite: ${_dbPath()}');
}

Future<String> _localIp() async {
  final candidates = <String>[];
  for (final iface in await NetworkInterface.list()) {
    for (final addr in iface.addresses) {
      if (addr.type != InternetAddressType.IPv4) continue;
      final a = addr.address;
      // 排除虚拟网卡地址段
      if (a.startsWith('172.17.') || a.startsWith('172.18.') ||
          a.startsWith('172.19.') || a.startsWith('172.2') ||
          a.startsWith('172.3')) continue;
      if (a.startsWith('192.168.') || a.startsWith('10.') || a.startsWith('172.')) {
        candidates.add(a);
      }
    }
  }
  // 优先 192.168.x.x（最常见家用路由器），其次 10.x，最后其他
  candidates.sort((a, b) {
    int rank(String ip) {
      if (ip.startsWith('192.168.')) return 0;
      if (ip.startsWith('10.')) return 1;
      return 2;
    }
    return rank(a).compareTo(rank(b));
  });
  return candidates.isNotEmpty ? candidates.first : '127.0.0.1';
}

// ─── 数据库初始化 ───

Future<void> _initDb() async {
  await _db.execute('''
    CREATE TABLE IF NOT EXISTS species (
      id INTEGER PRIMARY KEY AUTOINCREMENT, uuid TEXT UNIQUE NOT NULL, name TEXT NOT NULL,
      nestling_end_days INTEGER DEFAULT 45, juvenile_end_days INTEGER DEFAULT 120,
      nestling_weigh_interval_days INTEGER DEFAULT 1,
      juvenile_weigh_interval_days INTEGER DEFAULT 3,
      adult_weigh_interval_days INTEGER DEFAULT 7,
      created_at TEXT DEFAULT (CURRENT_TIMESTAMP), updated_at TEXT DEFAULT (CURRENT_TIMESTAMP),
      deleted_at TEXT
    )
  ''');
  await _db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT, uuid TEXT UNIQUE NOT NULL, username TEXT NOT NULL,
      display_name TEXT NOT NULL, password_hash TEXT DEFAULT '', role TEXT DEFAULT 'keeper',
      created_at TEXT DEFAULT (CURRENT_TIMESTAMP), updated_at TEXT DEFAULT (CURRENT_TIMESTAMP),
      deleted_at TEXT
    )
  ''');
  await _db.execute('''
    CREATE TABLE IF NOT EXISTS rooms (
      id INTEGER PRIMARY KEY AUTOINCREMENT, uuid TEXT UNIQUE NOT NULL, name TEXT NOT NULL,
      sort_order INTEGER DEFAULT 0, assigned_user_id INTEGER,
      created_at TEXT DEFAULT (CURRENT_TIMESTAMP), updated_at TEXT DEFAULT (CURRENT_TIMESTAMP),
      deleted_at TEXT
    )
  ''');
  await _db.execute('''
    CREATE TABLE IF NOT EXISTS birds (
      id INTEGER PRIMARY KEY AUTOINCREMENT, uuid TEXT UNIQUE NOT NULL, name TEXT NOT NULL,
      ring_number TEXT, species_id INTEGER NOT NULL, room_id INTEGER,
      birth_date TEXT NOT NULL, gender TEXT DEFAULT '未知',
      sort_order INTEGER DEFAULT 0, weigh_interval_days INTEGER,
      status TEXT DEFAULT '正常', notes TEXT,
      created_at TEXT DEFAULT (CURRENT_TIMESTAMP), updated_at TEXT DEFAULT (CURRENT_TIMESTAMP),
      deleted_at TEXT
    )
  ''');
  await _db.execute('''
    CREATE TABLE IF NOT EXISTS weight_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT, uuid TEXT UNIQUE NOT NULL, bird_id INTEGER NOT NULL,
      weight_g REAL NOT NULL, recorded_at TEXT NOT NULL,
      recorded_by INTEGER, is_fasting INTEGER DEFAULT 1, notes TEXT,
      created_at TEXT DEFAULT (CURRENT_TIMESTAMP), updated_at TEXT DEFAULT (CURRENT_TIMESTAMP)
    )
  ''');
  await _db.execute('''
    CREATE TABLE IF NOT EXISTS synced_ops (
      op_id TEXT UNIQUE NOT NULL, processed_at TEXT DEFAULT (CURRENT_TIMESTAMP)
    )
  ''');
  await _db.execute('''
    CREATE TABLE IF NOT EXISTS change_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT, entity_type TEXT NOT NULL, entity_uuid TEXT NOT NULL,
      data TEXT NOT NULL, created_at TEXT DEFAULT (CURRENT_TIMESTAMP)
    )
  ''');
  await _db.execute('''
    CREATE TABLE IF NOT EXISTS devices (
      device_id TEXT PRIMARY KEY, connected_at TEXT DEFAULT (CURRENT_TIMESTAMP)
    )
  ''');
  await _db.execute('''
    CREATE TABLE IF NOT EXISTS server_state (
      key TEXT PRIMARY KEY, value TEXT NOT NULL
    )
  ''');
}

// ─── 数据库迁移 ───

Future<void> _runMigrations() async {
  // SQLite 不支持 ALTER TABLE ADD COLUMN IF NOT EXISTS，逐条捕获
  for (final sql in [
    'ALTER TABLE change_log ADD COLUMN user_id INTEGER',
    'ALTER TABLE change_log ADD COLUMN action TEXT',
    'ALTER TABLE species ADD COLUMN nestling_weigh_interval_days INTEGER DEFAULT 1',
    'ALTER TABLE species ADD COLUMN juvenile_weigh_interval_days INTEGER DEFAULT 3',
    'ALTER TABLE birds ADD COLUMN weigh_interval_days INTEGER',
  ]) {
    try {
      await _db.execute(sql);
    } catch (_) {
      // 列已存在，忽略
    }
  }
}

/// 服务端品种初始化（与手机端 initDefaults 保持一致）
Future<void> _initDefaults() async {
  final species = [
    '牡丹鹦鹉', '金太阳', '虎皮鹦鹉', '玄凤鹦鹉', '金刚鹦鹉',
  ];
  for (final name in species) {
    final exists = await _db.execute(
      Sql.named('SELECT 1 FROM species WHERE name=@n'),
      parameters: {'n': name},
    );
    if (exists.isEmpty) {
      await _db.execute(
        Sql.named('INSERT INTO species (uuid, name) VALUES (@u, @n)'),
        parameters: {'u': _uuid.v4(), 'n': name},
      );
    }
  }

  // 默认管理员
  final adminExists = await _db.execute("SELECT 1 FROM users WHERE username='admin'");
  if (adminExists.isEmpty) {
    await _db.execute(
      Sql.named("INSERT INTO users (uuid, username, display_name, role) VALUES (@u, 'admin', '管理员', 'admin')"),
      parameters: {'u': _uuid.v4()},
    );
  }
}

Future<void> _loadDataVersion() async {
  try {
    final r = await _db.execute("SELECT value FROM server_state WHERE key='data_version'");
    if (r.isNotEmpty) {
      _dataVersion = int.tryParse(r.first[0] as String) ?? 0;
    }
  } catch (_) {}
}

Future<void> _bumpVersion() async {
  _dataVersion++;
  try {
    await _db.execute(
      Sql.named("INSERT INTO server_state (key, value) VALUES ('data_version', @v) "
          "ON CONFLICT (key) DO UPDATE SET value=@v"),
      parameters: {'v': '$_dataVersion'},
    );
  } catch (_) {}
}

// ─── 数据库迁移 ───

// ─── 二维码页面 ───

Future<Response> _handleQr(Request req) async {
  final ip = await _localIp();
  final port = _serverPort();
  final envHost = Platform.environment['SERVER_HOST'];
  final host = req.url.queryParameters['host'] ?? (envHost != null && envHost.isNotEmpty ? envHost : null) ?? ip;
  final session = req.url.queryParameters['session'];
  final qrJson = <String, dynamic>{'host': host, 'port': port};
  if (session != null) qrJson['session'] = session;
  final data = jsonEncode(qrJson);

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
    Sql.named('INSERT INTO devices (device_id, connected_at) VALUES (@d, CURRENT_TIMESTAMP) '
        'ON CONFLICT (device_id) DO UPDATE SET connected_at = CURRENT_TIMESTAMP'),
    parameters: {'d': deviceId ?? 'unknown'},
  );
  return Response.ok(jsonEncode({'token': token}));
}

// ─── 扫码登录 ───

/// 桌面端创建 QR 登录会话（返回 8 位会话码，有效期 2 分钟）
Future<Response> _handleQrSession(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{"error":"auth"}');
  final sessionId = _uuid.v4().substring(0, 8);
  _qrSessions[sessionId] = DateTime.now().add(const Duration(minutes: 2));
  final ip = await _localIp();
  final port = _serverPort();
  final envHost = Platform.environment['SERVER_HOST'];
  final host = req.url.queryParameters['host'] ?? (envHost != null && envHost.isNotEmpty ? envHost : null) ?? ip;
  return Response.ok(jsonEncode({
    'session': sessionId,
    'host': host,
    'port': port,
  }));
}

/// 手机端用 QR 会话码换取 auth token（免 PIN）
Future<Response> _handleQrLogin(Request req) async {
  final body = jsonDecode(await req.readAsString());
  final session = body['session'] as String?;
  final deviceId = body['deviceId'] as String? ?? 'mobile';

  if (session == null || !_qrSessions.containsKey(session)) {
    return Response.forbidden('{"error":"无效或已使用的登录会话"}');
  }
  if (_qrSessions[session]!.isBefore(DateTime.now())) {
    _qrSessions.remove(session);
    return Response.forbidden('{"error":"登录会话已过期"}');
  }
  _qrSessions.remove(session);

  final token = _uuid.v4();
  _validTokens.add(token);
  await _db.execute(
    Sql.named('INSERT INTO devices (device_id, connected_at) VALUES (@d, CURRENT_TIMESTAMP) '
        'ON CONFLICT (device_id) DO UPDATE SET connected_at = CURRENT_TIMESTAMP'),
    parameters: {'d': deviceId},
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
      final r = await _db.execute(Sql.named('SELECT 1 FROM synced_ops WHERE op_id=@id'), parameters: {'id': opId});
      if (r.isNotEmpty) {
        successOps.add(opId);
        continue;
      }
      await _applyOp(op);
      await _db.execute(Sql.named('INSERT INTO synced_ops (op_id) VALUES (@id)'), parameters: {'id': opId});
      successOps.add(opId);
    } catch (e) {
      print('同步失败 $opId: $e');
    }
  }
  if (successOps.isNotEmpty) await _bumpVersion();
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
      final birdUuid = p('birdUuid') as String?;
      int? serverBirdId;
      if (birdUuid != null) {
        final r = await _db.execute(
          Sql.named('SELECT id FROM birds WHERE uuid=@u'),
          parameters: {'u': birdUuid},
        );
        if (r.isEmpty) return; // 鹦鹉已删除，无视此操作
        serverBirdId = r.first[0] as int;
      } else {
        serverBirdId = p('birdId') as int;
      }
      await _db.execute(
          Sql.named('INSERT INTO weight_records (uuid,bird_id,weight_g,recorded_at,recorded_by,is_fasting) '
              'VALUES (@a,@b,@c,@d,@e,@f)'),
          parameters: {
            'a': entityUuid,
            'b': serverBirdId,
            'c': p('weightG'),
            'd': DateTime.parse(p('recordedAt')),
            'e': op['userId'],
            'f': p('isFasting') ?? true
          });
      break;
    case 'delete_weight':
      await _db.execute(
        Sql.named('DELETE FROM weight_records WHERE uuid=@u'),
        parameters: {'u': entityUuid},
      );
      // Fallback: old records may have mismatched UUIDs, match by birdUuid + same-minute recordedAt
      {
        final delBirdUuid = p('birdUuid') as String?;
        final delRecordedAt = p('recordedAt') as String?;
        if (delBirdUuid != null && delRecordedAt != null) {
          final br = await _db.execute(
            Sql.named('SELECT id FROM birds WHERE uuid=@u'),
            parameters: {'u': delBirdUuid},
          );
          if (br.isNotEmpty) {
            final serverBirdId = br.first[0] as int;
            final ra = DateTime.parse(delRecordedAt);
            final ms = DateTime(ra.year, ra.month, ra.day, ra.hour, ra.minute);
            final me = ms.add(const Duration(minutes: 1));
            await _db.execute(
              Sql.named('DELETE FROM weight_records WHERE bird_id=@bid AND recorded_at>=@ms AND recorded_at<@me'),
              parameters: {'bid': serverBirdId, 'ms': ms, 'me': me},
            );
          }
        }
      }
      break;
    case 'edit_weight':
      {
        final setClauses = <String>[];
        final params = <String, dynamic>{'u': entityUuid};
        if (payload.containsKey('weightG')) {
          setClauses.add('weight_g=@wg'); params['wg'] = p('weightG');
        }
        if (payload.containsKey('isFasting')) {
          setClauses.add('is_fasting=@f'); params['f'] = p('isFasting');
        }
        if (payload.containsKey('recordedAt')) {
          setClauses.add('recorded_at=@ra'); params['ra'] = DateTime.parse(p('recordedAt'));
        }
        if (setClauses.isNotEmpty) {
          await _db.execute(
            Sql.named('UPDATE weight_records SET ${setClauses.join(', ')} WHERE uuid=@u'),
            parameters: params,
          );
          // Fallback: old records with mismatched UUIDs, match by birdUuid + same-minute recordedAt
          final editBirdUuid = p('birdUuid') as String?;
          if (editBirdUuid != null && payload.containsKey('recordedAt')) {
            final br = await _db.execute(
              Sql.named('SELECT id FROM birds WHERE uuid=@u'),
              parameters: {'u': editBirdUuid},
            );
            if (br.isNotEmpty) {
              final serverBirdId = br.first[0] as int;
              final ra = DateTime.parse(p('recordedAt'));
              final ms = DateTime(ra.year, ra.month, ra.day, ra.hour, ra.minute);
              final me = ms.add(const Duration(minutes: 1));
              final fbParams = <String, dynamic>{'bid': serverBirdId, 'ms': ms, 'me': me};
              if (payload.containsKey('weightG')) fbParams['wg'] = p('weightG');
              if (payload.containsKey('isFasting')) fbParams['f'] = p('isFasting');
              if (payload.containsKey('recordedAt')) fbParams['ra'] = DateTime.parse(p('recordedAt'));
              await _db.execute(
                Sql.named('UPDATE weight_records SET ${setClauses.join(', ')} WHERE bird_id=@bid AND recorded_at>=@ms AND recorded_at<@me'),
                parameters: fbParams,
              );
            }
          }
        }
        break;
      }
    case 'create_bird':
      await _db.execute(
          Sql.named('INSERT INTO birds (uuid,name,species_id,room_id,birth_date,gender,ring_number) '
              'VALUES (@a,@b,@c,@d,@e,@f,@g)'),
          parameters: {
            'a': entityUuid,
            'b': p('name'),
            'c': p('speciesId') ?? 1,
            'd': p('roomId'),
            'e': DateTime.parse(p('birthDate')),
            'f': p('gender') ?? '未知',
            'g': p('ringNumber')
          });
      // 解析品种名和房间名，写入变更日志时可读
      final spResult = await _db.execute(Sql.named('SELECT name FROM species WHERE id=@id'),
          parameters: {'id': p('speciesId') ?? 1});
      if (spResult.isNotEmpty) payload['speciesName'] = spResult.first[0] as String;
      if (p('roomId') != null) {
        final rr = await _db.execute(Sql.named('SELECT name FROM rooms WHERE id=@id'),
            parameters: {'id': p('roomId') as int});
        if (rr.isNotEmpty) payload['roomName'] = rr.first[0] as String;
      }
      break;
    case 'update_bird':
      {
        // 通过 UUID 解析服务端 ID（客户端 payload 里没有 id 字段）
        final r = await _db.execute(
          Sql.named('SELECT id FROM birds WHERE uuid=@u'),
          parameters: {'u': entityUuid},
        );
        if (r.isEmpty) return; // 鹦鹉已删除，无视此操作
        final serverId = r.first[0] as int;
        await _db.execute(Sql.named(
            'UPDATE birds SET name=@n, species_id=@s, ring_number=@r, updated_at=CURRENT_TIMESTAMP WHERE id=@id'),
            parameters: {'n': p('name'), 's': p('speciesId') ?? 1, 'r': p('ringNumber'), 'id': serverId});
        // 解析品种名，写入变更日志时可读
        final spResult = await _db.execute(Sql.named('SELECT name FROM species WHERE id=@id'),
            parameters: {'id': p('speciesId') ?? 1});
        if (spResult.isNotEmpty) payload['speciesName'] = spResult.first[0] as String;
        break;
      }
    case 'create_room':
      await _db.execute(Sql.named('INSERT INTO rooms (uuid,name) VALUES (@a,@b)'),
          parameters: {'a': entityUuid, 'b': p('name')});
      break;
    case 'create_species':
      await _db.execute(Sql.named('INSERT INTO species (uuid,name) VALUES (@a,@b)'),
          parameters: {'a': entityUuid, 'b': p('name')});
      break;
    case 'create_user':
      await _db.execute(Sql.named('INSERT INTO users (uuid,username,display_name,role) VALUES (@a,@b,@c,@d)'),
          parameters: {'a': entityUuid, 'b': p('username'), 'c': p('displayName'), 'd': p('role') ?? 'keeper'});
      break;
  }
  await _db.execute(
      Sql.named('INSERT INTO change_log (entity_type,entity_uuid,data,user_id,action) VALUES (@a,@b,@c,@d,@e)'),
      parameters: {'a': entityType, 'b': entityUuid, 'c': jsonEncode(payload), 'd': op['userId'], 'e': action});
}

// ─── 增量拉取 ───

Future<Response> _handleChanges(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{"error":"auth"}');
  final since = int.tryParse(req.url.queryParameters['since'] ?? '0') ?? 0;
  final sinceDate = DateTime.fromMillisecondsSinceEpoch(since);

  final result = await _db.execute(
      Sql.named('SELECT entity_type,entity_uuid,data,action,created_at FROM change_log '
          'WHERE created_at>@s ORDER BY created_at ASC LIMIT 200'),
      parameters: {'s': sinceDate});

  final changes = <Map<String, dynamic>>[];
  for (final row in result) {
    changes.add({
      'entityType': row[0],
      'entityUuid': row[1],
      'data': row[2] is Map ? row[2] : jsonDecode(row[2] as String),
      'action': row[3],
      'createdAt': (row[4] as DateTime).toIso8601String(),
    });
  }
  return Response.ok(jsonEncode({'changes': changes}));
}

// ─── SSE 实时推送变更 ───

Future<Response> _handleChangesStream(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{"error":"auth"}');
  final since = int.tryParse(req.url.queryParameters['since'] ?? '0') ?? 0;
  var lastTs = DateTime.fromMillisecondsSinceEpoch(since);

  return Response.ok(
    _streamChanges(lastTs),
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    },
  );
}

Stream<String> _streamChanges(DateTime sinceDate) async* {
  var lastCheck = sinceDate;
  var idle = 0;

  while (idle < 2) { // max ~30s idle, then client reconnects
    await Future.delayed(const Duration(seconds: 2));

    try {
      final result = await _db.execute(
        Sql.named('SELECT entity_type, entity_uuid, data, action, created_at FROM change_log '
            'WHERE created_at > @s ORDER BY created_at ASC LIMIT 50'),
        parameters: {'s': lastCheck},
      );

      if (result.isNotEmpty) {
        idle = 0;
        for (final row in result) {
          final change = jsonEncode({
            'entityType': row[0],
            'entityUuid': row[1],
            'data': row[2] is Map ? row[2] : jsonDecode(row[2] as String),
            'action': row[3],
            'createdAt': (row[4] as DateTime).toIso8601String(),
          });
          yield 'data: $change\n\n';
          if ((row[4] as DateTime).isAfter(lastCheck)) {
            lastCheck = row[4] as DateTime;
          }
        }
      } else {
        idle++;
        yield ': heartbeat\n\n';
      }
    } catch (_) {
      break;
    }
  }
  yield 'data: {"type":"eof"}\n\n';
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
    Sql.named('SELECT cl.id, cl.entity_type, cl.entity_uuid, cl.data, cl.action, '
        'cl.created_at, cl.user_id, COALESCE(u.display_name, \'未知\') as user_name '
        'FROM change_log cl '
        'LEFT JOIN users u ON cl.user_id = u.id '
        'WHERE $whereClause '
        'ORDER BY cl.created_at DESC '
        'LIMIT @limit OFFSET @offset'),
    parameters: params,
  );

  final items = result
      .map((row) => {
            'id': row[0],
            'entityType': row[1],
            'entityUuid': row[2],
            'data': row[3] is Map ? row[3] : jsonDecode(row[3] as String),
            'action': row[4],
            'createdAt': (row[5] as DateTime).toIso8601String(),
            'userId': row[6],
            'userName': row[7],
          })
      .toList();

  return Response.ok(jsonEncode({
    'items': items,
    'total': total,
    'page': page,
    'pageSize': pageSize,
    'totalPages': (total / pageSize).ceil(),
  }));
}

// ─── 鹦鹉查询 ───

Future<Response> _handleBirds(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{"error":"auth"}');

  final search = req.url.queryParameters['search'];
  final speciesId = int.tryParse(req.url.queryParameters['speciesId'] ?? '');
  final roomId = int.tryParse(req.url.queryParameters['roomId'] ?? '');

  var sql = '''
    SELECT b.id, b.uuid, b.name, b.ring_number, b.species_id, b.room_id,
           b.birth_date, b.gender, b.status, b.notes, b.created_at, b.updated_at,
           s.name as species_name,
           r.name as room_name
    FROM birds b
    LEFT JOIN species s ON b.species_id = s.id
    LEFT JOIN rooms r ON b.room_id = r.id
    WHERE b.deleted_at IS NULL
  ''';
  final params = <String, dynamic>{};

  if (search != null && search.isNotEmpty) {
    sql += ' AND (b.name LIKE @search OR b.ring_number LIKE @search)';
    params['search'] = '%$search%';
  }
  if (speciesId != null) {
    sql += ' AND b.species_id=@speciesId';
    params['speciesId'] = speciesId;
  }
  if (roomId != null) {
    sql += ' AND b.room_id=@roomId';
    params['roomId'] = roomId;
  }
  sql += ' ORDER BY b.sort_order ASC, b.name ASC';

  final result = await _db.execute(Sql.named(sql), parameters: params);
  final birds = result
      .map((row) => {
            'id': row[0],
            'uuid': row[1],
            'name': row[2],
            'ringNumber': row[3],
            'speciesId': row[4],
            'roomId': row[5],
            'birthDate': (row[6] as DateTime).toIso8601String(),
            'gender': row[7],
            'status': row[8],
            'notes': row[9],
            'createdAt': (row[10] as DateTime?)?.toIso8601String(),
            'updatedAt': (row[11] as DateTime?)?.toIso8601String(),
            'speciesName': row[12],
            'roomName': row[13],
          })
      .toList();

  return Response.ok(jsonEncode({'birds': birds}));
}

Future<Response> _handleBirdDetail(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{"error":"auth"}');
  final id = int.tryParse(req.params['id'] ?? '');
  if (id == null) return Response(400, body: '{"error":"invalid id"}');

  final result = await _db.execute(Sql.named('''
    SELECT b.id, b.uuid, b.name, b.ring_number, b.species_id, b.room_id,
           b.birth_date, b.gender, b.status, b.notes, b.created_at, b.updated_at,
           s.name as species_name, s.nestling_end_days, s.juvenile_end_days,
           r.name as room_name
    FROM birds b
    LEFT JOIN species s ON b.species_id = s.id
    LEFT JOIN rooms r ON b.room_id = r.id
    WHERE b.id=@id AND b.deleted_at IS NULL
  '''), parameters: {'id': id});

  if (result.isEmpty) return Response.notFound('{"error":"not found"}');
  final row = result.first;
  return Response.ok(jsonEncode({
    'id': row[0],
    'uuid': row[1],
    'name': row[2],
    'ringNumber': row[3],
    'speciesId': row[4],
    'roomId': row[5],
    'birthDate': (row[6] as DateTime).toIso8601String(),
    'gender': row[7],
    'status': row[8],
    'notes': row[9],
    'speciesName': row[12],
    'nestlingEndDays': row[13],
    'juvenileEndDays': row[14],
    'roomName': row[15],
  }));
}

Future<Response> _handleBirdWeights(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{"error":"auth"}');
  final id = int.tryParse(req.params['id'] ?? '');
  if (id == null) return Response(400, body: '{"error":"invalid id"}');

  final result = await _db.execute(Sql.named('''
    SELECT id, uuid, bird_id, weight_g, recorded_at, recorded_by, is_fasting, notes, created_at
    FROM weight_records
    WHERE bird_id=@id
    ORDER BY recorded_at DESC
    LIMIT 500
  '''), parameters: {'id': id});

  final weights = result
      .map((row) => {
            'id': row[0],
            'uuid': row[1],
            'birdId': row[2],
            'weightG': row[3],
            'recordedAt': (row[4] as DateTime).toIso8601String(),
            'recordedBy': row[5],
            'isFasting': row[6],
            'notes': row[7],
          })
      .toList();

  return Response.ok(jsonEncode({'weights': weights}));
}

// ─── 更新鹦鹉 ───

Future<Response> _handleUpdateBird(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{"error":"auth"}');
  final id = int.tryParse(req.params['id'] ?? '');
  if (id == null) return Response(400, body: '{"error":"invalid id"}');

  final body = jsonDecode(await req.readAsString());
  final updates = <String>[];
  final params = <String, dynamic>{'id': id};

  if (body.containsKey('name')) { updates.add('name=@n'); params['n'] = body['name']; }
  if (body.containsKey('speciesId')) { updates.add('species_id=@s'); params['s'] = body['speciesId']; }
  if (body.containsKey('roomId')) { updates.add('room_id=@r'); params['r'] = body['roomId']; }
  if (body.containsKey('status')) { updates.add('status=@st'); params['st'] = body['status']; }
  if (body.containsKey('notes')) { updates.add('notes=@no'); params['no'] = body['notes']; }
  if (body.containsKey('ringNumber')) { updates.add('ring_number=@rn'); params['rn'] = body['ringNumber']; }
  if (body.containsKey('weighIntervalDays')) {
    updates.add('weigh_interval_days=@wi'); params['wi'] = body['weighIntervalDays'];
  }

  if (updates.isEmpty) return Response(400, body: '{"error":"no changes"}');
  updates.add('updated_at=CURRENT_TIMESTAMP');

  await _db.execute(
    Sql.named('UPDATE birds SET ${updates.join(', ')} WHERE id=@id'),
    parameters: params,
  );

  // Write change log — resolve IDs to names so audit log is readable
  final birdResult = await _db.execute(Sql.named(
    'SELECT b.uuid, b.name, s.name as sp_name FROM birds b LEFT JOIN species s ON b.species_id=s.id WHERE b.id=@id'),
    parameters: {'id': id});
  if (birdResult.isNotEmpty) {
    final birdUuid = birdResult.first[0] as String;
    final enriched = Map<String, dynamic>.from(body);
    enriched['name'] = birdResult.first[1] as String;
    enriched['speciesName'] = birdResult.first[2] as String?;
    if (body.containsKey('roomId')) {
      final rr = await _db.execute(Sql.named('SELECT name FROM rooms WHERE id=@id'), parameters: {'id': body['roomId']});
      if (rr.isNotEmpty) enriched['roomName'] = rr.first[0] as String;
    }
    await _db.execute(Sql.named(
      'INSERT INTO change_log (entity_type, entity_uuid, data, action) VALUES (@a,@b,@c,@d)'),
      parameters: {'a': 'bird', 'b': birdUuid, 'c': jsonEncode(enriched), 'd': 'update_bird'},
    );
    await _bumpVersion();
  }

  return Response.ok(jsonEncode({'ok': true}));
}

// ─── 发布称重任务 ───

Future<Response> _handlePublishTasks(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{"error":"auth"}');
  final body = jsonDecode(await req.readAsString());
  final birdIds = (body['birdIds'] as List?)?.map((e) => e as int).toList() ?? [];
  if (birdIds.isEmpty) return Response(400, body: '{"error":"birdIds required"}');

  final today = DateTime.now();
  final dayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  for (final birdId in birdIds) {
    // Write change_log entry — mobile apps will generate local tasks on pull
    await _db.execute(Sql.named(
      'INSERT INTO change_log (entity_type, entity_uuid, data, action) VALUES (@a,@b,@c,@d)'),
      parameters: {
        'a': 'task', 'b': _uuid.v4(), 'c': jsonEncode({'birdId': birdId, 'dueDate': dayStr, 'status': '待完成'}),
        'd': 'publish_task',
      },
    );
  }

  await _bumpVersion();
  return Response.ok(jsonEncode({'published': birdIds.length}));
}

// ─── 房间管理 ───

Future<Response> _handleRooms(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{"error":"auth"}');
  final result = await _db.execute('''
    SELECT r.id, r.uuid, r.name, r.sort_order, r.assigned_user_id,
           COALESCE(u.display_name, '') as assigned_name,
           (SELECT COUNT(*) FROM birds b WHERE b.room_id = r.id AND b.deleted_at IS NULL) as bird_count
    FROM rooms r
    LEFT JOIN users u ON r.assigned_user_id = u.id
    WHERE r.deleted_at IS NULL
    ORDER BY r.sort_order, r.id
  ''');
  final items = result.map((row) => {
    'id': row[0], 'uuid': row[1], 'name': row[2], 'sortOrder': row[3],
    'assignedUserId': row[4], 'assignedUserName': row[5],
    'birdCount': row[6],
  }).toList();
  return Response.ok(jsonEncode({'rooms': items}));
}

Future<Response> _handleCreateRoom(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{"error":"auth"}');
  final body = jsonDecode(await req.readAsString());
  final name = body['name'] as String?;
  if (name == null || name.isEmpty) return Response(400, body: '{"error":"name required"}');
  final uuid = _uuid.v4();
  await _db.execute(Sql.named(
    'INSERT INTO rooms (uuid, name, sort_order, assigned_user_id) VALUES (@u, @n, 0, @a)'),
    parameters: {'u': uuid, 'n': name, 'a': body['assignedUserId']},
  );
  await _db.execute(Sql.named(
    'INSERT INTO change_log (entity_type, entity_uuid, data, action) VALUES (@a,@b,@c,@d)'),
    parameters: {'a': 'room', 'b': uuid, 'c': jsonEncode(body), 'd': 'create_room'},
  );
  await _bumpVersion();
  return Response.ok(jsonEncode({'uuid': uuid}));
}

Future<Response> _handleUpdateRoom(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{"error":"auth"}');
  final id = int.tryParse(req.params['id'] ?? '');
  if (id == null) return Response(400, body: '{"error":"invalid id"}');
  final body = jsonDecode(await req.readAsString());
  final updates = <String>[];
  final params = <String, dynamic>{'id': id};
  if (body.containsKey('name')) { updates.add('name=@n'); params['n'] = body['name']; }
  if (body.containsKey('sortOrder')) { updates.add('sort_order=@so'); params['so'] = body['sortOrder']; }
  if (body.containsKey('assignedUserId')) { updates.add('assigned_user_id=@a'); params['a'] = body['assignedUserId']; }
  if (updates.isEmpty) return Response(400, body: '{"error":"no changes"}');
  updates.add('updated_at=CURRENT_TIMESTAMP');
  await _db.execute(Sql.named('UPDATE rooms SET ${updates.join(', ')} WHERE id=@id'), parameters: params);
  final r = await _db.execute(Sql.named('SELECT uuid FROM rooms WHERE id=@id'), parameters: {'id': id});
  if (r.isNotEmpty) {
    await _db.execute(Sql.named('INSERT INTO change_log (entity_type, entity_uuid, data, action) VALUES (@a,@b,@c,@d)'),
      parameters: {'a': 'room', 'b': r.first[0] as String, 'c': jsonEncode(body), 'd': 'update_room'});
    await _bumpVersion();
  }
  return Response.ok(jsonEncode({'ok': true}));
}

// ─── 品种列表及配置 ───

Future<Response> _handleSpecies(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{"error":"auth"}');
  final result = await _db.execute('''
    SELECT id, uuid, name, nestling_end_days, juvenile_end_days,
           nestling_weigh_interval_days, juvenile_weigh_interval_days,
           adult_weigh_interval_days, created_at
    FROM species WHERE deleted_at IS NULL ORDER BY id
  ''');
  final items = result.map((row) => {
    'id': row[0], 'uuid': row[1], 'name': row[2],
    'nestlingEndDays': row[3], 'juvenileEndDays': row[4],
    'nestlingWeighIntervalDays': row[5], 'juvenileWeighIntervalDays': row[6],
    'adultWeighIntervalDays': row[7],
    'createdAt': (row[8] as DateTime).toIso8601String(),
  }).toList();
  return Response.ok(jsonEncode({'species': items}));
}

Future<Response> _handleUpdateSpecies(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{"error":"auth"}');
  final id = int.tryParse(req.params['id'] ?? '');
  if (id == null) return Response(400, body: '{"error":"invalid id"}');

  final body = jsonDecode(await req.readAsString());
  final updates = <String>[];
  final params = <String, dynamic>{'id': id};
  final fields = {
    'nestlingEndDays': 'nestling_end_days', 'juvenileEndDays': 'juvenile_end_days',
    'nestlingWeighIntervalDays': 'nestling_weigh_interval_days',
    'juvenileWeighIntervalDays': 'juvenile_weigh_interval_days',
    'adultWeighIntervalDays': 'adult_weigh_interval_days',
  };
  for (final e in fields.entries) {
    if (body.containsKey(e.key)) {
      updates.add('${e.value}=@${e.key}');
      params[e.key] = body[e.key];
    }
  }

  if (updates.isEmpty) return Response(400, body: '{"error":"no changes"}');
  updates.add('updated_at=CURRENT_TIMESTAMP');
  await _db.execute(
    Sql.named('UPDATE species SET ${updates.join(', ')} WHERE id=@id'),
    parameters: params,
  );

  // Change log — write full species data so mobile can upsert
  final spResult = await _db.execute(Sql.named(
    'SELECT uuid, name, nestling_end_days, juvenile_end_days, nestling_weigh_interval_days, juvenile_weigh_interval_days, adult_weigh_interval_days FROM species WHERE id=@id'),
    parameters: {'id': id},
  );
  if (spResult.isNotEmpty) {
    final fullData = jsonEncode({
      'uuid': spResult.first[0] as String,
      'name': spResult.first[1] as String,
      'nestlingEndDays': spResult.first[2] as int,
      'juvenileEndDays': spResult.first[3] as int,
      'nestlingWeighIntervalDays': spResult.first[4] as int,
      'juvenileWeighIntervalDays': spResult.first[5] as int,
      'adultWeighIntervalDays': spResult.first[6] as int,
    });
    await _db.execute(Sql.named(
      'INSERT INTO change_log (entity_type, entity_uuid, data, action) VALUES (@a,@b,@c,@d)'),
      parameters: {'a': 'species', 'b': spResult.first[0] as String, 'c': fullData, 'd': 'update_species'},
    );
    await _bumpVersion();
  }

  return Response.ok(jsonEncode({'ok': true}));
}

// ─── 用户管理 ───

Future<Response> _handleUsers(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{"error":"auth"}');

  final result = await _db.execute('''
    SELECT id, uuid, username, display_name, role, created_at, updated_at, deleted_at
    FROM users
    ORDER BY id ASC
  ''');

  final users = result
      .map((row) => {
            'id': row[0],
            'uuid': row[1],
            'username': row[2],
            'displayName': row[3],
            'role': row[4],
            'createdAt': (row[5] as DateTime).toIso8601String(),
            'updatedAt': (row[6] as DateTime?)?.toIso8601String(),
            'deletedAt': (row[7] as DateTime?)?.toIso8601String(),
            'isActive': row[7] == null,
          })
      .toList();

  return Response.ok(jsonEncode({'users': users}));
}

Future<Response> _handleCreateUser(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{"error":"auth"}');

  final body = jsonDecode(await req.readAsString());
  final username = body['username'] as String?;
  final displayName = body['displayName'] as String?;
  final password = body['password'] as String? ?? '';
  final role = body['role'] as String? ?? 'keeper';

  if (username == null || username.isEmpty) return Response(400, body: '{"error":"缺少用户名"}');
  if (displayName == null || displayName.isEmpty) return Response(400, body: '{"error":"缺少显示名称"}');
  if (!['admin', 'keeper', 'viewer'].contains(role)) return Response(400, body: '{"error":"无效角色"}');

  final uuid = _uuid.v4();
  final q = Sql.named('INSERT INTO users (uuid, username, display_name, password_hash, role) VALUES (@a,@b,@c,@d,@e)');
  await _db.execute(q, parameters: {'a': uuid, 'b': username, 'c': displayName, 'd': password, 'e': role});

  // 写入变更日志，手机端可通过 /changes 拉取
  final logQ = Sql.named('INSERT INTO change_log (entity_type, entity_uuid, data, action) VALUES (@a,@b,@c,@d)');
  await _db.execute(logQ, parameters: {
    'a': 'user',
    'b': uuid,
    'c': jsonEncode({'username': username, 'displayName': displayName, 'passwordHash': password, 'role': role}),
    'd': 'create_user',
  });
  await _bumpVersion();

  return Response.ok(jsonEncode({'uuid': uuid}));
}

Future<Response> _handleUpdateUser(Request req) async {
  if (!_checkAuth(req)) return Response.forbidden('{"error":"auth"}');

  final id = int.tryParse(req.params['id'] ?? '');
  if (id == null) return Response(400, body: '{"error":"invalid id"}');

  final body = jsonDecode(await req.readAsString());
  final updates = <String>[];
  final params = <String, dynamic>{'id': id};

  if (body.containsKey('displayName')) {
    updates.add('display_name=@dn');
    params['dn'] = body['displayName'];
  }
  if (body.containsKey('role')) {
    final role = body['role'] as String;
    if (!['admin', 'keeper', 'viewer'].contains(role)) return Response(400, body: '{"error":"无效角色"}');
    updates.add('role=@role');
    params['role'] = role;
  }
  if (body.containsKey('password') && (body['password'] as String).isNotEmpty) {
    updates.add('password_hash=@pw');
    params['pw'] = body['password'];
  }
  if (body.containsKey('isActive')) {
    if (body['isActive'] == true) {
      updates.add('deleted_at=NULL');
    } else {
      updates.add('deleted_at=CURRENT_TIMESTAMP');
    }
  }

  if (updates.isEmpty) return Response(400, body: '{"error":"无变更"}');
  updates.add('updated_at=CURRENT_TIMESTAMP');
  final q = Sql.named('UPDATE users SET ${updates.join(', ')} WHERE id=@id');
  await _db.execute(q, parameters: params);

  // 写入变更日志
  final userResult = await _db.execute(Sql.named('SELECT uuid FROM users WHERE id=@id'), parameters: {'id': id});
  if (userResult.isNotEmpty) {
    final userUuid = userResult.first[0] as String;
    final logQ = Sql.named('INSERT INTO change_log (entity_type, entity_uuid, data, action) VALUES (@a,@b,@c,@d)');
    await _db.execute(logQ, parameters: {
      'a': 'user',
      'b': userUuid,
      'c': jsonEncode(body),
      'd': 'update_user',
    });
    await _bumpVersion();
  }

  return Response.ok(jsonEncode({'ok': true}));
}

bool _checkAuth(Request req) {
  final token = (req.headers['x-token'] ?? req.headers['Authorization'] ?? '').replaceFirst('Bearer ', '');
  return _validTokens.contains(token);
}
