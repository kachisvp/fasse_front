import 'package:flutter/material.dart';

import '../../shared/tax/tax_amount_calculator.dart';
import '../../shared/tax/tax_rate_resolver.dart';
import '../../shared/tax/taxable_line.dart';
import '../../shared/utils/date_format.dart';
import '../../shared/widgets/async_value_builder.dart';
import '../../shared/widgets/snackbar.dart';
import '../menus/menu.dart';
import '../menus/menus_api.dart';
import 'payment_method.dart';
import 'sales_api.dart';
import 'sales_detail.dart';
import 'sales_order.dart';

class _SalesFormData {
  _SalesFormData(this.menus, this.existing);

  final List<Menu> menus;
  final SalesOrder? existing;
}

class _DetailRow {
  _DetailRow({this.detailId, this.menu, String quantity = '', String unitPrice = ''})
      : quantityController = TextEditingController(text: quantity),
        unitPriceController = TextEditingController(text: unitPrice);

  final String? detailId;
  Menu? menu;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  num? resolvedTaxRate;
  bool resolvingTaxRate = false;
  Object? taxRateError;

  int get quantity => int.tryParse(quantityController.text.trim()) ?? 0;
  num get unitPrice => num.tryParse(unitPriceController.text.trim()) ?? 0;
  num get amount => quantity * unitPrice;

  void dispose() {
    quantityController.dispose();
    unitPriceController.dispose();
  }
}

class SalesFormScreen extends StatefulWidget {
  const SalesFormScreen({super.key, this.salesId});

  final String? salesId;

  @override
  State<SalesFormScreen> createState() => _SalesFormScreenState();
}

class _SalesFormScreenState extends State<SalesFormScreen> {
  final SalesApi _salesApi = SalesApi();
  final TaxRateResolver _taxRateResolver = TaxRateResolver();
  final _tableNoController = TextEditingController();
  final _customerCountController = TextEditingController(text: '1');
  final _discountController = TextEditingController(text: '0');
  final _remarksController = TextEditingController();

  late Future<_SalesFormData> _loadFuture;
  List<Menu> _menus = [];

  DateTime _salesDatetime = DateTime.now();
  DateTime _businessDate = DateTime.now();
  String? _paymentMethod;
  final List<_DetailRow> _rows = [];
  bool _submitting = false;
  bool _initialized = false;

  bool get _isEdit => widget.salesId != null;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  @override
  void dispose() {
    _tableNoController.dispose();
    _customerCountController.dispose();
    _discountController.dispose();
    _remarksController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<_SalesFormData> _load() async {
    final results = await Future.wait([
      MenusApi().list(),
      widget.salesId == null ? Future.value(null) : _salesApi.get(widget.salesId!),
    ]);
    return _SalesFormData(results[0] as List<Menu>, results[1] as SalesOrder?);
  }

  void _initializeFromData(_SalesFormData data) {
    if (_initialized) return;
    _initialized = true;
    _menus = data.menus;

    final existing = data.existing;
    if (existing != null) {
      _salesDatetime = parseIsoDateTime(existing.salesDatetime);
      _businessDate = parseIsoDate(existing.businessDate);
      _tableNoController.text = existing.tableNo ?? '';
      _customerCountController.text = existing.customerCount.toString();
      _discountController.text = _formatNum(existing.discountAmount);
      _paymentMethod = existing.paymentMethod;
      _remarksController.text = existing.remarks ?? '';
      for (final detail in existing.details) {
        final menu = _menus.where((m) => m.id == detail.menuId).firstOrNull;
        final row = _DetailRow(
          detailId: detail.id,
          menu: menu,
          quantity: detail.quantity.toString(),
          unitPrice: _formatNum(detail.unitPrice),
        );
        row.resolvedTaxRate = detail.taxRate;
        _rows.add(row);
      }
    }
  }

  String _formatNum(num value) => value == value.roundToDouble() ? value.toInt().toString() : value.toString();

  List<Menu> _menuOptions(_DetailRow row) {
    final active = _menus.where((m) => m.isActive).toList();
    if (row.menu != null && !row.menu!.isActive && !active.any((m) => m.id == row.menu!.id)) {
      return [...active, row.menu!];
    }
    return active;
  }

  void _addRow() => setState(() => _rows.add(_DetailRow()));

  void _removeRow(_DetailRow row) {
    setState(() {
      _rows.remove(row);
      row.dispose();
    });
  }

  Future<void> _onMenuSelected(_DetailRow row, Menu? menu) async {
    setState(() {
      row.menu = menu;
      if (menu != null && row.unitPriceController.text.trim().isEmpty) {
        row.unitPriceController.text = _formatNum(menu.standardPrice);
      }
    });
    await _resolveRowTaxRate(row);
  }

  Future<void> _resolveRowTaxRate(_DetailRow row) async {
    if (row.menu == null) return;
    setState(() {
      row.resolvingTaxRate = true;
      row.taxRateError = null;
    });
    try {
      final rate = await _taxRateResolver.resolveRate(row.menu!.taxCategory, _businessDate);
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

  Future<void> _reResolveAllRows() async {
    for (final row in _rows) {
      if (row.menu != null) {
        // ignore: unawaited_futures
        _resolveRowTaxRate(row);
      }
    }
  }

  Future<void> _pickSalesDatetime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _salesDatetime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_salesDatetime),
    );
    if (time == null) return;
    setState(() {
      _salesDatetime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickBusinessDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _businessDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _businessDate = picked);
    await _reResolveAllRows();
  }

  List<TaxableLine> _taxableLines() {
    return _rows
        .where((r) => r.menu != null && r.resolvedTaxRate != null)
        .map((r) => TaxableLine(amount: r.amount, taxRate: r.resolvedTaxRate!))
        .toList();
  }

  num get _discountAmount => num.tryParse(_discountController.text.trim()) ?? 0;

  String? _validate() {
    if (_paymentMethod == null) return '支払方法を選択してください';
    if (_rows.isEmpty) return '明細行を1件以上追加してください';
    for (final row in _rows) {
      if (row.menu == null) return '明細行のメニューを選択してください';
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
    final sales = SalesOrder(
      id: widget.salesId,
      salesDatetime: formatIsoDateTime(_salesDatetime),
      businessDate: formatIsoDate(_businessDate),
      tableNo: _tableNoController.text.trim().isEmpty ? null : _tableNoController.text.trim(),
      customerCount: int.tryParse(_customerCountController.text.trim()) ?? 1,
      subtotal: TaxAmountCalculator.subtotal(lines),
      taxAmount: TaxAmountCalculator.taxAmount(lines),
      discountAmount: _discountAmount,
      totalAmount: TaxAmountCalculator.totalAmount(lines, discountAmount: _discountAmount),
      paymentMethod: _paymentMethod!,
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      details: _rows
          .map((r) => SalesDetail(
                menuId: r.menu!.id!,
                quantity: r.quantity,
                unitPrice: r.unitPrice,
                amount: r.amount,
                taxRate: r.resolvedTaxRate!,
              ))
          .toList(),
    );

    try {
      if (_isEdit) {
        await _salesApi.update(widget.salesId!, sales);
      } else {
        await _salesApi.create(sales);
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
      appBar: AppBar(title: Text(_isEdit ? '売上伝票の変更' : '売上伝票の追加')),
      body: AsyncValueBuilder<_SalesFormData>(
        future: _loadFuture,
        builder: (context, data) {
          _initializeFromData(data);
          final lines = _taxableLines();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('売上日時 *'),
                  subtitle: Text(_salesDatetime.toString()),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickSalesDatetime,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('営業日 *'),
                  subtitle: Text(formatIsoDate(_businessDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickBusinessDate,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tableNoController,
                  decoration: const InputDecoration(labelText: '卓番'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customerCountController,
                  decoration: const InputDecoration(labelText: '人数'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(labelText: '支払方法 *'),
                  items: PaymentMethod.values
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _paymentMethod = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _discountController,
                  decoration: const InputDecoration(labelText: '値引き額'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
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
                _summaryRow('値引き額', -_discountAmount),
                _summaryRow(
                  '合計金額',
                  TaxAmountCalculator.totalAmount(lines, discountAmount: _discountAmount),
                  emphasize: true,
                ),
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
                  child: DropdownButtonFormField<Menu>(
                    initialValue: row.menu,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'メニュー *'),
                    items: _menuOptions(row)
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m.isActive ? m.menuName : '${m.menuName}（取扱終了）'),
                            ))
                        .toList(),
                    onChanged: (menu) => _onMenuSelected(row, menu),
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
                    keyboardType: TextInputType.number,
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
