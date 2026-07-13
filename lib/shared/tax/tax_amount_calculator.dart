import 'taxable_line.dart';

/// インボイス制度（適格請求書等保存方式）に基づき、
/// 「1つの伝票につき税率ごとに1回だけ端数処理（切り捨て）」する順序で消費税額を計算する。
class TaxAmountCalculator {
  const TaxAmountCalculator._();

  static num subtotal(List<TaxableLine> lines) {
    return lines.fold<num>(0, (sum, line) => sum + line.amount);
  }

  static num taxAmount(List<TaxableLine> lines) {
    final Map<num, num> rawTaxByRate = {};
    for (final line in lines) {
      rawTaxByRate.update(
        line.taxRate,
        (sum) => sum + line.amount * line.taxRate,
        ifAbsent: () => line.amount * line.taxRate,
      );
    }
    return rawTaxByRate.values.fold<num>(0, (sum, raw) => sum + raw.floor());
  }

  static num totalAmount(List<TaxableLine> lines, {num discountAmount = 0}) {
    return subtotal(lines) + taxAmount(lines) - discountAmount;
  }
}
