class SalesDetail {
  SalesDetail({
    this.id,
    required this.menuId,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    required this.taxRate,
  });

  factory SalesDetail.fromJson(Map<String, dynamic> json) {
    return SalesDetail(
      id: json['id'] as String?,
      menuId: json['menu_id'] as int,
      quantity: json['quantity'] as int,
      unitPrice: json['unit_price'] as num,
      amount: json['amount'] as num,
      taxRate: json['tax_rate'] as num,
    );
  }

  final String? id;
  final int menuId;
  final int quantity;
  final num unitPrice;
  final num amount;
  final num taxRate;

  Map<String, dynamic> toJson() {
    return {
      'menu_id': menuId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'amount': amount,
      'tax_rate': taxRate,
    };
  }
}
