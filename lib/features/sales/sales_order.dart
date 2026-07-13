import 'sales_detail.dart';

/// 売上伝票（ヘッダ+明細）。`Sales` はDart標準クラス名との衝突を避けるため `SalesOrder` とする。
class SalesOrder {
  SalesOrder({
    this.id,
    this.salesNo,
    required this.salesDatetime,
    required this.businessDate,
    this.tableNo,
    this.customerCount = 1,
    required this.subtotal,
    required this.taxAmount,
    this.discountAmount = 0,
    required this.totalAmount,
    required this.paymentMethod,
    this.remarks,
    required this.details,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    return SalesOrder(
      id: json['id'] as String?,
      salesNo: json['sales_no'] as String?,
      salesDatetime: json['sales_datetime'] as String,
      businessDate: json['business_date'] as String,
      tableNo: json['table_no'] as String?,
      customerCount: json['customer_count'] as int? ?? 1,
      subtotal: json['subtotal'] as num,
      taxAmount: json['tax_amount'] as num,
      discountAmount: json['discount_amount'] as num? ?? 0,
      totalAmount: json['total_amount'] as num,
      paymentMethod: json['payment_method'] as String,
      remarks: json['remarks'] as String?,
      details: (json['details'] as List<dynamic>? ?? [])
          .map((e) => SalesDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String? id;
  final String? salesNo;
  /// JST固定のISO8601日時文字列（例: 2026-07-13T19:30:00+09:00）
  final String salesDatetime;
  /// JST固定のISO8601日付文字列（例: 2026-07-13）
  final String businessDate;
  final String? tableNo;
  final int customerCount;
  final num subtotal;
  final num taxAmount;
  final num discountAmount;
  final num totalAmount;
  final String paymentMethod;
  final String? remarks;
  final List<SalesDetail> details;

  Map<String, dynamic> toJson() {
    return {
      'sales_datetime': salesDatetime,
      'business_date': businessDate,
      'table_no': tableNo,
      'customer_count': customerCount,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'remarks': remarks,
      'details': details.map((d) => d.toJson()).toList(),
    };
  }
}
