import 'package:flutter/material.dart';

import '../../shared/models/tax_category.dart';
import '../../shared/widgets/snackbar.dart';
import 'menu.dart';
import 'menus_api.dart';

class MenuFormScreen extends StatefulWidget {
  const MenuFormScreen({super.key, this.menu});

  final Menu? menu;

  @override
  State<MenuFormScreen> createState() => _MenuFormScreenState();
}

class _MenuFormScreenState extends State<MenuFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final MenusApi _api = MenusApi();

  late final TextEditingController _menuNameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  TaxCategory? _taxCategory;
  bool _isActive = true;
  bool _submitting = false;

  bool get _isEdit => widget.menu != null;

  @override
  void initState() {
    super.initState();
    final menu = widget.menu;
    _menuNameController = TextEditingController(text: menu?.menuName ?? '');
    _categoryController = TextEditingController(text: menu?.category ?? '');
    _priceController = TextEditingController(text: menu?.standardPrice.toString() ?? '');
    _taxCategory = menu?.taxCategory;
    _isActive = menu?.isActive ?? true;
  }

  @override
  void dispose() {
    _menuNameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final price = num.tryParse(_priceController.text.trim());
    if (!_formKey.currentState!.validate() || _taxCategory == null || price == null) {
      if (_taxCategory == null) {
        showErrorSnackBar(context, '税区分を選択してください');
      } else if (price == null) {
        showErrorSnackBar(context, '標準価格を数値で入力してください');
      }
      return;
    }

    setState(() => _submitting = true);
    final menu = Menu(
      id: widget.menu?.id,
      menuName: _menuNameController.text.trim(),
      category: _categoryController.text.trim(),
      standardPrice: price,
      taxCategory: _taxCategory!,
      isActive: _isActive,
    );

    try {
      if (_isEdit) {
        await _api.update(widget.menu!.id!, menu);
      } else {
        await _api.create(menu);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'メニューの変更' : 'メニューの追加')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _menuNameController,
                decoration: const InputDecoration(labelText: 'メニュー名 *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'メニュー名を入力してください' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'カテゴリ *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'カテゴリを入力してください' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: '標準価格（税抜） *'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || v.trim().isEmpty) ? '標準価格を入力してください' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaxCategory>(
                initialValue: _taxCategory,
                decoration: const InputDecoration(labelText: '税区分 *'),
                items: TaxCategory.values
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                    .toList(),
                onChanged: (v) => setState(() => _taxCategory = v),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('有効'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_isEdit ? '更新' : '登録'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
