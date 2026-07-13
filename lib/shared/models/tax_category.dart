/// 消費税法で定まる固定区分（標準税率/軽減税率/非課税）。
/// `fasse_infra` の `TaxCategory` ENUM（openapi.yaml）に対応する。
enum TaxCategory {
  standard('STANDARD', '標準税率'),
  reduced('REDUCED', '軽減税率'),
  exempt('EXEMPT', '非課税');

  const TaxCategory(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static TaxCategory fromApiValue(String value) {
    return TaxCategory.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => throw ArgumentError('未知の税区分です: $value'),
    );
  }
}
