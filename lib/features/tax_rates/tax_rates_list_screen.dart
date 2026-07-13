import 'package:flutter/material.dart';

import '../../shared/widgets/async_value_builder.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/snackbar.dart';
import 'tax_rate.dart';
import 'tax_rate_form_screen.dart';
import 'tax_rates_api.dart';

class TaxRatesListScreen extends StatefulWidget {
  const TaxRatesListScreen({super.key});

  @override
  State<TaxRatesListScreen> createState() => _TaxRatesListScreenState();
}

class _TaxRatesListScreenState extends State<TaxRatesListScreen> {
  final TaxRatesApi _api = TaxRatesApi();
  late Future<List<TaxRate>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.list();
  }

  void _reload() {
    setState(() => _future = _api.list());
  }

  Future<void> _openForm({TaxRate? taxRate}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TaxRateFormScreen(taxRate: taxRate)),
    );
    if (changed == true) _reload();
  }

  Future<void> _delete(TaxRate taxRate) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '消費税率の削除',
      message: '「${taxRate.taxCategory.label}（適用開始 ${taxRate.validFrom}）」を削除しますか？',
    );
    if (!confirmed) return;
    try {
      await _api.delete(taxRate.taxCategory, taxRate.validFrom);
      _reload();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('消費税率マスタ')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: '消費税率を追加',
        child: const Icon(Icons.add),
      ),
      body: AsyncValueBuilder<List<TaxRate>>(
        future: _future,
        onRetry: _reload,
        builder: (context, taxRates) {
          if (taxRates.isEmpty) {
            return const Center(child: Text('消費税率が登録されていません'));
          }
          final sorted = [...taxRates]..sort((a, b) {
              final byCategory = a.taxCategory.index.compareTo(b.taxCategory.index);
              if (byCategory != 0) return byCategory;
              return b.validFrom.compareTo(a.validFrom);
            });
          return ListView.builder(
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final taxRate = sorted[index];
              final rangeLabel = taxRate.validTo == null
                  ? '${taxRate.validFrom} 〜'
                  : '${taxRate.validFrom} 〜 ${taxRate.validTo}';
              return ListTile(
                title: Text('${taxRate.taxCategory.label}（${(taxRate.rate * 100).toStringAsFixed(0)}%）'),
                subtitle: Text('${taxRate.description} / $rangeLabel'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(taxRate),
                ),
                onTap: () => _openForm(taxRate: taxRate),
              );
            },
          );
        },
      ),
    );
  }
}
