import '../../shared/api/api_client.dart';
import '../../shared/api/api_parse.dart';
import 'menu.dart';

class MenusApi {
  MenusApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Menu>> list() async {
    final result = await _client.get('/menus') as List<dynamic>;
    return parseApiResponse(
      () => result.map((e) => Menu.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Future<Menu> create(Menu menu) async {
    final result = await _client.post('/menus', body: menu.toJson());
    return parseApiResponse(() => Menu.fromJson(result as Map<String, dynamic>));
  }

  Future<Menu> update(int id, Menu menu) async {
    final result = await _client.put('/menus/$id', body: menu.toJson());
    return parseApiResponse(() => Menu.fromJson(result as Map<String, dynamic>));
  }

  Future<void> delete(int id) => _client.delete('/menus/$id');
}
