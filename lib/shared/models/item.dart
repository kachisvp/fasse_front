class Item {
  final int? id;
  final String itemName;
  final String unit;
  final double? standardPrice;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Item({
    this.id,
    required this.itemName,
    required this.unit,
    this.standardPrice,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      itemName: json['item_name'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      standardPrice: json['standard_price'] != null ? (json['standard_price'] as num).toDouble() : null,
      isActive: json['is_active'] == null ? true : json['is_active'] as bool,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_name': itemName,
      'unit': unit,
      if (standardPrice != null) 'standard_price': standardPrice,
      'is_active': isActive,
    };
  }
}
