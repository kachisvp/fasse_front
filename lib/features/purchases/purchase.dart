import 'purchase_detail.dart';

class Purchase {
  Purchase({
    this.id,
    this.purchaseNo,
    required this.supplierId,
    required this.purchaseDate,
    this.deliveryDate,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    this.remarks,
    required this.details,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'] as String?,
      purchaseNo: json['purchase_no'] as String?,
      supplierId: json['supplier_id'] as int,
      purchaseDate: json['purchase_date'] as String,
      deliveryDate: json['delivery_date'] as String?,
      subtotal: json['subtotal'] as num,
      taxAmount: json['tax_amount'] as num,
      totalAmount: json['total_amount'] as num,
      remarks: json['remarks'] as String?,
      details: (json['details'] as List<dynamic>? ?? [])
          .map((e) => PurchaseDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String? id;
  final String? purchaseNo;
  final int supplierId;
  /// JST固定のISO8601日付文字列（例: 2026-07-13）
  final String purchaseDate;
  final String? deliveryDate;
  final num subtotal;
  final num taxAmount;
  final num totalAmount;
  final String? remarks;
  final List<PurchaseDetail> details;

  Map<String, dynamic> toJson() {
    return {
      'supplier_id': supplierId,
      'purchase_date': purchaseDate,
      'delivery_date': deliveryDate,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'remarks': remarks,
      'details': details.map((d) => d.toJson()).toList(),
    };
  }
}
