import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:multicast_dns/multicast_dns.dart';

class DiscoveredServer {
  final String host;
  final int port;
  const DiscoveredServer({required this.host, required this.port});

  String get baseUrl => 'http://$host:$port';
}

class DiscoveryClient {
  /// mDNS 发现 (RFC 6762)
  static Future<DiscoveredServer?> discover({Duration timeout = const Duration(seconds: 4)}) async {
    final client = MDnsClient();
    try {
      await client.start(mDnsPort: 5354);
      final List<DiscoveredServer> found = [];

      await for (final ptr in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_weightnest._tcp.local'),
        timeout: timeout,
      )) {
        try {
          await for (final txt in client.lookup<TxtResourceRecord>(
            ResourceRecordQuery.text(ptr.domainName),
            timeout: const Duration(seconds: 2),
          )) {
            final text = txt.text;
            final parts = <String, String>{};
            for (final part in text.split(' ')) {
              final eq = part.indexOf('=');
              if (eq > 0) parts[part.substring(0, eq)] = part.substring(eq + 1);
            }
            final host = parts['host'];
            final portStr = parts['port'];
            if (host != null && host.isNotEmpty && portStr != null) {
              final port = int.tryParse(portStr);
              if (port != null) found.add(DiscoveredServer(host: host, port: port));
            }
          }
        } catch (_) {}
      }
      return found.isNotEmpty ? found.first : null;
    } catch (e) {
      return null;
    } finally {
      client.stop();
    }
  }

  /// 子网 HTTP 扫描 — 并行探测同网段 :8080
  /// 从本机 LAN IP 推测子网，扫描 .1 ~ .254
  static Future<DiscoveredServer?> subnetScan({int port = 8080, Duration timeout = const Duration(seconds: 3)}) async {
    final lanIp = await _getLanIp();
    if (lanIp == null) return null;

    final parts = lanIp.split('.');
    final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';
    final mySuffix = int.tryParse(parts[3]) ?? 1;

    // Priority scan order: gateway, nearby IPs, then full sweep
    final candidates = <int>[
      1, // gateway most likely
      mySuffix, // same IP as this device (if desktop=server)
      2, 3, 4, 5, 6, 7, 8, 9, 10, // common DHCP low range
    ];
    // Then 11-254, but push mySuffix's neighbors first
    for (var i = 11; i <= 254; i++) {
      if (!candidates.contains(i)) candidates.add(i);
    }

    // 分批并行探测，每批 20 个
    final found = Completer<DiscoveredServer?>();
    var batchSize = 20;
    var idx = 0;

    while (idx < candidates.length && !found.isCompleted) {
      final batch = candidates.skip(idx).take(batchSize).toList();
      idx += batchSize;

      final futures = batch.map((suffix) async {
        if (found.isCompleted) return;
        try {
          final ip = '$prefix.$suffix';
          final res = await http
              .get(Uri.parse('http://$ip:$port/health'))
              .timeout(timeout);
          if (res.statusCode == 200 && res.body.contains('"status":"ok"')) {
            if (!found.isCompleted) {
              found.complete(DiscoveredServer(host: ip, port: port));
            }
          }
        } catch (_) {}
      });

      // 等待当前批次完成或发现结果
      await Future.any([
        Future.wait(futures),
        Future.delayed(timeout * 2),
      ]);
    }

    if (found.isCompleted) return await found.future;
    return null;
  }

  /// 获取本机 LAN IP
  static Future<String?> getLanIp() => _getLanIp();

  static Future<String?> _getLanIp() async {
    try {
      for (final iface in await NetworkInterface.list()) {
        final name = iface.name.toLowerCase();
        // Skip virtual/VM/VPN/TUN interfaces
        if (name.contains('vmware') || name.contains('virtual') ||
            name.contains('vethernet') || name.contains('hyper-v') ||
            name.contains('tun') || name.contains('tap') ||
            name.contains('utun') || name.contains('clash') ||
            name.contains('mihomo') || name.contains('vpn') ||
            name.contains('ppp') || name.contains('pppoe') ||
            name.contains('wintun')) continue;
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            final a = addr.address;
            if (a.startsWith('127.')) continue;
            if (a.startsWith('169.254.')) continue;
            if (a.startsWith('198.18.')) continue; // TUN/VPN test ranges
            if (a.startsWith('172.17.')) continue; // Docker bridge
            if (a.startsWith('192.168.') || a.startsWith('10.')) return a;
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
