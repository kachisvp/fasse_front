import 'package:flutter/material.dart';

import '../../shared/models/item.dart';
import 'item_service.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  late Future<List<Item>> _futureItems;

  @override
  void initState() {
    super.initState();
    _futureItems = ItemService.fetchItems();
  }

  Future<void> _reloadItems() async {
    setState(() {
      _futureItems = ItemService.fetchItems();
    });
  }

  Future<void> _showItemDialog([Item? item]) async {
    final nameController = TextEditingController(text: item?.itemName ?? '');
    final unitController = TextEditingController(text: item?.unit ?? '');
    final priceController = TextEditingController(text: item?.standardPrice?.toString() ?? '');
    final isActive = ValueNotifier<bool>(item?.isActive ?? true);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item == null ? '品目を追加' : '品目を編集'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '品目名'),
                ),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(labelText: '単位'),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '標準価格'),
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newItem = Item(
                  id: item?.id,
                  itemName: nameController.text.trim(),
                  unit: unitController.text.trim(),
                  standardPrice: double.tryParse(priceController.text.trim()),
                  isActive: isActive.value,
                );
                try {
                  if (item == null) {
                    await ItemService.createItem(newItem);
                  } else {
                    await ItemService.updateItem(newItem);
                  }
                  await _reloadItems();
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

  Future<void> _confirmDelete(Item item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('削除確認'),
          content: Text('「${item.itemName}」を削除してよろしいですか？'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('いいえ')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('はい')),
          ],
        );
      },
    );

    if (result == true && item.id != null) {
      await ItemService.deleteItem(item.id!);
      await _reloadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('品目マスタ'),
      ),
      body: RefreshIndicator(
        onRefresh: _reloadItems,
        child: FutureBuilder<List<Item>>(
          future: _futureItems,
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
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('品目データがありません')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    title: Text(item.itemName),
                    subtitle: Text('${item.unit} / ¥${item.standardPrice ?? 0}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showItemDialog(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _confirmDelete(item),
                        ),
                      ],
                    ),
                    onTap: () => _showItemDialog(item),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
