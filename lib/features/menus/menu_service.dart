import '../../shared/api_client.dart';
import '../../shared/models/menu.dart';

class MenuService {
  static Future<List<Menu>> fetchMenus() async {
    final response = await ApiClient.get('/menus');
    final data = ApiClient.decodeJson(response) as List<dynamic>;
    return data.map((dynamic json) => Menu.fromJson(json as Map<String, dynamic>)).toList();
  }

  static Future<Menu> createMenu(Menu menu) async {
    final response = await ApiClient.post('/menus', menu.toJson());
    final json = ApiClient.decodeJson(response) as Map<String, dynamic>;
    return Menu.fromJson(json);
  }

  static Future<Menu> updateMenu(Menu menu) async {
    if (menu.id == null) {
      throw ApiException('Menu id is required for update');
    }
    final response = await ApiClient.put('/menus/${menu.id}', menu.toJson());
    final json = ApiClient.decodeJson(response) as Map<String, dynamic>;
    return Menu.fromJson(json);
  }

  static Future<void> deleteMenu(int id) async {
    await ApiClient.delete('/menus/$id');
  }
}
