import 'api_exception.dart';

/// APIレスポンスのJSONをモデルに変換する際、想定と異なるデータ形式（フィールド欠落・型不一致等）
/// による生のDart例外（TypeError等）を、ユーザー向けの分かりやすい [ApiException] に変換する。
T parseApiResponse<T>(T Function() parse) {
  try {
    return parse();
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException('データの形式が想定と異なるため読み込めませんでした。既存データが現在の仕様と一致していない可能性があります（詳細: $e）');
  }
}
