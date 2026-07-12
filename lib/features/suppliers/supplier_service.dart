import '../../shared/api_client.dart';
import '../../shared/models/supplier.dart';

class SupplierService {
  static Future<List<Supplier>> fetchSuppliers() async {
    final response = await ApiClient.get('/suppliers');
    final data = ApiClient.decodeJson(response) as List<dynamic>;
    return data.map((dynamic json) => Supplier.fromJson(json as Map<String, dynamic>)).toList();
  }

  static Future<Supplier> createSupplier(Supplier supplier) async {
    final response = await ApiClient.post('/suppliers', supplier.toJson());
    final json = ApiClient.decodeJson(response) as Map<String, dynamic>;
    return Supplier.fromJson(json);
  }

  static Future<Supplier> updateSupplier(Supplier supplier) async {
    if (supplier.id == null) {
      throw ApiException('Supplier id is required for update');
    }
    final response = await ApiClient.put('/suppliers/${supplier.id}', supplier.toJson());
    final json = ApiClient.decodeJson(response) as Map<String, dynamic>;
    return Supplier.fromJson(json);
  }

  static Future<void> deleteSupplier(int id) async {
    await ApiClient.delete('/suppliers/$id');
  }
}
