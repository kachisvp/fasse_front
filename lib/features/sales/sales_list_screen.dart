import 'package:flutter/material.dart';

import '../../shared/utils/date_format.dart';
import '../../shared/widgets/async_value_builder.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/snackbar.dart';
import 'sales_api.dart';
import 'sales_form_screen.dart';
import 'sales_order.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  final SalesApi _api = SalesApi();

  late DateTimeRange _range;
  late Future<List<SalesOrder>> _future;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _range = DateTimeRange(start: today.subtract(const Duration(days: 7)), end: today);
    _future = _api.list(from: _range.start, to: _range.end);
  }

  void _reload() {
    setState(() => _future = _api.list(from: _range.start, to: _range.end));
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
      _future = _api.list(from: _range.start, to: _range.end);
    });
  }

  Future<void> _openForm({SalesOrder? sales}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SalesFormScreen(salesId: sales?.id)),
    );
    if (changed == true) _reload();
  }

  Future<void> _delete(SalesOrder sales) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '売上伝票の削除',
      message: '「${sales.salesNo ?? sales.id}」を削除しますか？',
    );
    if (!confirmed) return;
    try {
      await _api.delete(sales.id!);
      _reload();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('売上伝票'),
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: _pickRange),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: '売上伝票を追加',
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
            child: AsyncValueBuilder<List<SalesOrder>>(
              future: _future,
              onRetry: _reload,
              builder: (context, salesList) {
                if (salesList.isEmpty) {
                  return const Center(child: Text('該当期間の売上伝票がありません'));
                }
                final sorted = [...salesList]
                  ..sort((a, b) => b.businessDate.compareTo(a.businessDate));
                return ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final sales = sorted[index];
                    return ListTile(
                      title: Text('${sales.salesNo ?? ''} ${sales.tableNo ?? ''}'),
                      subtitle: Text('${sales.businessDate} / ¥${sales.totalAmount} / ${sales.paymentMethod}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(sales),
                      ),
                      onTap: () => _openForm(sales: sales),
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
