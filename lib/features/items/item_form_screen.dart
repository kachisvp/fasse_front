import 'package:flutter/material.dart';

import '../../shared/models/tax_category.dart';
import '../../shared/widgets/snackbar.dart';
import 'item.dart';
import 'items_api.dart';

class ItemFormScreen extends StatefulWidget {
  const ItemFormScreen({super.key, this.item});

  final Item? item;

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ItemsApi _api = ItemsApi();

  late final TextEditingController _itemNameController;
  late final TextEditingController _unitController;
  late final TextEditingController _priceController;
  TaxCategory? _taxCategory;
  bool _isActive = true;
  bool _submitting = false;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _itemNameController = TextEditingController(text: item?.itemName ?? '');
    _unitController = TextEditingController(text: item?.unit ?? '');
    _priceController = TextEditingController(text: item?.standardPrice?.toString() ?? '');
    _taxCategory = item?.taxCategory;
    _isActive = item?.isActive ?? true;
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _taxCategory == null) {
      if (_taxCategory == null) {
        showErrorSnackBar(context, '税区分を選択してください');
      }
      return;
    }

    setState(() => _submitting = true);
    final item = Item(
      id: widget.item?.id,
      itemName: _itemNameController.text.trim(),
      unit: _unitController.text.trim(),
      standardPrice: _priceController.text.trim().isEmpty
          ? null
          : num.tryParse(_priceController.text.trim()),
      taxCategory: _taxCategory!,
      isActive: _isActive,
    );

    try {
      if (_isEdit) {
        await _api.update(widget.item!.id!, item);
      } else {
        await _api.create(item);
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
      appBar: AppBar(title: Text(_isEdit ? '品目の変更' : '品目の追加')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _itemNameController,
                decoration: const InputDecoration(labelText: '品目名 *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? '品目名を入力してください' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(labelText: '単位 *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? '単位を入力してください' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: '標準価格（税抜）'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
