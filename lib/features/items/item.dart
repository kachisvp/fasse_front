import '../../shared/models/tax_category.dart';

class Item {
  Item({
    this.id,
    required this.itemName,
    required this.unit,
    this.standardPrice,
    required this.taxCategory,
    this.isActive = true,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int?,
      itemName: json['item_name'] as String,
      unit: json['unit'] as String,
      standardPrice: json['standard_price'] as num?,
      taxCategory: TaxCategory.fromApiValue(json['tax_category'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  final int? id;
  final String itemName;
  final String unit;
  final num? standardPrice;
  final TaxCategory taxCategory;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'item_name': itemName,
      'unit': unit,
      'standard_price': standardPrice,
      'tax_category': taxCategory.apiValue,
      'is_active': isActive,
    };
  }
}
