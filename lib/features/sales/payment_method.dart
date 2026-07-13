/// `payment_method` はAPI上は自由文字列だが、フロント側では表記ゆれを防ぐため固定リストから選択する。
class PaymentMethod {
  const PaymentMethod._();

  static const List<String> values = ['現金', 'クレジット', '電子マネー'];
}
