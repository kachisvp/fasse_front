import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "package:fasse_front/features/home/home_screen.dart";

// MyApp() 経由だと AuthGate の認証判定（非同期・ログイン画面遷移）を挟むため、
// Home/MasterMaintenance 画面の構造検証は対象画面を直接 pump する。
void main() {
  testWidgets("Home画面に3つの主要ボタンが縦に並ぶ", (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text("仕入伝票"), findsOneWidget);
    expect(find.text("売上伝票"), findsOneWidget);
    expect(find.text("マスタメンテナンス"), findsOneWidget);
  });

  testWidgets("マスタメンテナンス画面に4つのマスタボタンが縦に並ぶ", (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.tap(find.text("マスタメンテナンス"));
    await tester.pumpAndSettle();

    expect(find.text("品目"), findsOneWidget);
    expect(find.text("仕入先"), findsOneWidget);
    expect(find.text("メニュー"), findsOneWidget);
    expect(find.text("消費税率"), findsOneWidget);
  });
}
