import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// WeightNest mDNS 诊断工具
/// 用法:
///   dart run test_mdns.dart server [port]    — 启动 mDNS 发布端
///   dart run test_mdns.dart client           — 启动 mDNS 查询端
///   dart run test_mdns.dart                  — 本地自测（同机发布+查询）

const _serviceName = '_weightnest._tcp.local';
const _mDnsPort = 5354;
const _mDnsGroup = '224.0.0.251';

void main(List<String> args) async {
  final mode = args.isNotEmpty ? args[0] : 'self';

  print('=== WeightNest mDNS 诊断工具 ===');
  await _printNetworkInfo();

  switch (mode) {
    case 'server':
      final port = args.length > 1 ? int.parse(args[1]) : 8080;
      await _runServer(port);
    case 'client':
      await _runClient();
    default:
      await _selfTest();
  }
}

Future<void> _printNetworkInfo() async {
  print('\n--- 网络接口 ---');
  for (final iface in await NetworkInterface.list()) {
    for (final addr in iface.addresses) {
      if (addr.type == InternetAddressType.IPv4) {
        print('  ${iface.name}: ${addr.address}');
      }
    }
  }
}

// ============================================================
// Self-test: publisher + querier on same machine (loopback)
// ============================================================
Future<void> _selfTest() async {
  print('\n[1] 本地自测: 同机 mDNS 发布 + 查询');

  RawDatagramSocket? publisher;
  RawDatagramSocket? querier;

  try {
    // --- Publisher ---
    publisher = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4, _mDnsPort,
      reuseAddress: true, reusePort: true,
    );
    publisher.joinMulticast(InternetAddress(_mDnsGroup));
    print('  [PUB] 绑定 0.0.0.0:$_mDnsPort, 加入 $_mDnsGroup');

    // --- Querier ---
    querier = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4, 0,
      reuseAddress: true, reusePort: true,
    );
    querier.joinMulticast(InternetAddress(_mDnsGroup));
    print('  [QRY] 绑定随机端口, 加入 $_mDnsGroup');

    final received = Completer<Map<String, String>?>();

    // Querier listens for responses
    final qry = querier;
    querier.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = qry.receive();
      if (dg == null) return;
      _dumpPacket('  [QRY] ← 收到', dg);
      final txt = _parseTxtResponse(dg.data);
      if (txt != null) {
        print('  [QRY] ← TXT 解析成功: $txt');
        if (!received.isCompleted) received.complete(txt);
      }
    });

    // Publisher listens for queries and responds
    final p = publisher;
    publisher.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = p.receive();
      if (dg == null) return;
      _dumpPacket('  [PUB] ← 查询', dg);
      final names = _decodeDnsNames(dg.data);
      print('  [PUB] QNAMEs: $names');
      if (names.any((n) => n.contains('weightnest'))) {
        final ip = await _detectLanIp();
        final reply = _buildTxtResponse(dg.data, ip, 8080);
        p.send(reply, dg.address, dg.port);
        print('  [PUB] → 已回复 TXT');
      }
    });

    // Send PTR query
    final query = _buildPtrQuery(_serviceName);
    _dumpPacket('  [QRY] → 发送 PTR 查询', Datagram(query, InternetAddress(_mDnsGroup), _mDnsPort));
    qry.send(query, InternetAddress(_mDnsGroup), _mDnsPort);

    final result = await received.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    );

    print('');
    if (result != null) {
      print('✅ 本地 mDNS 自测通过');
      print('   服务信息: host=${result["host"]}, port=${result["port"]}');
    } else {
      print('❌ 本地 mDNS 自测失败');
      print('   可能原因: Windows 防火墙拦截多播、VirtualBox 网卡干扰');
      print('   尝试: netsh advfirewall firewall add rule name="mDNS" dir=in action=allow protocol=UDP localport=5354');
    }
  } catch (e) {
    print('❌ 异常: $e');
  } finally {
    publisher?.close();
    querier?.close();
  }
}

// ============================================================
// Server mode: continuously respond to mDNS queries
// ============================================================
Future<void> _runServer(int port) async {
  final host = await _detectLanIp();
  print('\n--- mDNS Server 模式 ---');
  print('发布服务: $_serviceName');
  print('地址: $host:$port');
  print('监听端口: $_mDnsPort');
  print('按 Ctrl+C 停止\n');

  final socket = await RawDatagramSocket.bind(
    InternetAddress.anyIPv4, _mDnsPort,
    reuseAddress: true, reusePort: true,
  );
  socket.joinMulticast(InternetAddress(_mDnsGroup));
  print('已启动, 等待查询...');

  final s = socket;
  s.listen((event) {
    if (event != RawSocketEvent.read) return;
    final dg = s.receive();
    if (dg == null) return;
    final names = _decodeDnsNames(dg.data);
    if (names.any((n) => n.contains('weightnest'))) {
      print('← 收到查询 from ${dg.address.address}:${dg.port}');
      final reply = _buildTxtResponse(dg.data, host, port);
      s.send(reply, dg.address, dg.port);
      print('→ 已回复 TXT: host=$host port=$port');
    }
  });

  // Keep alive
  await Completer<void>().future;
}

// ============================================================
// Client mode: query for service
// ============================================================
Future<void> _runClient() async {
  print('\n--- mDNS Client 模式 ---');
  print('查询服务: $_serviceName');
  print('多播地址: $_mDnsGroup:$_mDnsPort\n');

  final socket = await RawDatagramSocket.bind(
    InternetAddress.anyIPv4, 0,
    reuseAddress: true, reusePort: true,
  );
  socket.joinMulticast(InternetAddress(_mDnsGroup));

  final received = Completer<Map<String, String>?>();
  final s = socket;
  s.listen((event) {
    if (event != RawSocketEvent.read) return;
    final dg = s.receive();
    if (dg == null) return;
    final txt = _parseTxtResponse(dg.data);
    if (txt != null) {
      print('发现服务器: $txt');
      if (!received.isCompleted) received.complete(txt);
    } else {
      _dumpPacket('收到非目标响应', dg);
    }
  });

  final query = _buildPtrQuery(_serviceName);
  socket.send(query, InternetAddress(_mDnsGroup), _mDnsPort);
  print('→ 已发送 PTR 查询到 $_mDnsGroup:$_mDnsPort');

  final result = await received.future.timeout(
    const Duration(seconds: 10),
    onTimeout: () => null,
  );

  socket.close();

  if (result != null) {
    print('\n✅ 发现服务器: host=${result["host"]}, port=${result["port"]}');
  } else {
    print('\n❌ 未发现服务器 (10s 超时)');
    print('   检查清单:');
    print('   1. 服务端是否已启动: dart run test_mdns.dart server');
    print('   2. 两台设备是否在同一子网');
    print('   3. 路由器是否开启了 AP 隔离 (AP Isolation)');
    print('   4. Windows 防火墙是否拦截了 UDP $_mDnsPort');
    print('   5. 多播流量是否被交换机/路由器丢弃');
  }
}

// ============================================================
// DNS Helpers
// ============================================================
Uint8List _buildPtrQuery(String serviceName) {
  final nameBytes = _encodeDnsName(serviceName);
  return Uint8List.fromList([
    0x00, 0x01, // Transaction ID
    0x00, 0x00, // Flags: standard query
    0x00, 0x01, // QDCOUNT: 1
    0x00, 0x00, // ANCOUNT
    0x00, 0x00, // NSCOUNT
    0x00, 0x00, // ARCOUNT
    ...nameBytes,
    0x00,       // null terminator
    0x00, 0x0c, // QTYPE: PTR
    0x00, 0x01, // QCLASS: IN
  ]);
}

Uint8List _encodeDnsName(String name) {
  final buf = <int>[];
  for (final label in name.split('.')) {
    if (label.isEmpty) continue;
    buf.add(label.length);
    buf.addAll(utf8.encode(label));
  }
  return Uint8List.fromList(buf);
}

List<String> _decodeDnsNames(Uint8List data) {
  if (data.length < 12) return [];
  final qdCount = (data[4] << 8) | data[5];
  var pos = 12;
  final names = <String>[];
  for (var i = 0; i < qdCount; i++) {
    final labels = <String>[];
    while (pos < data.length && data[pos] != 0) {
      final len = data[pos];
      pos++;
      if (pos + len > data.length) break;
      labels.add(utf8.decode(data.sublist(pos, pos + len)));
      pos += len;
    }
    pos++; // null
    if (pos + 4 > data.length) break;
    final qtype = (data[pos] << 8) | data[pos + 1];
    pos += 4;
    if (qtype == 12) names.add(labels.join('.'));
  }
  return names;
}

Map<String, String>? _parseTxtResponse(Uint8List data) {
  if (data.length < 12) return null;
  final flags = (data[2] << 8) | data[3];
  final isResponse = (flags & 0x8000) != 0;
  if (!isResponse) return null;
  final anCount = (data[6] << 8) | data[7];
  if (anCount == 0) return null;

  // Skip header + questions to get to answers
  var pos = 12;
  final qdCount = (data[4] << 8) | data[5];
  for (var i = 0; i < qdCount; i++) {
    while (pos < data.length && data[pos] != 0) { pos++; } // skip name
    pos++; // null
    pos += 4; // QTYPE + QCLASS
  }

  // Parse answers
  for (var i = 0; i < anCount; i++) {
    if (pos + 10 > data.length) break;
    // Skip name (may be compressed with 0xc0 pointer)
    if (pos < data.length && (data[pos] & 0xc0) == 0xc0) {
      pos += 2; // compressed pointer
    } else {
      while (pos < data.length && data[pos] != 0) pos++;
      pos++; // null
    }
    if (pos + 10 > data.length) break;
    final rtype = (data[pos] << 8) | data[pos + 1];
    pos += 2; // TYPE
    pos += 2; // CLASS
    pos += 4; // TTL
    final rdLen = (data[pos] << 8) | data[pos + 1];
    pos += 2;
    if (pos + rdLen > data.length) break;

    if (rtype == 16 && rdLen > 1) {
      // TXT record — first byte is length prefix
      final txtLen = data[pos];
      if (txtLen > 0 && pos + 1 + txtLen <= data.length) {
        final txt = utf8.decode(data.sublist(pos + 1, pos + 1 + txtLen));
        final parts = <String, String>{};
        for (final p in txt.split(' ')) {
          final eq = p.indexOf('=');
          if (eq > 0) parts[p.substring(0, eq)] = p.substring(eq + 1);
        }
        if (parts.containsKey('host') && parts.containsKey('port')) {
          return parts;
        }
      }
    }
    pos += rdLen;
  }
  return null;
}

Uint8List _buildTxtResponse(Uint8List query, String host, int port) {
  final txt = 'host=$host port=$port';
  final txtBytes = utf8.encode(txt);

  // Build the TXT answer section
  final txtRdata = Uint8List.fromList([txtBytes.length, ...txtBytes]);

  // Full service name: weightnest._tcp.local → encoded
  final svcName = Uint8List.fromList([..._encodeDnsName(_serviceName), 0]);

  // Answer: NAME + TYPE(2) + CLASS(2) + TTL(4) + RDLENGTH(2) + RDATA
  final answer = Uint8List.fromList([
    // NAME pointer to service name at offset 12 (standard mDNS compression)
    0xc0, 0x0c,
    0x00, 0x10, // TYPE: TXT (16)
    0x00, 0x01, // CLASS: IN, cache-flush bit set for mDNS
    0x00, 0x00, 0x00, 0x78, // TTL: 120
    (txtRdata.length >> 8) & 0xff, txtRdata.length & 0xff, // RDLENGTH
    ...txtRdata,
  ]);

  return Uint8List.fromList([
    query[0], query[1], // echo Transaction ID
    0x84, 0x00, // Flags: QR=1(response), AA=1(authoritative)
    0x00, 0x00, // QDCOUNT: 0
    0x00, 0x01, // ANCOUNT: 1
    0x00, 0x00, // NSCOUNT
    0x00, 0x00, // ARCOUNT
    ...answer,
  ]);
}

// ============================================================
// Utils
// ============================================================
String _pickLocalIp() {
  // Return the LAN (192.168.x.x) IPv4 address
  // NetworkInterface.list() is async, so caller should handle this
  return '127.0.0.1';
}

Future<String> _detectLanIp() async {
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

void _dumpPacket(String label, Datagram dg) {
  final hex = dg.data.take(32).map((b) => '${b.toRadixString(16).padLeft(2, '0')}').join(' ');
  print('$label ${dg.data.length}B from ${dg.address.address}:${dg.port}  [$hex...]');
}
