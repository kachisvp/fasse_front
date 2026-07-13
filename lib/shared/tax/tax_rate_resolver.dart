import '../../features/tax_rates/tax_rate.dart';
import '../../features/tax_rates/tax_rates_api.dart';
import '../models/tax_category.dart';
import '../utils/date_format.dart';

class TaxRateNotFoundException implements Exception {
  TaxRateNotFoundException(this.category, this.asOf);

  final TaxCategory category;
  final DateTime asOf;

  @override
  String toString() =>
      '${category.label}の${formatIsoDate(asOf)}時点で有効な消費税率が見つかりません。消費税率マスタを確認してください';
}

/// 品目/メニューの税区分と伝票の基準日から、その時点で有効な税率を解決する。
/// バックエンドの選定ロジック（`Query`: SK=valid_from <= 対象日, 降順, Limit=1）をクライアント側で再現する。
class TaxRateResolver {
  TaxRateResolver({TaxRatesApi? api}) : _api = api ?? TaxRatesApi();

  final TaxRatesApi _api;

  /// 税区分ごとの税率一覧をキャッシュし、同一税区分の解決で都度APIを呼び出さないようにする。
  final Map<TaxCategory, Future<List<TaxRate>>> _cache = {};

  Future<num> resolveRate(TaxCategory category, DateTime asOf) async {
    final rates = await (_cache[category] ??= _api.list(taxCategory: category));
    final applicable = rates.where((r) => !parseIsoDate(r.validFrom).isAfter(asOf)).toList()
      ..sort((a, b) => b.validFrom.compareTo(a.validFrom));
    if (applicable.isEmpty) {
      throw TaxRateNotFoundException(category, asOf);
    }
    return applicable.first.rate;
  }

  /// 消費税率マスタが更新された可能性がある場合に呼び出し、次回解決時に再取得させる。
  void clearCache() => _cache.clear();
}
