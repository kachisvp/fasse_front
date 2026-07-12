class Supplier {
  final int? id;
  final String supplierName;
  final String? postalCode;
  final String? address;
  final String? phoneNumber;
  final String? email;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Supplier({
    this.id,
    required this.supplierName,
    this.postalCode,
    this.address,
    this.phoneNumber,
    this.email,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      supplierName: json['supplier_name'] as String? ?? '',
      postalCode: json['postal_code'] as String?,
      address: json['address'] as String?,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      isActive: json['is_active'] == null ? true : json['is_active'] as bool,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supplier_name': supplierName,
      if (postalCode != null) 'postal_code': postalCode,
      if (address != null) 'address': address,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (email != null) 'email': email,
      'is_active': isActive,
    };
  }
}
