# 仕入・売上管理フロントエンド 設計

## アーキテクチャ

Flutter アプリを feature-first で整理し、API 呼び出しは `lib/config` と `lib/features/*/data` で管理する。

## 画面構成

- Home: 初期画面。主要機能への入口として 3 つのボタンを縦配置
- MasterMaintenance: マスタメンテナンスのサブメニュー画面
- Items: 品目マスタ。一覧・追加・変更・削除を行う
- Suppliers: 仕入先マスタ。一覧・追加・変更・削除を行う
- Menus: メニューマスタ。一覧・追加・変更・削除を行う
- Purchases: 仕入伝票。一覧・追加・変更・削除を行う
- Sales: 売上伝票。一覧・追加・変更・削除を行う

## 画面遷移

- 起動直後の Home 画面では、上から順に「仕入伝票」「売上伝票」「マスタメンテナンス」の 3 つを表示する
- 「マスタメンテナンス」押下時に MasterMaintenance 画面へ遷移する
- MasterMaintenance 画面では、上から順に「品目」「仕入先」「メニュー」の 3 つを表示する
- 各ボタン押下時に、対象 domain の一覧画面へ遷移する
- 一覧画面から、追加・変更・削除の操作を行うための画面遷移を用意する
- API の GET/POST/PUT/DELETE を適切に使い分けて、WebAPI の機能をフル活用する
- 戻るボタンは AppBar の leading もしくは左上固定ボタンとして配置し、前の画面へ戻る

## API 連携方針

- ベース URL は `API_BASE_URL` で注入する
- `package:http` を利用して REST API を呼び出す
- 例: `GET /items`, `POST /purchases`, `GET /sales?from=...&to=...`
- レスポンスのエラー時は `Exception` を投げ、画面側でハンドリングする
- JSON レスポンスは RFC 8259 により常に UTF-8 であるため、`response.body` は使わず
  `utf8.decode(response.bodyBytes)` で明示的に decode してから `jsonDecode` する
  （サーバーの `Content-Type` に `charset` が無いと `response.body` は Latin-1 として
  decode され文字化けするため）

## ディレクトリ構成

```text
lib/
  config/
    app_config.dart
  features/
    items/
    suppliers/
    menus/
    purchases/
    sales/
  shared/
```

## 環境変数

```bash
flutter run --dart-define=API_BASE_URL=https://<api-id>.execute-api.<region>.amazonaws.com/stg
```

## 状態管理

- 初期実装では `setState` ベース
- 画面遷移状態は `Navigator.push/pop` で管理する

## レイアウト配慮

- 画面幅が狭い場合でもボタンが押しやすいよう、余白を確保し、縦並びのままスクロールできるようにする
- ボタン高さは十分に確保し、タップしやすいサイズにする
- 一覧表示は必要に応じて `SingleChildScrollView` や `ListView` でスクロール可能にする
