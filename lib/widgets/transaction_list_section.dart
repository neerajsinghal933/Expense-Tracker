import 'package:flutter/material.dart';

import '../core/utils/format_utils.dart';
import '../data/db/app_database.dart';
import 'transaction_tile.dart';

class TransactionListSection extends StatelessWidget {
  const TransactionListSection({
    super.key,
    required this.transactions,
    required this.currency,
    this.maxItems,
    this.onViewAll,
    this.onTransactionTap,
    this.categoryNames = const {},
  });

  final List<Transaction> transactions;
  final String currency;
  final int? maxItems;
  final VoidCallback? onViewAll;
  final void Function(Transaction tx)? onTransactionTap;
  final Map<String, String> categoryNames;

  @override
  Widget build(BuildContext context) {
    final visible =
        maxItems == null ? transactions : transactions.take(maxItems!).toList();

    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Recent transactions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            if (onViewAll != null && transactions.length > (maxItems ?? 0))
              TextButton(onPressed: onViewAll, child: const Text('See all')),
          ],
        ),
        const SizedBox(height: 8),
        ...visible.map((tx) {
          final cat = categoryNames[tx.categoryId] ?? tx.categoryId ?? 'Other';
          return TransactionTile(
            merchant: transactionTitle(tx),
            category: cat,
            amount: formatAmount(tx, currencyOverride: currency),
            date: formatTransactionDate(tx.timestamp),
            type: tx.type,
            onTap:
                onTransactionTap == null ? null : () => onTransactionTap!(tx),
          );
        }),
      ],
    );
  }
}
