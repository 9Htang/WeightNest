import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth_manager.dart';
import 'api_exception.dart';

export '../auth_manager.dart'; // re-export so subclasses see AuthManager

class AuthenticatedHttpClient {
  final String _baseUrl;
  final AuthManager _auth;

  AuthenticatedHttpClient({
    required String serverHost,
    required int serverPort,
    required AuthManager auth,
  })  : _baseUrl = 'http://$serverHost:$serverPort',
        _auth = auth;

  Map<String, String> get jsonHeaders =>
      {..._auth.authHeaders(), 'Content-Type': 'application/json'};

  Future<http.Response> get(String path,
      {Map<String, String>? params}) async {
    var uri = Uri.parse('$_baseUrl$path');
    if (params != null && params.isNotEmpty) {
      uri = uri.replace(queryParameters: params);
    }
    var res = await http
        .get(uri, headers: _auth.authHeaders())
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 403) {
      await _auth.refresh();
      res = await http
          .get(uri, headers: _auth.authHeaders())
          .timeout(const Duration(seconds: 10));
    }
    return res;
  }

  Future<http.Response> post(String path,
      {Map<String, dynamic>? body}) async {
    final b = body != null ? jsonEncode(body) : null;
    var res = await http
        .post(Uri.parse('$_baseUrl$path'), headers: jsonHeaders, body: b)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 403) {
      await _auth.refresh();
      res = await http
          .post(Uri.parse('$_baseUrl$path'), headers: jsonHeaders, body: b)
          .timeout(const Duration(seconds: 10));
    }
    return res;
  }

  Future<http.Response> patch(String path,
      {Map<String, dynamic>? body}) async {
    final b = body != null ? jsonEncode(body) : null;
    var res = await http
        .patch(Uri.parse('$_baseUrl$path'), headers: jsonHeaders, body: b)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 403) {
      await _auth.refresh();
      res = await http
          .patch(Uri.parse('$_baseUrl$path'), headers: jsonHeaders, body: b)
          .timeout(const Duration(seconds: 10));
    }
    return res;
  }

  /// Like [get] but throws [ApiException] on non-2xx status.
  Future<http.Response> checkedGet(String path,
      {Map<String, String>? params}) async {
    final res = await get(path, params: params);
    if (res.statusCode >= 400) throw ApiException(res.statusCode, res.body);
    return res;
  }

  /// Like [post] but throws [ApiException] on non-2xx status.
  Future<http.Response> checkedPost(String path,
      {Map<String, dynamic>? body}) async {
    final res = await post(path, body: body);
    if (res.statusCode >= 400) throw ApiException(res.statusCode, res.body);
    return res;
  }

  /// Like [patch] but throws [ApiException] on non-2xx status.
  Future<http.Response> checkedPatch(String path,
      {Map<String, dynamic>? body}) async {
    final res = await patch(path, body: body);
    if (res.statusCode >= 400) throw ApiException(res.statusCode, res.body);
    return res;
  }
}
