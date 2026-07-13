import 'package:flutter/material.dart';

import '../../shared/widgets/async_value_builder.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/snackbar.dart';
import 'supplier.dart';
import 'supplier_form_screen.dart';
import 'suppliers_api.dart';

class SuppliersListScreen extends StatefulWidget {
  const SuppliersListScreen({super.key});

  @override
  State<SuppliersListScreen> createState() => _SuppliersListScreenState();
}

class _SuppliersListScreenState extends State<SuppliersListScreen> {
  final SuppliersApi _api = SuppliersApi();
  late Future<List<Supplier>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.list();
  }

  void _reload() {
    setState(() => _future = _api.list());
  }

  Future<void> _openForm({Supplier? supplier}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SupplierFormScreen(supplier: supplier)),
    );
    if (changed == true) _reload();
  }

  Future<void> _delete(Supplier supplier) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '仕入先の削除',
      message: '「${supplier.supplierName}」を削除しますか？',
    );
    if (!confirmed) return;
    try {
      await _api.delete(supplier.id!);
      _reload();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('仕入先マスタ')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: '仕入先を追加',
        child: const Icon(Icons.add),
      ),
      body: AsyncValueBuilder<List<Supplier>>(
        future: _future,
        onRetry: _reload,
        builder: (context, suppliers) {
          if (suppliers.isEmpty) {
            return const Center(child: Text('仕入先が登録されていません'));
          }
          return ListView.builder(
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final supplier = suppliers[index];
              return ListTile(
                title: Text(supplier.supplierName),
                subtitle: Text(supplier.isActive ? (supplier.address ?? '') : '（廃止）'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(supplier),
                ),
                onTap: () => _openForm(supplier: supplier),
              );
            },
          );
        },
      ),
    );
  }
}
