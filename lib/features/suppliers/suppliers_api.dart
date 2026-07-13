import '../../shared/api/api_client.dart';
import 'supplier.dart';

class SuppliersApi {
  SuppliersApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Supplier>> list() async {
    final result = await _client.get('/suppliers') as List<dynamic>;
    return result.map((e) => Supplier.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Supplier> create(Supplier supplier) async {
    final result = await _client.post('/suppliers', body: supplier.toJson());
    return Supplier.fromJson(result as Map<String, dynamic>);
  }

  Future<Supplier> update(int id, Supplier supplier) async {
    final result = await _client.put('/suppliers/$id', body: supplier.toJson());
    return Supplier.fromJson(result as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _client.delete('/suppliers/$id');
}
