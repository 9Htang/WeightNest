import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

/// Minimal HTTP + mDNS test — run on desktop, test reachability from phone
void main() async {
  final app = Router()
    ..get('/health', (Request req) => Response.ok('{"status":"ok"}'));

  final server = await shelf_io.serve(app, InternetAddress.anyIPv4, 9090);
  final ip = await _pickLanIp();
  print('Test HTTP server running on http://$ip:9090/health');
  print('From phone: curl http://$ip:9090/health');

  // mDNS responder
  RawDatagramSocket? mDns;
  try {
    mDns = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 5354,
        reuseAddress: true, reusePort: true);
    mDns.joinMulticast(InternetAddress('224.0.0.251'));
    print('mDNS responder on port 5354');
  } catch (e) {
    print('mDNS port 5354 in use: $e');
  }

  if (mDns != null) {
    final s = mDns;
    s.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = s.receive();
      if (dg == null) return;
      final names = _decodeDnsNames(dg.data);
      if (names.any((n) => n.contains('weightnest'))) {
        print('mDNS query from ${dg.address.address}');
        final reply = _buildTxtResponse(dg.data, ip, 9090);
        s.send(reply, dg.address, dg.port);
        print('mDNS replied: $ip:9090');
      }
    });
  }
}

Future<String> _pickLanIp() async {
  for (final iface in await NetworkInterface.list()) {
    final name = iface.name.toLowerCase();
    if (name.contains('vmware') || name.contains('virtual') || name.contains('vethernet')) continue;
    for (final addr in iface.addresses) {
      if (addr.type == InternetAddressType.IPv4 &&
          (addr.address.startsWith('192.168.') || addr.address.startsWith('10.'))) {
        return addr.address;
      }
    }
  }
  return '127.0.0.1';
}

List<String> _decodeDnsNames(Uint8List data) {
  if (data.length < 12) return [];
  final qdCount = (data[4] << 8) | data[5];
  var pos = 12;
  final names = <String>[];
  for (var i = 0; i < qdCount; i++) {
    final labels = <String>[];
    while (pos < data.length && data[pos] != 0) {
      final len = data[pos]; pos++;
      if (pos + len > data.length) break;
      labels.add(utf8.decode(data.sublist(pos, pos + len)));
      pos += len;
    }
    pos++; if (pos + 4 > data.length) break;
    final qtype = (data[pos] << 8) | data[pos + 1]; pos += 4;
    if (qtype == 12) names.add(labels.join('.'));
  }
  return names;
}

Uint8List _buildTxtResponse(Uint8List query, String host, int port) {
  final txt = 'host=$host port=$port';
  final txtBytes = utf8.encode(txt);
  final rdata = <int>[txtBytes.length, ...txtBytes];
  final name = <int>[0x0b, ...'_weightnest'.codeUnits, 0x04, ...'_tcp'.codeUnits, 0x05, ...'local'.codeUnits, 0x00];
  final answer = <int>[
    ...name,
    0x00, 0x10,
    0x00, 0x01,
    0x00, 0x00, 0x00, 0x78,
    (rdata.length >> 8) & 0xff, rdata.length & 0xff,
    ...rdata,
  ];
  return Uint8List.fromList([
    query[0], query[1],
    0x84, 0x00,
    0x00, 0x00,
    0x00, 0x01,
    0x00, 0x00,
    0x00, 0x00,
    ...answer,
  ]);
}
