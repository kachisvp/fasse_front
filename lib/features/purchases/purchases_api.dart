import '../../shared/api/api_client.dart';
import '../../shared/api/api_parse.dart';
import '../../shared/utils/date_format.dart';
import 'purchase.dart';

class PurchasesApi {
  PurchasesApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Purchase>> list({required DateTime from, required DateTime to}) async {
    final result = await _client.get(
      '/purchases',
      queryParameters: {'from': formatIsoDate(from), 'to': formatIsoDate(to)},
    ) as List<dynamic>;
    return parseApiResponse(
      () => result.map((e) => Purchase.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Future<Purchase> get(String id) async {
    final result = await _client.get('/purchases/$id');
    return parseApiResponse(() => Purchase.fromJson(result as Map<String, dynamic>));
  }

  Future<Purchase> create(Purchase purchase) async {
    final result = await _client.post('/purchases', body: purchase.toJson());
    return parseApiResponse(() => Purchase.fromJson(result as Map<String, dynamic>));
  }

  Future<Purchase> update(String id, Purchase purchase) async {
    final result = await _client.put('/purchases/$id', body: purchase.toJson());
    return parseApiResponse(() => Purchase.fromJson(result as Map<String, dynamic>));
  }

  Future<void> delete(String id) => _client.delete('/purchases/$id');
}
