import 'package:flutter/material.dart';

import '../../shared/utils/date_format.dart';
import '../../shared/widgets/async_value_builder.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/snackbar.dart';
import '../suppliers/suppliers_api.dart';
import 'purchase.dart';
import 'purchase_form_screen.dart';
import 'purchases_api.dart';

class _PurchasesListData {
  _PurchasesListData(this.purchases, this.supplierNames);

  final List<Purchase> purchases;
  final Map<int, String> supplierNames;
}

class PurchasesListScreen extends StatefulWidget {
  const PurchasesListScreen({super.key});

  @override
  State<PurchasesListScreen> createState() => _PurchasesListScreenState();
}

class _PurchasesListScreenState extends State<PurchasesListScreen> {
  final PurchasesApi _api = PurchasesApi();
  final SuppliersApi _suppliersApi = SuppliersApi();

  late DateTimeRange _range;
  late Future<_PurchasesListData> _future;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _range = DateTimeRange(start: today.subtract(const Duration(days: 7)), end: today);
    _future = _load();
  }

  Future<_PurchasesListData> _load() async {
    final results = await Future.wait([
      _api.list(from: _range.start, to: _range.end),
      _suppliersApi.list(),
    ]);
    final purchases = results[0] as List<Purchase>;
    final suppliers = results[1] as List;
    final names = {for (final s in suppliers) (s as dynamic).id as int: s.supplierName as String};
    return _PurchasesListData(purchases, names);
  }

  void _reload() {
    setState(() => _future = _load());
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _range,
    );
    if (picked == null) return;
    setState(() {
      _range = picked;
      _future = _load();
    });
  }

  Future<void> _openForm({Purchase? purchase}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PurchaseFormScreen(purchaseId: purchase?.id)),
    );
    if (changed == true) _reload();
  }

  Future<void> _delete(Purchase purchase) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '仕入伝票の削除',
      message: '「${purchase.purchaseNo ?? purchase.id}」を削除しますか？',
    );
    if (!confirmed) return;
    try {
      await _api.delete(purchase.id!);
      _reload();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('仕入伝票'),
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: _pickRange),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: '仕入伝票を追加',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '表示期間: ${formatIsoDate(_range.start)} 〜 ${formatIsoDate(_range.end)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: AsyncValueBuilder<_PurchasesListData>(
              future: _future,
              onRetry: _reload,
              builder: (context, data) {
                if (data.purchases.isEmpty) {
                  return const Center(child: Text('該当期間の仕入伝票がありません'));
                }
                final sorted = [...data.purchases]
                  ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
                return ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final purchase = sorted[index];
                    final supplierName = data.supplierNames[purchase.supplierId] ?? '不明';
                    return ListTile(
                      title: Text('${purchase.purchaseNo ?? ''} $supplierName'),
                      subtitle: Text('${purchase.purchaseDate} / ¥${purchase.totalAmount}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(purchase),
                      ),
                      onTap: () => _openForm(purchase: purchase),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
