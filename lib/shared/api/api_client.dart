import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../features/auth/auth_session.dart';
import '../logging/app_logger.dart';
import 'api_exception.dart';

/// `fasse_infra` の REST API（API Gateway + Lambda + DynamoDB）を呼び出す薄いラッパー。
/// レスポンスのエラー時は [ApiException] を投げ、画面側でハンドリングする。
///
/// `attachAuth: true`（デフォルト）の場合、[authSession] のJWTを`Authorization`ヘッダーへ付与し、
/// 401応答時はAccessKeyでの自動再取得・失敗時のログイン誘導を行う
/// （docs/spec/purchase-sales-frontend/design.md「JWTの付与・失効時の挙動」参照）。
/// ルートA/ルートB自身（[AuthRepository]内部）は認証対象外のため`attachAuth: false`で呼び出す。
class ApiClient {
  ApiClient({http.Client? httpClient, this.attachAuth = true})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final bool attachAuth;

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
    final response = await _send(
      () async => _httpClient.get(_uri(path, queryParameters), headers: await _headers()),
    );
    return _decodeBody(response);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final response = await _send(
      () async =>
          _httpClient.post(_uri(path), headers: await _headers(_jsonHeaders), body: jsonEncode(body)),
    );
    return _decodeBody(response);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final response = await _send(
      () async =>
          _httpClient.put(_uri(path), headers: await _headers(_jsonHeaders), body: jsonEncode(body)),
    );
    return _decodeBody(response);
  }

  Future<void> delete(String path) async {
    await _send(() async => _httpClient.delete(_uri(path), headers: await _headers()));
  }

  Future<Map<String, String>> _headers([Map<String, String>? base]) async {
    final headers = {...?base};
    if (!attachAuth) return headers;
    final jwt = await authSession.currentJwt();
    if (jwt != null) headers['Authorization'] = 'Bearer $jwt';
    return headers;
  }

  Future<http.Response> _send(Future<http.Response> Function() request, {bool isRetry = false}) async {
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

    if (attachAuth && response.statusCode == 401 && !isRetry) {
      final recovered = await authSession.handleUnauthorized();
      if (recovered) {
        return _send(request, isRetry: true);
      }
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
