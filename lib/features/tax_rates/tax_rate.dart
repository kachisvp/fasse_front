import '../../shared/models/tax_category.dart';

class TaxRate {
  TaxRate({
    required this.taxCategory,
    required this.description,
    required this.rate,
    required this.validFrom,
    this.validTo,
  });

  factory TaxRate.fromJson(Map<String, dynamic> json) {
    return TaxRate(
      taxCategory: TaxCategory.fromApiValue(json['tax_category'] as String),
      description: json['description'] as String,
      rate: json['rate'] as num,
      validFrom: json['valid_from'] as String,
      validTo: json['valid_to'] as String?,
    );
  }

  final TaxCategory taxCategory;
  final String description;
  final num rate;
  /// ISO8601日付文字列（例: 2026-07-13）
  final String validFrom;
  final String? validTo;

  Map<String, dynamic> toCreateJson() {
    return {
      'tax_category': taxCategory.apiValue,
      'description': description,
      'rate': rate,
      'valid_from': validFrom,
      'valid_to': validTo,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'description': description,
      'rate': rate,
      'valid_to': validTo,
    };
  }
}
