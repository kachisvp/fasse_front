import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  static final http.Client _client = http.Client();

  static Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$normalizedPath');
    return queryParameters == null ? uri : uri.replace(queryParameters: queryParameters);
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  static Future<http.Response> get(String path, {Map<String, String>? queryParameters}) async {
    final response = await _client.get(_buildUri(path, queryParameters), headers: _headers);
    _throwOnError(response);
    return response;
  }

  static Future<http.Response> post(String path, Object body) async {
    final response = await _client.post(
      _buildUri(path),
      headers: _headers,
      body: jsonEncode(body),
    );
    _throwOnError(response, allow204: false);
    return response;
  }

  static Future<http.Response> put(String path, Object body) async {
    final response = await _client.put(
      _buildUri(path),
      headers: _headers,
      body: jsonEncode(body),
    );
    _throwOnError(response, allow204: false);
    return response;
  }

  static Future<http.Response> delete(String path) async {
    final response = await _client.delete(_buildUri(path), headers: _headers);
    _throwOnError(response, allow204: true);
    return response;
  }

  static void _throwOnError(http.Response response, {bool allow204 = true}) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      if (status == 204 && allow204) {
        return;
      }
      if (status == 204) {
        return;
      }
      return;
    }

    var message = 'HTTP $status';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['message'] is String) {
        message = body['message'] as String;
      }
    } catch (_) {
      // ignore
    }
    throw ApiException(message);
  }
}
