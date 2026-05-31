import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/ui_helpers.dart';
import '../../data/db/app_database.dart';
import '../../widgets/transaction_list_section.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final uncategorized =
        ref.watch(uncategorizedStreamProvider).valueOrNull ?? [];
    final catNames = <String, String>{
      for (final c in ref.watch(categoriesProvider).valueOrNull ?? <Category>[])
        c.id: c.name,
    };

    return Scaffold(
      appBar: AppBar(
        title: profileAsync.when(
          data: (p) => Text(
            p == null ? 'Home' : 'Hi, ${p.fullName.split(' ').first}',
          ),
          loading: () => const Text('Home'),
          error: (_, __) => const Text('Home'),
        ),
      ),
      body: SafeArea(
        child: transactionsAsync.when(
          data: (transactions) => Column(
            children: [
              if (uncategorized.isNotEmpty)
                MaterialBanner(
                  content: Text(
                    '${uncategorized.length} transaction(s) need a category',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => context.push(
                        '/transactions/${uncategorized.first.id}',
                      ),
                      child: const Text('Review'),
                    ),
                  ],
                ),
              Expanded(
                child: _DashboardBody(
                  transactions: transactions,
                  currency:
                      profileAsync.valueOrNull?.preferredCurrency ?? 'INR',
                  categoryNames: catNames,
                  onViewAll: () => context.go('/transactions'),
                  onTransactionTap: (tx) =>
                      context.push('/transactions/${tx.id}'),
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load: $e')),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.transactions,
    required this.currency,
    required this.categoryNames,
    required this.onViewAll,
    this.onTransactionTap,
  });

  final List<Transaction> transactions;
  final String currency;
  final Map<String, String> categoryNames;
  final VoidCallback onViewAll;
  final void Function(Transaction tx)? onTransactionTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month).millisecondsSinceEpoch;

    final monthDebits = transactions.where((t) {
      return t.timestamp >= monthStart &&
          (t.type == 'debit' || t.type == 'emi' || t.type == 'atm_withdrawal');
    });
    final monthCredits = transactions.where((t) {
      return t.timestamp >= monthStart &&
          (t.type == 'credit' || t.type == 'refund');
    });

    final monthSpend = monthDebits.fold<double>(0, (s, t) => s + t.amount);
    final monthIncome = monthCredits.fold<double>(0, (s, t) => s + t.amount);
    final savings = monthIncome - monthSpend;
    final balance = transactions.fold<double>(0, (sum, t) {
      if (t.type == 'credit' || t.type == 'refund') return sum + t.amount;
      if (t.type == 'failed') return sum;
      return sum - t.amount;
    });
    final categoryTotals = <String, double>{};
    for (final t in monthDebits) {
      final id = t.categoryId ?? 'Other';
      categoryTotals[id] = (categoryTotals[id] ?? 0) + t.amount;
    }
    final topCategory = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategoryName = topCategory.isEmpty
        ? 'No spend yet'
        : categoryNames[topCategory.first.key] ?? topCategory.first.key;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF12312E), Color(0xFF172554)],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Balance snapshot',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                '$currency ${balance.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SummaryStat(
                      label: 'Income',
                      value: '$currency ${monthIncome.toStringAsFixed(0)}',
                      caption: 'This month',
                    ),
                  ),
                  Expanded(
                    child: _SummaryStat(
                      label: 'Expense',
                      value: '$currency ${monthSpend.toStringAsFixed(0)}',
                      caption: 'This month',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GlassContainer(
                borderRadius: 8,
                child: _SummaryStat(
                  label: 'Savings',
                  value: '$currency ${savings.toStringAsFixed(0)}',
                  caption: savings >= 0 ? 'On track' : 'Needs attention',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassContainer(
                borderRadius: 8,
                child: _SummaryStat(
                  label: 'Top category',
                  value: topCategoryName,
                  caption: topCategory.isEmpty
                      ? 'This month'
                      : '$currency ${topCategory.first.value.toStringAsFixed(0)}',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassContainer(
          borderRadius: 8,
          child: Row(
            children: [
              const Icon(Icons.insights_outlined, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  transactions.isEmpty
                      ? 'Add or import transactions to unlock monthly insights.'
                      : '${transactions.length} total transactions · ${monthDebits.length} expenses this month',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'No transactions yet.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          TransactionListSection(
            transactions: transactions,
            currency: currency,
            maxItems: 5,
            categoryNames: categoryNames,
            onViewAll: onViewAll,
            onTransactionTap: onTransactionTap,
          ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(caption, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
