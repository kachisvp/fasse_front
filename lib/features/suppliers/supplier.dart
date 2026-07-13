class Supplier {
  Supplier({
    this.id,
    required this.supplierName,
    this.postalCode,
    this.address,
    this.phoneNumber,
    this.email,
    this.isActive = true,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as int?,
      supplierName: json['supplier_name'] as String,
      postalCode: json['postal_code'] as String?,
      address: json['address'] as String?,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  final int? id;
  final String supplierName;
  final String? postalCode;
  final String? address;
  final String? phoneNumber;
  final String? email;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'supplier_name': supplierName,
      'postal_code': postalCode,
      'address': address,
      'phone_number': phoneNumber,
      'email': email,
      'is_active': isActive,
    };
  }
}
