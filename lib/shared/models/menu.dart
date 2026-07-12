class Menu {
  final int? id;
  final String menuName;
  final String category;
  final double standardPrice;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Menu({
    this.id,
    required this.menuName,
    required this.category,
    required this.standardPrice,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      menuName: json['menu_name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      standardPrice: json['standard_price'] != null ? (json['standard_price'] as num).toDouble() : 0.0,
      isActive: json['is_active'] == null ? true : json['is_active'] as bool,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menu_name': menuName,
      'category': category,
      'standard_price': standardPrice,
      'is_active': isActive,
    };
  }
}
