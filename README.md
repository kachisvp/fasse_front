<details>

<summary>Mac環境構築</summary>

# Mac 環境構築

## Google Chrome

Google Chrome がインストールされていないと、[flutter doctor -v]が終了しないため、インストールする

## Git

### install

brew install git

### Terminal を開き、version を確認

git --version

### Git 初期設定

git config --global user.name "Namae Myoji"
git config --global user.email "_username_@example.com"

## SourceTree

### install

公式サイトからダウンロード、インストール

### Git Credential Manager

[Git Credential Manager]を install しないと、push するのに token が必要になる
[Git for Windows]の場合、[Git]の install 時に一緒に install される

```
brew install --cask git-credential-manager
```

## Flutter SDK

### install

[/Users/_username_/dev/flutter]となる様に保存

### PATH に追加

```
vi ~/.zshrc
export PATH=${HOME}/dev/flutter/bin:${PATH}
source ~/.zshrc
```

### Flutter が利用可能になったことを確認

Terminal を開き、以下のコマンドを実行

```
flutter --version
flutter doctor -v
```

**10 分程度、何も表示されずに処理に時間が掛かる可能性あり**

## Visual Studio Code

### install

すべてデフォルトでインストール

### Extensions

以下を検索して[install]を押下

- Flutter

## Visual Studio Code 動作確認手順

### Flutter

[fasse_front]プロジェクトを[Git Clone]
[fasse_front]プロジェクトを[Visual Studio Code]で開く
[Ctrl + @]を押下して[Terminal]を開く
以下のコマンドを実行する

```
flutter clean
flutter pub get
flutter build web
flutter run -d chrome
```

Chrome で Flutter アプリが動作することを確認

</details>

<details>

<summary>Windows環境構築</summary>

# Windows 環境構築

## Google Chrome

Google Chrome がインストールされていないと、[flutter doctor -v]が終了しないため、インストールする

## Git For Windows

### install

[Override the default branch name for new repositories]を選択 > [main]に変更
[Checkout as-is, commit as-is]を選択
他は default で[Next] > [Finish]を押下

### コマンドプロンプトを開き、version を確認

git --version

### Git 初期設定

git config --global user.name "Namae Myoji"
git config --global user.email "_username_@example.com"

## TortoiseGit

### install

すべてデフォルトでインストール

## Flutter SDK

### install

[C:\Users\'_username_'\dev\flutter\]となる様に保存

### システム環境変数に以下を追加

PATH=%PATH%;"C:\Users\'_username_'\dev\flutter\bin"

### Flutter が利用可能になっていることを確認

コマンドプロンプトを開き、以下のコマンドを実行

```
flutter --version
flutter doctor -v
```

**10 分程度、何も表示されずに処理に時間が掛かる可能性あり**

## Visual Studio Code

### install

すべてデフォルトでインストール

### Visual Studio Code Settings

[File] > [Preferences] > [Settings]を押下 > 右上の[Open Settings(JSON)]を押下
以下の設定を追加

```
{
    // "http.proxy": "http://_domain_:8080",
    // "https.proxy": "http://_domain_:8080",
    // "http.proxyStrictSSL": false
}
```

### Extensions

以下を検索して[install]を押下

- Flutter

## Visual Studio Code 動作確認手順

### Flutter

[fasse_front]プロジェクトを[Git Clone]
[fasse_front]プロジェクトを[Visual Studio Code]で開く
[Ctrl + @]を押下して[Terminal]を開く
以下のコマンドを実行する

```
flutter clean
flutter pub get
flutter build web
flutter run -d chrome
```

Chrome で Flutter アプリが動作することを確認

</details>

<details>

<summary>実装機能</summary>

# システム構成

- Database: MySQL
- Back-End: SpringBoot
- Front-End: Flutter

# 実装機能

- データ抽出、表示
- データ登録
- 画像登録
- ファイルアップロード、データ登録
- ファイルダウンロード
- PDF 出力
- ログイン
- ログアウト
- ログ出力
- オンデマンドバッチ

# テスト自動化

- SpringBoot のテスト自動化
- Flutter のテスト自動化

# 教育目標

- SpringBoot で MySQL からデータを抽出し、JSON データを返却できること
- SpringBoot で JSON データを MySQL に登録できること
- Flutter で WebAPI の GET メソッドをコールし、返却された JSON データを表示できること
- Flutter で WebAPI の POST メソッドをコールし、JSON データを送信できること

</details>
