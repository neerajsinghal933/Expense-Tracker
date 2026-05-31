import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as d;

import '../core/providers/app_providers.dart';
import '../data/db/app_database.dart';
import 'category_picker_sheet.dart';
import '../domain/constants/category_constants.dart';

Future<void> showManualTransactionSheet(BuildContext context) async {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _ManualTransactionForm(),
    ),
  );
}

class _ManualTransactionForm extends ConsumerStatefulWidget {
  const _ManualTransactionForm();

  @override
  _ManualTransactionFormState createState() => _ManualTransactionFormState();
}

class _ManualTransactionFormState
    extends ConsumerState<_ManualTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  String _type = 'debit';
  String? _selectedCategoryId;
  String _selectedCategoryName = 'Uncategorized';
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (time == null) return;
    if (!mounted) return;
    setState(() {
      _selectedDate =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickCategory() async {
    final catId = await showCategoryPicker(
      context,
      selectedId: _selectedCategoryId,
      filter: (c) {
        if (_type == 'credit') {
          return c.id == CategoryIds.salary ||
              c.id == CategoryIds.transfer ||
              c.id == CategoryIds.other;
        }
        return true;
      },
    );
    if (catId == null) return;
    // resolve name from provider
    if (!mounted) return;
    final cats = ref.read(categoriesProvider).valueOrNull ?? [];
    final fallbackTime = DateTime.now().millisecondsSinceEpoch;
    final cat = cats.firstWhere(
      (c) => c.id == catId,
      orElse: () => Category(
        id: catId,
        name: catId,
        parentId: null,
        colorHex: 'AAB3C0',
        createdAt: fallbackTime,
        updatedAt: fallbackTime,
      ),
    );
    setState(() {
      _selectedCategoryId = catId;
      _selectedCategoryName = cat.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.add_circle_outline,
                    size: 28, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add transaction', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text('Create a manual expense or income',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _merchantController,
                    decoration: const InputDecoration(
                        labelText: 'Merchant', prefixIcon: Icon(Icons.store)),
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter merchant'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: const Icon(Icons.currency_rupee),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calculate_outlined),
                        onPressed: _openCalculator,
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final val = double.tryParse(v ?? '');
                      if (val == null || val <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _type,
                          items: const [
                            DropdownMenuItem(
                                value: 'debit', child: Text('Expense')),
                            DropdownMenuItem(
                                value: 'credit', child: Text('Income')),
                          ],
                          onChanged: (v) => setState(() {
                            _type = v ?? 'debit';
                            if (_type == 'credit' &&
                                _selectedCategoryId != CategoryIds.salary &&
                                _selectedCategoryId != CategoryIds.transfer &&
                                _selectedCategoryId != CategoryIds.other) {
                              _selectedCategoryId = null;
                              _selectedCategoryName = 'Uncategorized';
                            }
                          }),
                          decoration: const InputDecoration(labelText: 'Type'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDateTime(context),
                          borderRadius: BorderRadius.circular(8),
                          child: InputDecorator(
                            decoration:
                                const InputDecoration(labelText: 'Date'),
                            child: Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} ${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _pickCategory,
                          icon: const Icon(Icons.category_outlined),
                          label: Text(_selectedCategoryName),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;
                            final merchant = _merchantController.text.trim();
                            final amount =
                                double.parse(_amountController.text.trim());
                            final repo =
                                ref.read(transactionRepositoryProvider);
                            final id = DateTime.now()
                                .millisecondsSinceEpoch
                                .toString();
                            final now = DateTime.now().millisecondsSinceEpoch;
                            await repo
                                .insertTransaction(TransactionsCompanion.insert(
                              id: id,
                              rawText: 'Manual: $merchant',
                              amount: amount,
                              currency: d.Value('INR'),
                              type: _type,
                              timestamp: _selectedDate.millisecondsSinceEpoch,
                              merchantName:
                                  d.Value(merchant.isEmpty ? null : merchant),
                              categoryId: d.Value(_selectedCategoryId),
                              paymentMethod: d.Value(null),
                              balance: d.Value(null),
                              reference: d.Value(null),
                              confidence: d.Value(1.0),
                              parsedBy: d.Value('manual'),
                              isDuplicate: d.Value(false),
                              createdAt: d.Value(now),
                              updatedAt: d.Value(now),
                            ));
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('Save transaction'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _openCalculator() async {
    final controller = TextEditingController(text: _amountController.text);
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount calculator',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Expression',
                  hintText: '1200 + 349 - 50',
                  prefixIcon: Icon(Icons.calculate_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final value = _evaluateExpression(controller.text);
                        if (value == null || value <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Enter a valid expression')),
                          );
                          return;
                        }
                        Navigator.pop(context, value);
                      },
                      child: const Text('Use result'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    setState(() => _amountController.text = result.toStringAsFixed(2));
  }

  double? _evaluateExpression(String input) {
    final clean = input.replaceAll(' ', '');
    if (clean.isEmpty || RegExp(r'[^0-9\.\+\-\*\/]').hasMatch(clean)) {
      return null;
    }
    final values = <double>[];
    final ops = <String>[];
    var number = '';

    int precedence(String op) => (op == '+' || op == '-') ? 1 : 2;
    bool applyTop() {
      if (values.length < 2 || ops.isEmpty) return false;
      final b = values.removeLast();
      final a = values.removeLast();
      final op = ops.removeLast();
      if (op == '/' && b == 0) return false;
      values.add(switch (op) {
        '+' => a + b,
        '-' => a - b,
        '*' => a * b,
        '/' => a / b,
        _ => b,
      });
      return true;
    }

    for (var i = 0; i < clean.length; i++) {
      final ch = clean[i];
      if (RegExp(r'[0-9\.]').hasMatch(ch)) {
        number += ch;
        continue;
      }
      final parsed = double.tryParse(number);
      if (parsed == null) return null;
      values.add(parsed);
      number = '';
      while (ops.isNotEmpty && precedence(ops.last) >= precedence(ch)) {
        if (!applyTop()) return null;
      }
      ops.add(ch);
    }
    final parsed = double.tryParse(number);
    if (parsed == null) return null;
    values.add(parsed);
    while (ops.isNotEmpty) {
      if (!applyTop()) return null;
    }
    return values.length == 1 ? values.single : null;
  }
}
