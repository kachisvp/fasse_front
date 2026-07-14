import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  /// `--dart-define=API_BASE_URL=...`（コンパイル時に埋め込まれる）
  static const String _dartDefineApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// API のベース URL。
  /// `--dart-define=API_BASE_URL=...` を優先し、未指定の場合は `.env` の `API_BASE_URL` を使う
  /// （`flutter run -d chrome` のように dart-define を付けずに起動した場合のローカル開発向けフォールバック）。
  /// どちらも無い場合はローカルAPIサーバーのデフォルト値を使う。
  static String get apiBaseUrl {
    if (_dartDefineApiBaseUrl.isNotEmpty) return _dartDefineApiBaseUrl;
    final dotenvValue = dotenv.env['API_BASE_URL'];
    if (dotenvValue != null && dotenvValue.isNotEmpty) return dotenvValue;
    return 'http://localhost:8080';
  }

  /// ルートA（AccessKey認証）用のAccessKey。`.env`にのみ保持し、`--dart-define`では注入しない
  /// （docs/spec/purchase-sales-frontend/design.md「AccessKey（.env）」参照）。
  /// 未設定の場合はルートAを利用せず、Cognitoログインへフォールバックする。
  static String? get accessKey {
    final value = dotenv.env['ACCESS_KEY'];
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Cognito Hosted UIのドメイン（例: `https://<prefix>.auth.<region>.amazoncognito.com`）
  static const String _dartDefineCognitoDomain = String.fromEnvironment('COGNITO_DOMAIN');
  static String? get cognitoDomain =>
      _resolve(dartDefineValue: _dartDefineCognitoDomain, dotenvKey: 'COGNITO_DOMAIN');

  /// Cognito App Client ID（publicクライアント）
  static const String _dartDefineCognitoClientId = String.fromEnvironment('COGNITO_CLIENT_ID');
  static String? get cognitoClientId =>
      _resolve(dartDefineValue: _dartDefineCognitoClientId, dotenvKey: 'COGNITO_CLIENT_ID');

  /// Cognitoに登録するCallback URLのorigin（例: `https://<stg配信ドメイン>`）。
  /// stgにデプロイ済みの `auth_callback.html` を指す固定originを設定することで、
  /// Cognito App Clientへのcallback URL登録を1件に固定できる。
  /// `flutter_web_auth_2`の`FlutterWebAuth2Options.debugOrigin`と組み合わせて、
  /// ローカル開発時のポート番号に依存せずCognitoログインを検証できるようにする
  /// （docs/spec/purchase-sales-frontend/design.md「Cognito Hosted UIとの連携」参照）。
  /// 未設定の場合は実行中のorigin（`Uri.base.origin`）を使う（要: ポート固定＋callback URL個別登録）。
  static const String _dartDefineCognitoCallbackOrigin = String.fromEnvironment(
    'COGNITO_CALLBACK_ORIGIN',
  );
  static String? get cognitoCallbackOrigin => _resolve(
    dartDefineValue: _dartDefineCognitoCallbackOrigin,
    dotenvKey: 'COGNITO_CALLBACK_ORIGIN',
  );

  static String? _resolve({required String dartDefineValue, required String dotenvKey}) {
    if (dartDefineValue.isNotEmpty) return dartDefineValue;
    final dotenvValue = dotenv.env[dotenvKey];
    return (dotenvValue == null || dotenvValue.isEmpty) ? null : dotenvValue;
  }
}
