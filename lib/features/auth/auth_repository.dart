import 'dart:convert';

import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../shared/api/api_client.dart';
import '../../shared/api/api_exception.dart';
import '../../shared/logging/app_logger.dart';
import 'pkce.dart';

/// fasse_infraのJWT発行API（ルートA/ルートB）とCognito Hosted UIを呼び出す。
/// 認証方式の詳細は ../../../fasse_infra/docs/spec/authentication/ を参照。
class AuthRepository {
  AuthRepository({ApiClient? apiClient, http.Client? httpClient})
    : _apiClient = apiClient ?? ApiClient(attachAuth: false),
      _httpClient = httpClient ?? http.Client();

  final ApiClient _apiClient;
  final http.Client _httpClient;

  /// Cognitoからのredirect先。Flutterのルーティングとは独立した静的ページとする
  /// （docs/spec/purchase-sales-frontend/design.md「Cognito Hosted UIとの連携」参照）。
  /// `COGNITO_CALLBACK_ORIGIN`が設定されていればその固定origin（stg配信ドメイン等）を使い、
  /// 未設定の場合は実行中のorigin（ローカル開発時はポート固定＋callback URL個別登録が必要）を使う。
  String get _redirectOrigin => AppConfig.cognitoCallbackOrigin ?? Uri.base.origin;

  String get _redirectUri => '$_redirectOrigin/auth_callback.html';

  /// ルートA（AccessKey）: `.env`のAccessKeyでJWTを取得する。
  /// AccessKey未設定の場合はnullを返し、呼び出し側でCognitoへフォールバックする。
  Future<String?> issueTokenByAccessKey() async {
    final accessKey = AppConfig.accessKey;
    if (accessKey == null) return null;
    final response = await _apiClient.post('/auth/token', body: {'accessKey': accessKey});
    return response['token'] as String;
  }

  /// ルートB（Cognito ID Token）: Cognitoから取得したID TokenでJWTを取得する。
  Future<String> issueTokenByCognito(String idToken) async {
    final response = await _apiClient.post('/auth/token/cognito', body: {'idToken': idToken});
    return response['token'] as String;
  }

  /// Cognito Hosted UIでログインし、最終的にfasse_infraのJWTを取得する（Authorization Code Grant + PKCE）。
  /// 別ウィンドウ（ポップアップ）で認証が完結するため、呼び出し元アプリはリロードされない。
  Future<String> loginWithCognito() async {
    final domain = AppConfig.cognitoDomain;
    final clientId = AppConfig.cognitoClientId;
    if (domain == null || clientId == null) {
      throw ApiException('Cognitoの設定が構成されていません');
    }

    final pkce = PkcePair.generate();
    final state = generateOAuthState();
    final redirectUri = _redirectUri;

    final authorizeUrl = Uri.parse('$domain/login').replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': 'openid email',
        'code_challenge': pkce.codeChallenge,
        'code_challenge_method': 'S256',
        'state': state,
      },
    );

    final String resultUrl;
    try {
      resultUrl = await FlutterWebAuth2.authenticate(
        url: authorizeUrl.toString(),
        callbackUrlScheme: 'https',
        // `auth_callback.html`のorigin（stg配信ドメイン等）と実行中のorigin（ローカル開発時のlocalhost:<port>）
        // が異なる場合でも、`postMessage`の送信元originとして扱われるよう明示的に指定する。
        // 未設定（null）の場合は`Uri.base.origin`が使われる（パッケージ側のデフォルト挙動）。
        options: FlutterWebAuth2Options(debugOrigin: AppConfig.cognitoCallbackOrigin),
      );
    } catch (e, stackTrace) {
      appLogger.e('Cognitoログインに失敗しました', error: e, stackTrace: stackTrace);
      throw ApiException('Cognitoログインがキャンセルまたは失敗しました');
    }

    final callbackUri = Uri.parse(resultUrl);
    final code = callbackUri.queryParameters['code'];
    if (callbackUri.queryParameters['state'] != state || code == null) {
      throw ApiException('Cognitoからの応答が不正です');
    }

    final idToken = await _exchangeAuthorizationCode(
      domain: domain,
      clientId: clientId,
      code: code,
      redirectUri: redirectUri,
      codeVerifier: pkce.codeVerifier,
    );

    return issueTokenByCognito(idToken);
  }

  /// Cognitoの`/oauth2/token`エンドポイントへ認可コードを交換し、ID Tokenを取得する。
  /// publicクライアント（シークレットなし）としてPKCEで検証する。
  Future<String> _exchangeAuthorizationCode({
    required String domain,
    required String clientId,
    required String code,
    required String redirectUri,
    required String codeVerifier,
  }) async {
    final http.Response response;
    try {
      response = await _httpClient.post(
        Uri.parse('$domain/oauth2/token'),
        headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'code': code,
          'redirect_uri': redirectUri,
          'code_verifier': codeVerifier,
        },
      );
    } catch (e, stackTrace) {
      appLogger.e('Cognito Token Endpointへの接続に失敗しました', error: e, stackTrace: stackTrace);
      throw ApiException('Cognitoからのトークン取得に失敗しました');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      appLogger.w('Cognito Token Endpointエラー: ${response.statusCode} ${response.body}');
      throw ApiException('Cognitoからのトークン取得に失敗しました');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final idToken = decoded['id_token'] as String?;
    if (idToken == null) {
      throw ApiException('Cognitoからのトークン取得に失敗しました');
    }
    return idToken;
  }
}
