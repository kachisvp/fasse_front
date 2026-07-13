import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../logging/app_logger.dart';
import 'api_exception.dart';

/// `fasse_infra` の REST API（API Gateway + Lambda + DynamoDB）を呼び出す薄いラッパー。
/// レスポンスのエラー時は [ApiException] を投げ、画面側でハンドリングする。
class ApiClient {
  ApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json; charset=utf-8',
  };

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final query = queryParameters?.entries
        .where((e) => e.value.isNotEmpty)
        .fold<Map<String, String>>({}, (map, e) => map..[e.key] = e.value);
    return Uri.parse('${AppConfig.apiBaseUrl}$path').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParameters}) async {
    final response = await _send(() => _httpClient.get(_uri(path, queryParameters)));
    return _decodeBody(response);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final response = await _send(
      () => _httpClient.post(_uri(path), headers: _jsonHeaders, body: jsonEncode(body)),
    );
    return _decodeBody(response);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final response = await _send(
      () => _httpClient.put(_uri(path), headers: _jsonHeaders, body: jsonEncode(body)),
    );
    return _decodeBody(response);
  }

  Future<void> delete(String path) async {
    await _send(() => _httpClient.delete(_uri(path)));
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    late final http.Response response;
    try {
      response = await request();
    } catch (e, stackTrace) {
      appLogger.e('API呼び出しに失敗しました', error: e, stackTrace: stackTrace);
      throw ApiException('サーバーに接続できませんでした');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    final message = _extractErrorMessage(response);
    appLogger.w('APIエラー: ${response.statusCode} $message');
    throw ApiException(message, statusCode: response.statusCode);
  }

  dynamic _decodeBody(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {
      // レスポンスがJSONでない場合はデフォルトメッセージにフォールバックする
    }
    return 'サーバーエラーが発生しました（${response.statusCode}）';
  }
}
