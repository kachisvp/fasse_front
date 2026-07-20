# Flutter - Agent Instructions

ルートの `CLAUDE.md` の方針（言語、セキュリティ、仕様駆動開発）を前提とする。

## 仕様駆動開発

- 画面追加・修正を行う前に、このフォルダ配下（または対象機能配下）に `requirements.md` / `design.md` / `tasks.md` を作成・更新し、承認を得ること
- `design.md` には画面遷移、状態管理方針、APIとの連携方法、ウィジェット構成を記載すること

## セキュリティ

- APIキーやトークンをソースコードに直接記述せず、`.env` や `flutter_dotenv`、Secure Storage等で管理すること
- 端末内に機密情報を保存する場合は `flutter_secure_storage` 等の暗号化ストレージを使用すること（`SharedPreferences` に平文保存しない）
- 通信は必ずHTTPSを使用し、証明書検証を無効化しないこと
- ディープリンク・URLスキームは入力値検証を行い、不正な遷移を防ぐこと
- 難読化（`--obfuscate`）とデバッグシンボル分離をリリースビルドで有効化すること
- 権限（カメラ、位置情報等）は必要最小限のみ要求し、用途を明示すること

## 実装方針

- 状態管理は原則プロジェクトで統一した手法（例: Riverpod, Bloc等）に従うこと
- ウィジェットは可能な限り小さく分割し、再利用性を意識すること
- `null safety` を活かし、不要な `!`（null許容の強制解除）を避けること
- Lintルール（`flutter_lints`等）に従い、`flutter analyze` を通すこと

## ログ出力

- `print` や `debugPrint` の直接使用、`console.log`相当のその場限りの出力を残さないこと。`logger`パッケージ等の専用ロガーを導入し、ログレベル（error/warning/info/debug）を使い分けること
- リリースビルドでは不要なデバッグログが出力されないよう、ログレベルやビルドモード（`kReleaseMode`等）で制御すること
- クラッシュ・エラー発生時の調査のため、Firebase Crashlytics等のクラッシュレポートツール導入を検討すること
- ログにAPIキー、トークン、個人情報等の機密情報を出力しないこと

## 例外処理

- 例外を空の`catch`ブロックで握りつぶさないこと。捕捉した例外は必ずログ出力し、必要に応じて呼び出し元に伝播させること
- APIエラーやネットワークエラー発生時は、ユーザーに分かりやすいエラーメッセージ（例: SnackBar、ダイアログ）を表示すること。技術的なエラー内容をそのままユーザーに見せないこと
- 予期しない例外を捕捉するため、`runZonedGuarded` や `FlutterError.onError` 等を用いたグローバルなエラーハンドリングを実装すること
- 非同期処理（`Future`/`async`）は `try-catch` で確実にエラーハンドリングし、未処理の例外（Unhandled Exception）を残さないこと

## テスト自動化

- ビジネスロジック（Repository, UseCase, StateNotifier/Bloc等）は `flutter test` によるユニットテストで検証すること
- 主要なウィジェットにはウィジェットテスト（`testWidgets`）を追加し、表示内容やユーザー操作への反応を検証すること
- 外部API・DB等の依存はモック（`mocktail`, `mockito`等）に置き換え、テストの再現性を担保すること
- 主要なユーザーシナリオ（ログイン、購入等のクリティカルパス）には `integration_test` によるE2Eテストを整備すること
- CI（GitHub Actions等）で `flutter analyze` と `flutter test` を自動実行し、失敗時はマージをブロックすること
- カバレッジ計測（`flutter test --coverage`）を行い、低下傾向を継続的に確認すること
- 新規機能追加・バグ修正時は、対応するテストコードを同一PR内に含めること

## コマンド例

```bash
# 依存パッケージの取得
flutter pub get

# 静的解析（Lintチェック）
flutter analyze

# コードフォーマットチェック
dart format --output=none --set-exit-if-changed .

# テスト実行
flutter test

# カバレッジ付きテスト実行
flutter test --coverage

# 結合（E2E）テスト実行
flutter test integration_test

# ビルド（リリース、例: Android）
flutter build apk --release
```
