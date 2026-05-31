import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/utils/format_utils.dart';
import '../../widgets/transaction_tile.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _typeFilter = 'all';
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _typeFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _typeFilter = value);
      },
      selectedColor: value == 'credit' 
          ? Colors.green.withOpacity(0.2)
          : value == 'debit'
              ? Colors.red.withOpacity(0.2)
              : Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: value == 'credit'
          ? Colors.green
          : value == 'debit'
              ? Colors.red
              : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final currency = profileAsync.valueOrNull?.preferredCurrency ?? 'INR';
    final catMap = {
      for (final c in categoriesAsync.valueOrNull ?? []) c.id: c.name,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          final filtered = transactions.where((tx) {
            // Apply type filter
            if (_typeFilter != 'all' && tx.type.toLowerCase() != _typeFilter) {
              return false;
            }
            
            // Apply search filter
            final q = _query.trim().toLowerCase();
            if (q.isEmpty) return true;
            final cat =
                (catMap[tx.categoryId] ?? tx.categoryId ?? '').toLowerCase();
            final values = [
              transactionTitle(tx),
              cat,
              tx.type,
              tx.amount.toStringAsFixed(2),
              formatTransactionDate(tx.timestamp),
              tx.rawText,
              tx.paymentMethod ?? '',
            ].join(' ').toLowerCase();
            return values.contains(q);
          }).toList();

          if (transactions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No transactions yet.\nImport sample SMS from Home (debug) or enable SMS in Settings.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search amount, category, note, type, date',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              if (_showFilters)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Credit', 'credit'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Debit', 'debit'),
                    ],
                  ),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No matching transactions.'))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 72),
                        itemBuilder: (context, index) {
                          final tx = filtered[index];
                          final cat =
                              catMap[tx.categoryId] ?? tx.categoryId ?? 'Other';
                          return TransactionTile(
                            merchant: transactionTitle(tx),
                            category: cat,
                            amount:
                                formatAmount(tx, currencyOverride: currency),
                            date: formatTransactionDate(tx.timestamp),
                            type: tx.type,
                            onTap: () => context.push('/transactions/${tx.id}'),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
      ),
    );
  }
}
