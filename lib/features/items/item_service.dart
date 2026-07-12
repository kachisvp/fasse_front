import 'dart:convert';

import '../../shared/api_client.dart';
import '../../shared/models/item.dart';

class ItemService {
  static Future<List<Item>> fetchItems() async {
    final response = await ApiClient.get('/items');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((dynamic json) => Item.fromJson(json as Map<String, dynamic>)).toList();
  }

  static Future<Item> createItem(Item item) async {
    final response = await ApiClient.post('/items', item.toJson());
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return Item.fromJson(json);
  }

  static Future<Item> updateItem(Item item) async {
    if (item.id == null) {
      throw ApiException('Item id is required for update');
    }
    final response = await ApiClient.put('/items/${item.id}', item.toJson());
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return Item.fromJson(json);
  }

  static Future<void> deleteItem(int id) async {
    await ApiClient.delete('/items/$id');
  }
}
