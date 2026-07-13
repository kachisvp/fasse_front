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
}
