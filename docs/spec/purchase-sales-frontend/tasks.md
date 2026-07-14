# 仕入・売上管理フロントエンド 実装タスク

## 1. 事前準備

- [x] Flutter プロジェクトの確認
- [x] 仕様書の雛形を作成
- [x] API ベース URL を環境変数で切り替えられる構成を作成

## 2. API 接続基盤

- [x] `lib/config/app_config.dart` を利用した API 呼び出し基盤を追加する
- [x] 共通の API エラー処理を実装する
- [x] APIレスポンスのパース失敗（既存データの不整合等）を分かりやすいメッセージに変換する処理を実装する
- [x] 一覧・登録編集フォーム画面に再試行ボタンを実装する

## 3. 画面・遷移実装

- [x] 初期画面に 3 つの主要ボタンを縦配置する
- [x] マスタメンテナンス画面に 4 つのサブボタン（品目・仕入先・メニュー・消費税率）を縦配置する
- [x] 左上の戻るボタンを実装する
- [x] 画面遷移（Home → MasterMaintenance → 各マスタ画面）を実装する

## 4. 機能実装

- [x] 品目マスタ画面（税区分の選択を含む）
- [x] 仕入先マスタ画面
- [x] メニューマスタ画面（税区分の選択を含む）
- [x] 消費税率マスタ画面
- [x] 仕入伝票画面（明細行の税率自動セット、一覧の直近7日デフォルト表示＋カレンダー期間選択、非active品目の選択肢除外を含む）
- [x] 売上伝票画面（明細行の税率自動セット、一覧の直近7日デフォルト表示＋カレンダー期間選択、支払方法の固定リスト選択、値引き額入力、非activeメニューの選択肢除外を含む）
- [x] 各フォームのクライアント側必須項目バリデーションを実装する

## 4. 確認

- [x] `flutter analyze` を通す
- [x] `flutter test` を通す
- [ ] stg 環境の API と疎通確認する（仕入伝票の一覧・詳細表示はブラウザで確認済み。既存データ不整合による不具合を1件発見・修正済み。他画面・他操作は未確認）

## 5. 認証機能実装（第二弾: Web + API Gateway + Lambda + DynamoDB）

- [x] `pubspec.yaml`に`flutter_secure_storage`・`flutter_web_auth_2`・`crypto`を追加する
- [x] `lib/features/auth/pkce.dart`: code_verifier/code_challenge生成を実装する
- [x] `lib/features/auth/auth_repository.dart`: ルートA（`/auth/token`）・ルートB（`/auth/token/cognito`）・Cognito Token Endpoint交換を実装する
- [x] `lib/features/auth/auth_session.dart`: 起動時判定フロー（SecureStorage確認→AccessKey試行→Cognitoログインへフォールバック）・401時のハンドリングを実装する（設計時点の`auth_controller.dart`から改称。`ApiClient`と共有する単一インスタンスとして実装）
- [x] `lib/features/auth/login_screen.dart`: Cognitoログインボタン画面を実装する
- [x] `lib/features/auth/auth_gate.dart`: 上記を`MyApp`の`home`にラップする
- [x] `web/auth_callback.html`: Cognitoからのリダイレクト受け先の静的ページを追加する（`flutter_web_auth_2`のWeb向けセットアップに準拠）
- [x] `lib/main.dart`: `AuthGate`を組み込む
- [x] `lib/shared/api/api_client.dart`: Authorizationヘッダー付与、401時の自動再取得・ログイン誘導を実装する
- [x] `.env.dummy`に`ACCESS_KEY`・`COGNITO_DOMAIN`・`COGNITO_CLIENT_ID`のダミー値を追加する
- [x] `flutter analyze` / `flutter test` を通す（`test/widget_test.dart`は`AuthGate`を経由しないよう`HomeScreen`を直接pumpする形に修正）
- [ ] （前提条件・fasse_infra側対応）Cognito App Client（publicクライアント・Authorization Code + PKCE）・Hosted UIドメイン・Callback URL（`web/auth_callback.html`のURL）の設定を依頼する
- [ ] stg環境で疎通確認する（AccessKeyパス・Cognitoパスの双方、および401時の再取得動作）
