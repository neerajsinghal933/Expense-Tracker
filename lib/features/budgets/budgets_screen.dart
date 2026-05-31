import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/app_providers.dart';
import '../../data/db/app_database.dart';
import '../../widgets/category_picker_sheet.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsStreamProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final currency = profile?.preferredCurrency ?? 'INR';

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudget(context, ref),
        child: const Icon(Icons.add),
      ),
      body: budgetsAsync.when(
        data: (budgets) {
          if (budgets.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No budgets yet.\nTap + to set a monthly limit per category.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final catMap = categoriesAsync.valueOrNull ?? [];
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: budgets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final b = budgets[index];
              String catName = b.categoryId;
              for (final c in catMap) {
                if (c.id == b.categoryId) {
                  catName = c.name;
                  break;
                }
              }
              return Card(
                child: ListTile(
                  title: Text(catName),
                  subtitle: Text('${b.period} limit'),
                  trailing: Text('$currency ${b.amount.toStringAsFixed(0)}'),
                  onLongPress: () =>
                      ref.read(budgetRepositoryProvider).delete(b.id),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _showAddBudget(BuildContext context, WidgetRef ref) async {
    String? categoryId;
    try {
      categoryId = await showCategoryPicker(context);
      if (categoryId == null || !context.mounted) return;

      // Use a dialog widget that owns and disposes its own TextEditingController
      final double? amount = await showDialog<double>(
        context: context,
        builder: (ctx) => _AddBudgetDialog(),
      );

      if (amount == null) return;
      if (amount <= 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please enter a valid amount greater than zero')),
          );
        }
        return;
      }

      await ref.read(budgetRepositoryProvider).upsert(
            BudgetsCompanion.insert(
              id: const Uuid().v4(),
              categoryId: categoryId,
              period: 'monthly',
              amount: amount,
            ),
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget saved')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add budget: $e')),
        );
      }
    }
  }
}

// Dialog widget that owns its TextEditingController and disposes it in dispose().
class _AddBudgetDialog extends StatefulWidget {
  const _AddBudgetDialog({Key? key}) : super(key: key);

  @override
  State<_AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<_AddBudgetDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSave() {
    final parsed = double.tryParse(_controller.text.trim());
    final amount = parsed ?? 0;
    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Monthly budget'),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Amount'),
        autofocus: true,
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(onPressed: _onSave, child: const Text('Save')),
      ],
    );
  }
}
