import 'package:flutter/material.dart';

import '../../shared/models/tax_category.dart';
import '../../shared/utils/date_format.dart';
import '../../shared/widgets/snackbar.dart';
import 'tax_rate.dart';
import 'tax_rates_api.dart';

class TaxRateFormScreen extends StatefulWidget {
  const TaxRateFormScreen({super.key, this.taxRate});

  final TaxRate? taxRate;

  @override
  State<TaxRateFormScreen> createState() => _TaxRateFormScreenState();
}

class _TaxRateFormScreenState extends State<TaxRateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TaxRatesApi _api = TaxRatesApi();

  late final TextEditingController _descriptionController;
  late final TextEditingController _rateController;
  TaxCategory? _taxCategory;
  DateTime? _validFrom;
  DateTime? _validTo;
  bool _submitting = false;

  bool get _isEdit => widget.taxRate != null;

  @override
  void initState() {
    super.initState();
    final taxRate = widget.taxRate;
    _descriptionController = TextEditingController(text: taxRate?.description ?? '');
    _rateController = TextEditingController(text: taxRate?.rate.toString() ?? '');
    _taxCategory = taxRate?.taxCategory;
    _validFrom = taxRate == null ? null : parseIsoDate(taxRate.validFrom);
    _validTo = taxRate?.validTo == null ? null : parseIsoDate(taxRate!.validTo!);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isValidFrom}) async {
    final initial = (isValidFrom ? _validFrom : _validTo) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isValidFrom) {
        _validFrom = picked;
      } else {
        _validTo = picked;
      }
    });
  }

  Future<void> _submit() async {
    final rate = num.tryParse(_rateController.text.trim());
    if (!_formKey.currentState!.validate() ||
        _taxCategory == null ||
        _validFrom == null ||
        rate == null) {
      if (_taxCategory == null) {
        showErrorSnackBar(context, '税区分を選択してください');
      } else if (_validFrom == null) {
        showErrorSnackBar(context, '適用開始日を選択してください');
      } else if (rate == null) {
        showErrorSnackBar(context, '税率を数値で入力してください');
      }
      return;
    }

    setState(() => _submitting = true);
    final taxRate = TaxRate(
      taxCategory: _taxCategory!,
      description: _descriptionController.text.trim(),
      rate: rate,
      validFrom: formatIsoDate(_validFrom!),
      validTo: _validTo == null ? null : formatIsoDate(_validTo!),
    );

    try {
      if (_isEdit) {
        await _api.update(taxRate);
      } else {
        await _api.create(taxRate);
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
      appBar: AppBar(title: Text(_isEdit ? '消費税率の変更' : '消費税率の追加')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<TaxCategory>(
                initialValue: _taxCategory,
                decoration: const InputDecoration(labelText: '税区分 *'),
                items: TaxCategory.values
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                    .toList(),
                // 税区分+適用開始日が複合キーのため、変更時は変更不可（PUTのパスパラメータで一意に決まる）
                onChanged: _isEdit ? null : (v) => setState(() => _taxCategory = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: '概要 *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? '概要を入力してください' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rateController,
                decoration: const InputDecoration(labelText: '税率（例: 0.10） *'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || v.trim().isEmpty) ? '税率を入力してください' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('適用開始日 *'),
                subtitle: Text(_validFrom == null ? '未選択' : formatIsoDate(_validFrom!)),
                trailing: const Icon(Icons.calendar_today),
                // 変更時は複合キーの一部のため変更不可
                onTap: _isEdit ? null : () => _pickDate(isValidFrom: true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('適用終了日（未設定の場合は現在も有効）'),
                subtitle: Text(_validTo == null ? '未選択' : formatIsoDate(_validTo!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(isValidFrom: false),
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
