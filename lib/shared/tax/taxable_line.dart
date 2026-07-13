/// 消費税額の計算対象となる明細行の最小情報（仕入明細・売上明細で共通）。
class TaxableLine {
  const TaxableLine({required this.amount, required this.taxRate});

  final num amount;
  final num taxRate;
}
