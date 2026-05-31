import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as d;

import '../../core/providers/app_providers.dart';
import '../../domain/constants/category_constants.dart';
import '../../core/utils/format_utils.dart';
import '../../services/categorization/categorization_service.dart';
import '../../widgets/category_picker_sheet.dart';
import '../../data/db/app_database.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.id});

  final String id;

  Future<void> _deleteTransaction(
    BuildContext context,
    WidgetRef ref,
    String txId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final transactions = ref.read(transactionRepositoryProvider);

    await transactions.deleteTransaction(txId);

    if (!context.mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Transaction deleted')),
    );
  }

  Future<void> _editTransaction(
    BuildContext context,
    WidgetRef ref,
    Transaction tx,
  ) async {
    final amountController = TextEditingController(
      text: tx.amount.toStringAsFixed(2),
    );
    final merchantController = TextEditingController(
      text: tx.merchantName ?? '',
    );
    final dateTime = DateTime.fromMillisecondsSinceEpoch(tx.timestamp);
    var selectedType = tx.type == 'credit' ? 'credit' : 'debit';
    var selectedCategoryId = tx.categoryId;
    String categoryName(String? id) {
      final cats = ref.read(categoriesProvider).valueOrNull ?? [];
      for (final c in cats) {
        if (c.id == id) return c.name;
      }
      return id ?? 'Uncategorized';
    }

    Future<void> save(BuildContext dialogContext) async {
      final amount = double.tryParse(amountController.text.trim()) ?? tx.amount;
      final merchant = merchantController.text.trim();
      final messenger = ScaffoldMessenger.of(context);
      final transactions = ref.read(transactionRepositoryProvider);

      if (amount <= 0) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
        return;
      }

      try {
        await transactions.updateTransaction(
          TransactionsCompanion(
            id: d.Value(tx.id),
            rawText: d.Value(
              merchant.isEmpty ? tx.rawText : 'Manual: $merchant',
            ),
            amount: d.Value(amount),
            currency: d.Value(tx.currency),
            type: d.Value(selectedType),
            timestamp: d.Value(tx.timestamp),
            merchantName: d.Value(merchant.isEmpty ? null : merchant),
            categoryId: d.Value(selectedCategoryId),
            paymentMethod: d.Value(tx.paymentMethod),
            balance: d.Value(tx.balance),
            reference: d.Value(tx.reference),
            confidence: d.Value(tx.confidence),
            parsedBy: d.Value(tx.parsedBy),
            createdAt: d.Value(tx.createdAt),
            updatedAt: d.Value(DateTime.now().millisecondsSinceEpoch),
            isDuplicate: d.Value(tx.isDuplicate),
          ),
        );

        if (!context.mounted || !dialogContext.mounted) return;
        Navigator.pop(dialogContext);
        messenger.showSnackBar(
          const SnackBar(content: Text('Transaction updated')),
        );
      } catch (e) {
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Edit Transaction'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: merchantController,
                    decoration: const InputDecoration(labelText: 'Merchant'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: 'debit', child: Text('Expense')),
                      DropdownMenuItem(value: 'credit', child: Text('Income')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedType = value;
                        if (value == 'credit' &&
                            selectedCategoryId != CategoryIds.salary &&
                            selectedCategoryId != CategoryIds.transfer &&
                            selectedCategoryId != CategoryIds.other) {
                          selectedCategoryId = CategoryIds.salary;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final catId = await showCategoryPicker(
                        context,
                        selectedId: selectedCategoryId,
                        filter: (cat) {
                          if (selectedType == 'credit') {
                            return cat.id == CategoryIds.salary ||
                                cat.id == CategoryIds.transfer ||
                                cat.id == CategoryIds.other;
                          }
                          return true;
                        },
                      );
                      if (catId == null) return;
                      setDialogState(() => selectedCategoryId = catId);
                    },
                    icon: const Icon(Icons.category_outlined),
                    label: Text(categoryName(selectedCategoryId)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Date: ${DateFormat('dd MMM yyyy, HH:mm').format(dateTime)}',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => save(ctx),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );
    } finally {
      amountController.dispose();
      merchantController.dispose();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final transactionAsync = ref.watch(transactionByIdProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction')),
      body: transactionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (tx) {
          if (tx == null) {
            return const Center(child: Text('Transaction not found'));
          }

          final suggestedCategoryId = CategorizationService.suggestCategoryId(
            merchantName: tx.merchantName,
            rawText: tx.rawText,
          );
          final selectedCategoryId = _isUncategorized(tx.categoryId)
              ? suggestedCategoryId
              : tx.categoryId;

          var catName = tx.categoryId ?? 'Uncategorized';
          var suggestedCatName = '';
          for (final c in categoriesAsync.valueOrNull ?? []) {
            if (c.id == tx.categoryId) {
              catName = c.name;
            }
            if (c.id == suggestedCategoryId) {
              suggestedCatName = c.name;
            }
          }
          if (_isUncategorized(tx.categoryId) && suggestedCatName.isNotEmpty) {
            catName = '$suggestedCatName (suggested)';
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                formatAmount(tx),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(transactionTitle(tx),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _Row('Category', catName),
              _Row('Type', tx.type),
              _Row(
                'Date',
                DateFormat('dd MMM yyyy, HH:mm').format(
                  DateTime.fromMillisecondsSinceEpoch(tx.timestamp),
                ),
              ),
              _Row('Payment', tx.paymentMethod ?? '—'),
              _Row(
                  'Confidence', '${(tx.confidence * 100).toStringAsFixed(0)}%'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  final catId = await showCategoryPicker(
                    context,
                    selectedId: selectedCategoryId,
                    filter: (cat) {
                      // If transaction is credit, prefer income categories (salary/transfer)
                      if (tx.type == 'credit') {
                        return cat.id == CategoryIds.salary ||
                            cat.id == CategoryIds.transfer ||
                            cat.id == CategoryIds.other;
                      }
                      return true;
                    },
                  );
                  if (catId == null || !context.mounted) return;

                  final messenger = ScaffoldMessenger.of(context);
                  final transactions = ref.read(transactionRepositoryProvider);
                  final merchantRules =
                      ref.read(merchantRuleRepositoryProvider);
                  try {
                    await transactions.updateCategory(tx.id, catId);
                    if (tx.merchantName != null) {
                      await merchantRules.learnCategory(
                        merchantName: tx.merchantName!,
                        categoryId: catId,
                      );
                    }

                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Category updated')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                icon: const Icon(Icons.category_outlined),
                label: const Text('Change category'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _editTransaction(context, ref, tx),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _deleteTransaction(context, ref, tx.id),
                      icon: const Icon(Icons.delete_outlined),
                      label: const Text('Delete'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Raw SMS', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(tx.rawText, style: Theme.of(context).textTheme.bodySmall),
            ],
          );
        },
      ),
    );
  }
}

bool _isUncategorized(String? categoryId) {
  return categoryId == null || categoryId == CategoryIds.uncategorized;
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
