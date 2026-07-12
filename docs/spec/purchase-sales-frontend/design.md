# 仕入・売上管理フロントエンド 設計

## アーキテクチャ

Flutter アプリを feature-first で整理し、API 呼び出しは `lib/config` と `lib/features/*/data` で管理する。

## 画面構成

- Home: 主要機能への入口
- Items: 品目マスタ
- Suppliers: 仕入先マスタ
- Menus: メニューマスタ
- Purchases: 仕入伝票
- Sales: 売上伝票

## API 連携方針

- ベース URL は `API_BASE_URL` で注入する
- `package:http` を利用して REST API を呼び出す
- 例: `GET /items`, `POST /purchases`, `GET /sales?from=...&to=...`
- レスポンスのエラー時は `Exception` を投げ、画面側でハンドリングする

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
- 将来的な拡張時に Riverpod へ移行する前提
