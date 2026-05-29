import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// 桌面端 mDNS 服务发布器（RFC 6762 简化实现）
/// 监听 5353 端口，响应 _weightnest._tcp.local 查询
class DiscoveryServer {
  RawDatagramSocket? _socket;
  final String _host;
  final int _port;
  final String _instanceName;
  bool _running = false;

  DiscoveryServer({required String host, required int port, String instanceName = 'weightnest'})
      : _host = host,
        _port = port,
        _instanceName = instanceName;

  bool get isRunning => _running;

  Future<void> start() async {
    if (_running) return;
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 5354,
          reuseAddress: true, reusePort: true);
      _socket!.setRawOption(RawSocketOption.fromInt(1, 3, 255)); // IP_MULTICAST_TTL
      _socket!.joinMulticast(InternetAddress('224.0.0.251'));
      _running = true;
      _socket!.listen(_onData);
    } catch (e) {
      _running = false;
    }
  }

  void _onData(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final sock = _socket;
    if (sock == null) return;
    try {
      final datagram = sock.receive();
      if (datagram == null) return;

      // 解析 DNS 查询，检查是否是 _weightnest._tcp.local
      final queries = _decodeQuestions(datagram.data);
      for (final q in queries) {
        if (q == '_weightnest._tcp.local') {
          _sendResponse(sock, datagram);
          break;
        }
      }
    } catch (_) {}
  }

  /// 简单 DNS 问题解析（只检查 QNAME 是否匹配我们的服务）
  List<String> _decodeQuestions(Uint8List data) {
    if (data.length < 12) return [];
    // DNS header: 12 bytes, skip to questions
    final qdCount = (data[4] << 8) | data[5];
    if (qdCount == 0) return [];
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
      pos++; // skip null terminator
      if (pos + 4 > data.length) break; // QTYPE + QCLASS
      final qtype = (data[pos] << 8) | data[pos + 1];
      pos += 4;

      if (qtype == 12) {
        // PTR query
        names.add(labels.join('.'));
      }
    }
    return names;
  }

  /// 发送 mDNS 应答
  void _sendResponse(RawDatagramSocket sock, Datagram query) {
    // 编码服务名: weightnest._tcp.local → \x09weightnest\x04_tcp\x05local\x00
    final serviceName = _encodeDnsName(_instanceName);
    final typeName = _encodeDnsName('_tcp');
    final localName = _encodeDnsName('local');
    final fullName = Uint8List.fromList([
      ...serviceName,
      ...typeName,
      ...localName,
      0,
    ]);

    // TXT 记录数据
    final txtData = utf8.encode('host=$_host port=$_port');

    // DNS 响应头 (12 bytes)
    final header = Uint8List.fromList([
      query.data[0], query.data[1], // Transaction ID (echo)
      0x84, 0x00, // Flags: response, authoritative
      0x00, 0x00, // Questions: 0
      0x00, 0x02, // Answers: 2 (PTR + TXT)
      0x00, 0x00, // Authority: 0
      0x00, 0x00, // Additional: 0
    ]);

    // PTR Answer
    final ptrAnswer = _buildAnswer(fullName, 12, 0x00, // PTR type
        Uint8List.fromList([0xc0, 0x0c])); // pointer to name at offset 12

    // TXT Answer
    final txtAnswer = _buildAnswer(fullName, 16, 0x00, // TXT type
        Uint8List.fromList([txtData.length, ...txtData]));

    final response = Uint8List.fromList([
      ...header,
      ...ptrAnswer,
      ...txtAnswer,
    ]);

    sock.send(response, query.address, query.port);
  }

  Uint8List _encodeDnsName(String label) {
    return Uint8List.fromList([label.length, ...utf8.encode(label)]);
  }

  Uint8List _buildAnswer(Uint8List name, int type, int klass, Uint8List rdata) {
    // NAME + TYPE(2) + CLASS(2) + TTL(4) + RDLENGTH(2) + RDATA
    return Uint8List.fromList([
      ...name,
      (type >> 8) & 0xFF, type & 0xFF,
      (klass >> 8) & 0xFF, klass & 0xFF,
      0x00, 0x00, 0x00, 0x78, // TTL 120 seconds
      (rdata.length >> 8) & 0xFF, rdata.length & 0xFF,
      ...rdata,
    ]);
  }

  void stop() {
    _running = false;
    _socket?.close();
    _socket = null;
  }
}
