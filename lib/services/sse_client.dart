import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// SSE 事件客户端 — 连接服务器 /events 端点，监听数据变化通知
class SseClient {
  final String _url;
  final void Function(String event, String data)? onEvent;
  http.Client? _client;
  StreamSubscription? _sub;

  SseClient({required String serverHost, required int serverPort, this.onEvent})
      : _url = 'http://$serverHost:$serverPort/events';

  Future<void> connect() async {
    _client?.close();
    _client = http.Client();

    try {
      final request = http.Request('GET', Uri.parse(_url));
      final response = await _client!.send(request);

      if (response.statusCode == 200) {
        _sub = response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(_onLine);
      }
    } catch (_) {
      // 5秒后重试
      Future.delayed(const Duration(seconds: 5), connect);
    }
  }

  String _eventBuffer = '';
  String _dataBuffer = '';

  void _onLine(String line) {
    if (line.startsWith('event: ')) {
      _eventBuffer = line.substring(7);
    } else if (line.startsWith('data: ')) {
      _dataBuffer = line.substring(6);
    } else if (line.isEmpty && _dataBuffer.isNotEmpty) {
      onEvent?.call(_eventBuffer.isNotEmpty ? _eventBuffer : 'message', _dataBuffer);
      _eventBuffer = '';
      _dataBuffer = '';
    }
    // 忽略 heartbeat 注释行（以 : 开头）
  }

  void close() {
    _sub?.cancel();
    _client?.close();
  }
}
