import 'package:flutter/material.dart';

import '../../shared/widgets/async_value_builder.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/snackbar.dart';
import 'item.dart';
import 'item_form_screen.dart';
import 'items_api.dart';

class ItemsListScreen extends StatefulWidget {
  const ItemsListScreen({super.key});

  @override
  State<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> {
  final ItemsApi _api = ItemsApi();
  late Future<List<Item>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.list();
  }

  void _reload() {
    setState(() => _future = _api.list());
  }

  Future<void> _openForm({Item? item}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ItemFormScreen(item: item)),
    );
    if (changed == true) _reload();
  }

  Future<void> _delete(Item item) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '品目の削除',
      message: '「${item.itemName}」を削除しますか？',
    );
    if (!confirmed) return;
    try {
      await _api.delete(item.id!);
      _reload();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('品目マスタ')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: '品目を追加',
        child: const Icon(Icons.add),
      ),
      body: AsyncValueBuilder<List<Item>>(
        future: _future,
        onRetry: _reload,
        builder: (context, items) {
          if (items.isEmpty) {
            return const Center(child: Text('品目が登録されていません'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.itemName),
                subtitle: Text('${item.unit} / ${item.taxCategory.label}'
                    '${item.isActive ? '' : '（廃止）'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(item),
                ),
                onTap: () => _openForm(item: item),
              );
            },
          );
        },
      ),
    );
  }
}
