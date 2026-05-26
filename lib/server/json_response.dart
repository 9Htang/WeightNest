import 'dart:convert';
import 'package:shelf/shelf.dart';

/// JSON 响应工具
Response jsonResponse(Map<String, dynamic> data, {int statusCode = 200}) {
  return Response(
    statusCode,
    headers: {'Content-Type': 'application/json; charset=utf-8'},
    body: jsonEncode(data),
  );
}

Response jsonList(List<Map<String, dynamic>> data) {
  return jsonResponse({'success': true, 'data': data});
}

Response jsonItem(Map<String, dynamic> data) {
  return jsonResponse({'success': true, 'data': data});
}

Response jsonError(String message, {int statusCode = 400}) {
  return jsonResponse({'success': false, 'error': message}, statusCode: statusCode);
}

/// 解析请求 body 为 JSON Map
Future<Map<String, dynamic>> parseBody(Request request) async {
  final body = await request.readAsString();
  if (body.isEmpty) return {};
  return jsonDecode(body) as Map<String, dynamic>;
}
