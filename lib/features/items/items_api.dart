import '../../shared/api/api_client.dart';
import 'item.dart';

class ItemsApi {
  ItemsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Item>> list() async {
    final result = await _client.get('/items') as List<dynamic>;
    return result.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Item> create(Item item) async {
    final result = await _client.post('/items', body: item.toJson());
    return Item.fromJson(result as Map<String, dynamic>);
  }

  Future<Item> update(int id, Item item) async {
    final result = await _client.put('/items/$id', body: item.toJson());
    return Item.fromJson(result as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _client.delete('/items/$id');
}
