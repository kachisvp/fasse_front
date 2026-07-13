class PurchaseDetail {
  PurchaseDetail({
    this.id,
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    required this.taxRate,
  });

  factory PurchaseDetail.fromJson(Map<String, dynamic> json) {
    return PurchaseDetail(
      id: json['id'] as String?,
      itemId: json['item_id'] as int,
      quantity: json['quantity'] as num,
      unitPrice: json['unit_price'] as num,
      amount: json['amount'] as num,
      taxRate: json['tax_rate'] as num,
    );
  }

  final String? id;
  final int itemId;
  final num quantity;
  final num unitPrice;
  final num amount;
  final num taxRate;

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'amount': amount,
      'tax_rate': taxRate,
    };
  }
}
