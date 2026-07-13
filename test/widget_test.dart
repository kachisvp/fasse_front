import "package:flutter_test/flutter_test.dart";

import "package:fasse_front/main.dart";

void main() {
  testWidgets("Home画面に3つの主要ボタンが縦に並ぶ", (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text("仕入伝票"), findsOneWidget);
    expect(find.text("売上伝票"), findsOneWidget);
    expect(find.text("マスタメンテナンス"), findsOneWidget);
  });

  testWidgets("マスタメンテナンス画面に4つのマスタボタンが縦に並ぶ", (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text("マスタメンテナンス"));
    await tester.pumpAndSettle();

    expect(find.text("品目"), findsOneWidget);
    expect(find.text("仕入先"), findsOneWidget);
    expect(find.text("メニュー"), findsOneWidget);
    expect(find.text("消費税率"), findsOneWidget);
  });
}
