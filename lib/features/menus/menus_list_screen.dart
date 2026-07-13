import 'package:flutter/material.dart';

import '../../shared/widgets/async_value_builder.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/snackbar.dart';
import 'menu.dart';
import 'menu_form_screen.dart';
import 'menus_api.dart';

class MenusListScreen extends StatefulWidget {
  const MenusListScreen({super.key});

  @override
  State<MenusListScreen> createState() => _MenusListScreenState();
}

class _MenusListScreenState extends State<MenusListScreen> {
  final MenusApi _api = MenusApi();
  late Future<List<Menu>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.list();
  }

  void _reload() {
    setState(() => _future = _api.list());
  }

  Future<void> _openForm({Menu? menu}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MenuFormScreen(menu: menu)),
    );
    if (changed == true) _reload();
  }

  Future<void> _delete(Menu menu) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'メニューの削除',
      message: '「${menu.menuName}」を削除しますか？',
    );
    if (!confirmed) return;
    try {
      await _api.delete(menu.id!);
      _reload();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('メニューマスタ')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'メニューを追加',
        child: const Icon(Icons.add),
      ),
      body: AsyncValueBuilder<List<Menu>>(
        future: _future,
        onRetry: _reload,
        builder: (context, menus) {
          if (menus.isEmpty) {
            return const Center(child: Text('メニューが登録されていません'));
          }
          return ListView.builder(
            itemCount: menus.length,
            itemBuilder: (context, index) {
              final menu = menus[index];
              return ListTile(
                title: Text(menu.menuName),
                subtitle: Text('${menu.category} / ${menu.taxCategory.label}'
                    '${menu.isActive ? '' : '（廃止）'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(menu),
                ),
                onTap: () => _openForm(menu: menu),
              );
            },
          );
        },
      ),
    );
  }
}
