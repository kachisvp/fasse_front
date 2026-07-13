import 'package:flutter/material.dart';

import '../../shared/tax/tax_amount_calculator.dart';
import '../../shared/tax/tax_rate_resolver.dart';
import '../../shared/tax/taxable_line.dart';
import '../../shared/utils/date_format.dart';
import '../../shared/widgets/async_value_builder.dart';
import '../../shared/widgets/snackbar.dart';
import '../items/item.dart';
import '../items/items_api.dart';
import '../suppliers/supplier.dart';
import '../suppliers/suppliers_api.dart';
import 'purchase.dart';
import 'purchase_detail.dart';
import 'purchases_api.dart';

class _PurchaseFormData {
  _PurchaseFormData(this.suppliers, this.items, this.existing);

  final List<Supplier> suppliers;
  final List<Item> items;
  final Purchase? existing;
}

class _DetailRow {
  _DetailRow({this.detailId, this.item, String quantity = '', String unitPrice = ''})
      : quantityController = TextEditingController(text: quantity),
        unitPriceController = TextEditingController(text: unitPrice);

  final String? detailId;
  Item? item;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  num? resolvedTaxRate;
  bool resolvingTaxRate = false;
  Object? taxRateError;

  num get quantity => num.tryParse(quantityController.text.trim()) ?? 0;
  num get unitPrice => num.tryParse(unitPriceController.text.trim()) ?? 0;
  num get amount => quantity * unitPrice;

  void dispose() {
    quantityController.dispose();
    unitPriceController.dispose();
  }
}

class PurchaseFormScreen extends StatefulWidget {
  const PurchaseFormScreen({super.key, this.purchaseId});

  final String? purchaseId;

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  final PurchasesApi _purchasesApi = PurchasesApi();
  final TaxRateResolver _taxRateResolver = TaxRateResolver();
  final _remarksController = TextEditingController();

  late Future<_PurchaseFormData> _loadFuture;
  List<Supplier> _suppliers = [];
  List<Item> _items = [];

  int? _supplierId;
  DateTime _purchaseDate = DateTime.now();
  DateTime? _deliveryDate;
  final List<_DetailRow> _rows = [];
  bool _submitting = false;
  bool _initialized = false;

  bool get _isEdit => widget.purchaseId != null;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  void _retryLoad() {
    setState(() {
      _initialized = false;
      _loadFuture = _load();
    });
  }

  @override
  void dispose() {
    _remarksController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<_PurchaseFormData> _load() async {
    final results = await Future.wait([
      SuppliersApi().list(),
      ItemsApi().list(),
      widget.purchaseId == null ? Future.value(null) : _purchasesApi.get(widget.purchaseId!),
    ]);
    return _PurchaseFormData(
      results[0] as List<Supplier>,
      results[1] as List<Item>,
      results[2] as Purchase?,
    );
  }

  void _initializeFromData(_PurchaseFormData data) {
    if (_initialized) return;
    _initialized = true;
    _suppliers = data.suppliers;
    _items = data.items;

    final existing = data.existing;
    if (existing != null) {
      _supplierId = existing.supplierId;
      _purchaseDate = parseIsoDate(existing.purchaseDate);
      _deliveryDate = existing.deliveryDate == null ? null : parseIsoDate(existing.deliveryDate!);
      _remarksController.text = existing.remarks ?? '';
      for (final detail in existing.details) {
        final item = _items.where((i) => i.id == detail.itemId).firstOrNull;
        final row = _DetailRow(
          detailId: detail.id,
          item: item,
          quantity: _formatNum(detail.quantity),
          unitPrice: _formatNum(detail.unitPrice),
        );
        row.resolvedTaxRate = detail.taxRate;
        _rows.add(row);
      }
    }
  }

  String _formatNum(num value) => value == value.roundToDouble() ? value.toInt().toString() : value.toString();

  List<Supplier> _supplierOptions() {
    final active = _suppliers.where((s) => s.isActive).toList();
    if (_supplierId != null && !active.any((s) => s.id == _supplierId)) {
      final current = _suppliers.where((s) => s.id == _supplierId).firstOrNull;
      if (current != null) return [...active, current];
    }
    return active;
  }

  List<Item> _itemOptions(_DetailRow row) {
    final active = _items.where((i) => i.isActive).toList();
    if (row.item != null && !row.item!.isActive && !active.any((i) => i.id == row.item!.id)) {
      return [...active, row.item!];
    }
    return active;
  }

  void _addRow() {
    setState(() => _rows.add(_DetailRow()));
  }

  void _removeRow(_DetailRow row) {
    setState(() {
      _rows.remove(row);
      row.dispose();
    });
  }

  Future<void> _onItemSelected(_DetailRow row, Item? item) async {
    setState(() {
      row.item = item;
      if (item != null && row.unitPriceController.text.trim().isEmpty && item.standardPrice != null) {
        row.unitPriceController.text = _formatNum(item.standardPrice!);
      }
    });
    await _resolveRowTaxRate(row);
  }

  Future<void> _resolveRowTaxRate(_DetailRow row) async {
    if (row.item == null) return;
    setState(() {
      row.resolvingTaxRate = true;
      row.taxRateError = null;
    });
    try {
      final rate = await _taxRateResolver.resolveRate(row.item!.taxCategory, _purchaseDate);
      if (!mounted) return;
      setState(() {
        row.resolvedTaxRate = rate;
        row.resolvingTaxRate = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        row.taxRateError = e;
        row.resolvedTaxRate = null;
        row.resolvingTaxRate = false;
      });
    }
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _purchaseDate = picked);
    for (final row in _rows) {
      if (row.item != null) {
        // ignore: unawaited_futures
        _resolveRowTaxRate(row);
      }
    }
  }

  Future<void> _pickDeliveryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate ?? _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _deliveryDate = picked);
  }

  List<TaxableLine> _taxableLines() {
    return _rows
        .where((r) => r.item != null && r.resolvedTaxRate != null)
        .map((r) => TaxableLine(amount: r.amount, taxRate: r.resolvedTaxRate!))
        .toList();
  }

  String? _validate() {
    if (_supplierId == null) return '仕入先を選択してください';
    if (_rows.isEmpty) return '明細行を1件以上追加してください';
    for (final row in _rows) {
      if (row.item == null) return '明細行の品目を選択してください';
      if (row.quantityController.text.trim().isEmpty) return '明細行の数量を入力してください';
      if (row.unitPriceController.text.trim().isEmpty) return '明細行の単価を入力してください';
      if (row.taxRateError != null) return '税率が解決できない明細行があります: ${row.taxRateError}';
      if (row.resolvedTaxRate == null) return '明細行の税率が解決されていません';
    }
    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      showErrorSnackBar(context, error);
      return;
    }

    setState(() => _submitting = true);
    final lines = _taxableLines();
    final purchase = Purchase(
      id: widget.purchaseId,
      supplierId: _supplierId!,
      purchaseDate: formatIsoDate(_purchaseDate),
      deliveryDate: _deliveryDate == null ? null : formatIsoDate(_deliveryDate!),
      subtotal: TaxAmountCalculator.subtotal(lines),
      taxAmount: TaxAmountCalculator.taxAmount(lines),
      totalAmount: TaxAmountCalculator.totalAmount(lines),
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      details: _rows
          .map((r) => PurchaseDetail(
                itemId: r.item!.id!,
                quantity: r.quantity,
                unitPrice: r.unitPrice,
                amount: r.amount,
                taxRate: r.resolvedTaxRate!,
              ))
          .toList(),
    );

    try {
      if (_isEdit) {
        await _purchasesApi.update(widget.purchaseId!, purchase);
      } else {
        await _purchasesApi.create(purchase);
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
      appBar: AppBar(title: Text(_isEdit ? '仕入伝票の変更' : '仕入伝票の追加')),
      body: AsyncValueBuilder<_PurchaseFormData>(
        future: _loadFuture,
        onRetry: _retryLoad,
        builder: (context, data) {
          _initializeFromData(data);
          final lines = _taxableLines();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _supplierId,
                  decoration: const InputDecoration(labelText: '仕入先 *'),
                  items: _supplierOptions()
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.isActive ? s.supplierName : '${s.supplierName}（廃止）'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _supplierId = v),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('仕入日 *'),
                  subtitle: Text(formatIsoDate(_purchaseDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickPurchaseDate,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('納品日'),
                  subtitle: Text(_deliveryDate == null ? '未選択' : formatIsoDate(_deliveryDate!)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDeliveryDate,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _remarksController,
                  decoration: const InputDecoration(labelText: '備考'),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('明細', style: Theme.of(context).textTheme.titleMedium),
                    TextButton.icon(
                      onPressed: _addRow,
                      icon: const Icon(Icons.add),
                      label: const Text('明細行を追加'),
                    ),
                  ],
                ),
                for (final row in _rows) _buildDetailRow(row),
                const Divider(height: 32),
                _summaryRow('小計', TaxAmountCalculator.subtotal(lines)),
                _summaryRow('消費税額', TaxAmountCalculator.taxAmount(lines)),
                _summaryRow('合計金額', TaxAmountCalculator.totalAmount(lines), emphasize: true),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(_isEdit ? '更新' : '登録'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(_DetailRow row) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Item>(
                    initialValue: row.item,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '品目 *'),
                    items: _itemOptions(row)
                        .map((i) => DropdownMenuItem(
                              value: i,
                              child: Text(i.isActive ? i.itemName : '${i.itemName}（取扱終了）'),
                            ))
                        .toList(),
                    onChanged: (item) => _onItemSelected(row, item),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeRow(row),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: row.quantityController,
                    decoration: const InputDecoration(labelText: '数量 *'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: row.unitPriceController,
                    decoration: const InputDecoration(labelText: '単価（税抜） *'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('金額: ¥${row.amount}'),
                Text('税率: ${_taxRateLabel(row)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _taxRateLabel(_DetailRow row) {
    if (row.resolvingTaxRate) return '解決中…';
    if (row.taxRateError != null) return 'エラー';
    if (row.resolvedTaxRate == null) return '-';
    return '${(row.resolvedTaxRate! * 100).toStringAsFixed(0)}%';
  }

  Widget _summaryRow(String label, num value, {bool emphasize = false}) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('¥$value', style: style),
        ],
      ),
    );
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
