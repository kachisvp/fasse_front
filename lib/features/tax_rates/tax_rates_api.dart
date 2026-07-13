import '../../shared/api/api_client.dart';
import '../../shared/models/tax_category.dart';
import 'tax_rate.dart';

class TaxRatesApi {
  TaxRatesApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<TaxRate>> list({TaxCategory? taxCategory}) async {
    final result = await _client.get(
      '/tax-rates',
      queryParameters: taxCategory == null ? null : {'tax_category': taxCategory.apiValue},
    ) as List<dynamic>;
    return result.map((e) => TaxRate.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TaxRate> create(TaxRate taxRate) async {
    final result = await _client.post('/tax-rates', body: taxRate.toCreateJson());
    return TaxRate.fromJson(result as Map<String, dynamic>);
  }

  Future<TaxRate> update(TaxRate taxRate) async {
    final result = await _client.put(
      '/tax-rates/${taxRate.taxCategory.apiValue}/${taxRate.validFrom}',
      body: taxRate.toUpdateJson(),
    );
    return TaxRate.fromJson(result as Map<String, dynamic>);
  }

  Future<void> delete(TaxCategory taxCategory, String validFrom) =>
      _client.delete('/tax-rates/${taxCategory.apiValue}/$validFrom');
}
