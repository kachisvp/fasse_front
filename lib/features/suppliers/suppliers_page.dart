import 'package:flutter/material.dart';

import '../../shared/models/supplier.dart';
import 'supplier_service.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  late Future<List<Supplier>> _futureSuppliers;

  @override
  void initState() {
    super.initState();
    _futureSuppliers = SupplierService.fetchSuppliers();
  }

  Future<void> _reloadSuppliers() async {
    setState(() {
      _futureSuppliers = SupplierService.fetchSuppliers();
    });
  }

  Future<void> _showSupplierDialog([Supplier? supplier]) async {
    final nameController = TextEditingController(text: supplier?.supplierName ?? '');
    final postalController = TextEditingController(text: supplier?.postalCode ?? '');
    final addressController = TextEditingController(text: supplier?.address ?? '');
    final phoneController = TextEditingController(text: supplier?.phoneNumber ?? '');
    final emailController = TextEditingController(text: supplier?.email ?? '');
    final isActive = ValueNotifier<bool>(supplier?.isActive ?? true);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(supplier == null ? '仕入先を追加' : '仕入先を編集'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '仕入先名'),
                ),
                TextField(
                  controller: postalController,
                  decoration: const InputDecoration(labelText: '郵便番号'),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: '住所'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: '電話番号'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'メール'),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<bool>(
                  valueListenable: isActive,
                  builder: (context, active, child) {
                    return SwitchListTile(
                      title: const Text('有効'),
                      value: active,
                      onChanged: (value) => isActive.value = value,
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('キャンセル')),
            ElevatedButton(
              onPressed: () async {
                final newSupplier = Supplier(
                  id: supplier?.id,
                  supplierName: nameController.text.trim(),
                  postalCode: postalController.text.trim().isEmpty ? null : postalController.text.trim(),
                  address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                  phoneNumber: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                  email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                  isActive: isActive.value,
                );
                try {
                  if (supplier == null) {
                    await SupplierService.createSupplier(newSupplier);
                  } else {
                    await SupplierService.updateSupplier(newSupplier);
                  }
                  await _reloadSuppliers();
                  if (context.mounted) Navigator.of(context).pop();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('保存に失敗しました: $e')),
                    );
                  }
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(Supplier supplier) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('削除確認'),
          content: Text('「${supplier.supplierName}」を削除してよろしいですか？'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('いいえ')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('はい')),
          ],
        );
      },
    );

    if (result == true && supplier.id != null) {
      await SupplierService.deleteSupplier(supplier.id!);
      await _reloadSuppliers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('仕入先マスタ')),
      body: RefreshIndicator(
        onRefresh: _reloadSuppliers,
        child: FutureBuilder<List<Supplier>>(
          future: _futureSuppliers,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('読み込みに失敗しました: ${snapshot.error}'),
                  ),
                ],
              );
            }
            final suppliers = snapshot.data ?? [];
            if (suppliers.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('仕入先データがありません')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: suppliers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final supplier = suppliers[index];
                return Card(
                  child: ListTile(
                    title: Text(supplier.supplierName),
                    subtitle: Text(supplier.address ?? '住所なし'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showSupplierDialog(supplier),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _confirmDelete(supplier),
                        ),
                      ],
                    ),
                    onTap: () => _showSupplierDialog(supplier),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupplierDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
