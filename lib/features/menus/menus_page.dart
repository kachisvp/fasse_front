import 'package:flutter/material.dart';

import '../../shared/models/menu.dart';
import 'menu_service.dart';

class MenusPage extends StatefulWidget {
  const MenusPage({super.key});

  @override
  State<MenusPage> createState() => _MenusPageState();
}

class _MenusPageState extends State<MenusPage> {
  late Future<List<Menu>> _futureMenus;

  @override
  void initState() {
    super.initState();
    _futureMenus = MenuService.fetchMenus();
  }

  Future<void> _reloadMenus() async {
    setState(() {
      _futureMenus = MenuService.fetchMenus();
    });
  }

  Future<void> _showMenuDialog([Menu? menu]) async {
    final nameController = TextEditingController(text: menu?.menuName ?? '');
    final categoryController = TextEditingController(text: menu?.category ?? '');
    final priceController = TextEditingController(text: menu?.standardPrice.toString() ?? '');
    final isActive = ValueNotifier<bool>(menu?.isActive ?? true);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(menu == null ? 'メニューを追加' : 'メニューを編集'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'メニュー名'),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'カテゴリ'),
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
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('キャンセル')),
            ElevatedButton(
              onPressed: () async {
                final newMenu = Menu(
                  id: menu?.id,
                  menuName: nameController.text.trim(),
                  category: categoryController.text.trim(),
                  standardPrice: double.tryParse(priceController.text.trim()) ?? 0.0,
                  isActive: isActive.value,
                );
                try {
                  if (menu == null) {
                    await MenuService.createMenu(newMenu);
                  } else {
                    await MenuService.updateMenu(newMenu);
                  }
                  await _reloadMenus();
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

  Future<void> _confirmDelete(Menu menu) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('削除確認'),
          content: Text('「${menu.menuName}」を削除してよろしいですか？'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('いいえ')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('はい')),
          ],
        );
      },
    );

    if (result == true && menu.id != null) {
      await MenuService.deleteMenu(menu.id!);
      await _reloadMenus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('メニューマスタ')),
      body: RefreshIndicator(
        onRefresh: _reloadMenus,
        child: FutureBuilder<List<Menu>>(
          future: _futureMenus,
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
            final menus = snapshot.data ?? [];
            if (menus.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('メニューデータがありません')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: menus.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final menu = menus[index];
                return Card(
                  child: ListTile(
                    title: Text(menu.menuName),
                    subtitle: Text('${menu.category} / ¥${menu.standardPrice}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _showMenuDialog(menu)),
                        IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete(menu)),
                      ],
                    ),
                    onTap: () => _showMenuDialog(menu),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMenuDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
