import '../../shared/models/tax_category.dart';

class Menu {
  Menu({
    this.id,
    required this.menuName,
    required this.category,
    required this.standardPrice,
    required this.taxCategory,
    this.isActive = true,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id'] as int?,
      menuName: json['menu_name'] as String,
      category: json['category'] as String,
      standardPrice: json['standard_price'] as num,
      taxCategory: TaxCategory.fromApiValue(json['tax_category'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  final int? id;
  final String menuName;
  final String category;
  final num standardPrice;
  final TaxCategory taxCategory;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'menu_name': menuName,
      'category': category,
      'standard_price': standardPrice,
      'tax_category': taxCategory.apiValue,
      'is_active': isActive,
    };
  }
}
