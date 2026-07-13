import '../../shared/api/api_client.dart';
import '../../shared/api/api_parse.dart';
import '../../shared/utils/date_format.dart';
import 'sales_order.dart';

class SalesApi {
  SalesApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<SalesOrder>> list({required DateTime from, required DateTime to}) async {
    final result = await _client.get(
      '/sales',
      queryParameters: {'from': formatIsoDate(from), 'to': formatIsoDate(to)},
    ) as List<dynamic>;
    return parseApiResponse(
      () => result.map((e) => SalesOrder.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Future<SalesOrder> get(String id) async {
    final result = await _client.get('/sales/$id');
    return parseApiResponse(() => SalesOrder.fromJson(result as Map<String, dynamic>));
  }

  Future<SalesOrder> create(SalesOrder sales) async {
    final result = await _client.post('/sales', body: sales.toJson());
    return parseApiResponse(() => SalesOrder.fromJson(result as Map<String, dynamic>));
  }

  Future<SalesOrder> update(String id, SalesOrder sales) async {
    final result = await _client.put('/sales/$id', body: sales.toJson());
    return parseApiResponse(() => SalesOrder.fromJson(result as Map<String, dynamic>));
  }

  Future<void> delete(String id) => _client.delete('/sales/$id');
}
