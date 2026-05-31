import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/ui_helpers.dart';
import '../../data/db/app_database.dart';

class StatsDashboardScreen extends ConsumerWidget {
  const StatsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = ref.watch(transactionsStreamProvider).valueOrNull ?? [];
    final categories = <String, Category>{
      for (final c in ref.watch(categoriesProvider).valueOrNull ?? []) c.id: c
    };
    final currency =
        ref.watch(userProfileProvider).valueOrNull?.preferredCurrency ?? 'INR';
    final stats = _Stats.fromTransactions(txs, categories);

    return Scaffold(
      appBar: AppBar(title: const Text('Stats dashboard')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
        children: [
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.85,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _MetricCard(
                  'Total income',
                  '$currency ${stats.income.toStringAsFixed(0)}',
                  Icons.trending_up),
              _MetricCard(
                  'Total expense',
                  '$currency ${stats.expense.toStringAsFixed(0)}',
                  Icons.trending_down),
              _MetricCard(
                  'Savings',
                  '$currency ${stats.savings.toStringAsFixed(0)}',
                  Icons.savings_outlined),
              _MetricCard(
                  'Transactions', '${txs.length}', Icons.receipt_long_outlined),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Income vs expense',
            child: SizedBox(
              height: 170,
              child: BarChart(
                BarChartData(
                  titlesData: const FlTitlesData(show: false),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _bar(0, stats.income, AppColors.successGreen),
                    _bar(1, stats.expense, AppColors.errorRed),
                    _bar(2, stats.savings.abs(), AppColors.accentStart),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Category breakdown',
            child: SizedBox(
              height: 190,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 26,
                  sections: stats.categoryTotals.entries.take(8).map((entry) {
                    final cat = categories[entry.key];
                    return PieChartSectionData(
                      value: entry.value,
                      color: _color(cat?.colorHex ?? 'AAB3C0'),
                      title: stats.expense > 0
                          ? '${(entry.value / stats.expense * 100).toStringAsFixed(0)}%'
                          : '',
                      radius: 58,
                      titleStyle:
                          const TextStyle(fontSize: 10, color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Monthly comparison',
            child: SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  titlesData: const FlTitlesData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: stats.monthlyExpense
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: AppColors.errorRed,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: stats.monthlyIncome
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: AppColors.successGreen,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Useful insights',
            child: Column(
              children: [
                _InsightRow('Highest spending category', stats.topCategoryName),
                _InsightRow('Average daily spend',
                    '$currency ${stats.averageDailySpend.toStringAsFixed(0)}'),
                _InsightRow('Income vs expense ratio', stats.ratio),
                _InsightRow('Peak spending day', stats.peakDay),
                _InsightRow('Largest transaction', stats.largestTransaction),
                _InsightRow('Repeated expenses',
                    '${stats.repeatedExpenseCount} possible repeats'),
                _InsightRow('Category concentration', stats.concentration),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats {
  const _Stats({
    required this.income,
    required this.expense,
    required this.savings,
    required this.categoryTotals,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.topCategoryName,
    required this.averageDailySpend,
    required this.ratio,
    required this.peakDay,
    required this.largestTransaction,
    required this.repeatedExpenseCount,
    required this.concentration,
  });

  final double income;
  final double expense;
  final double savings;
  final Map<String, double> categoryTotals;
  final List<double> monthlyIncome;
  final List<double> monthlyExpense;
  final String topCategoryName;
  final double averageDailySpend;
  final String ratio;
  final String peakDay;
  final String largestTransaction;
  final int repeatedExpenseCount;
  final String concentration;

  static _Stats fromTransactions(
    List<Transaction> txs,
    Map<String, Category> categories,
  ) {
    var income = 0.0;
    var expense = 0.0;
    final categoryTotals = <String, double>{};
    final daily = <String, double>{};
    Transaction? largest;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 11);
    final monthlyIncome = List<double>.filled(12, 0);
    final monthlyExpense = List<double>.filled(12, 0);
    final repeatKeys = <String, int>{};

    for (final t in txs) {
      final date = DateTime.fromMillisecondsSinceEpoch(t.timestamp);
      final monthIndex =
          (date.year - start.year) * 12 + date.month - start.month;
      final isIncome = t.type == 'credit' || t.type == 'refund';
      final isExpense =
          t.type == 'debit' || t.type == 'emi' || t.type == 'atm_withdrawal';
      if (isIncome) {
        income += t.amount;
        if (monthIndex >= 0 && monthIndex < 12) {
          monthlyIncome[monthIndex] += t.amount;
        }
      }
      if (isExpense) {
        expense += t.amount;
        if (monthIndex >= 0 && monthIndex < 12) {
          monthlyExpense[monthIndex] += t.amount;
        }
        final cat = t.categoryId ?? 'other';
        categoryTotals[cat] = (categoryTotals[cat] ?? 0) + t.amount;
        final dayKey = DateFormat('yyyy-MM-dd').format(date);
        daily[dayKey] = (daily[dayKey] ?? 0) + t.amount;
        final repeatKey =
            '${(t.merchantName ?? '').toLowerCase()}|${t.amount.toStringAsFixed(0)}';
        repeatKeys[repeatKey] = (repeatKeys[repeatKey] ?? 0) + 1;
      }
      if (largest == null || t.amount > largest.amount) {
        largest = t;
      }
    }

    final sortedCats = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sortedCats.isEmpty ? null : sortedCats.first;
    final sortedDays = daily.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final repeatCount = repeatKeys.values.where((count) => count >= 3).length;
    final concentration = top == null || expense == 0
        ? 'No expense data yet'
        : '${((top.value / expense) * 100).toStringAsFixed(0)}% in ${categories[top.key]?.name ?? top.key}';

    return _Stats(
      income: income,
      expense: expense,
      savings: income - expense,
      categoryTotals: Map.fromEntries(sortedCats),
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      topCategoryName:
          top == null ? 'No spend yet' : categories[top.key]?.name ?? top.key,
      averageDailySpend: daily.isEmpty ? 0 : expense / daily.length,
      ratio: expense == 0
          ? 'No expense yet'
          : '${(income / expense).toStringAsFixed(2)}x',
      peakDay: sortedDays.isEmpty
          ? 'No spend yet'
          : '${DateFormat('dd MMM yyyy').format(DateTime.parse(sortedDays.first.key))} · ${sortedDays.first.value.toStringAsFixed(0)}',
      largestTransaction: largest == null
          ? 'No transaction yet'
          : '${largest.merchantName ?? largest.type} · ${largest.amount.toStringAsFixed(0)}',
      repeatedExpenseCount: repeatCount,
      concentration: concentration,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const Spacer(),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

BarChartGroupData _bar(int x, double y, Color color) {
  return BarChartGroupData(
    x: x,
    barRods: [
      BarChartRodData(
        toY: y,
        color: color,
        width: 30,
        borderRadius: BorderRadius.circular(4),
      ),
    ],
  );
}

Color _color(String hex) {
  try {
    return Color(int.parse('FF$hex', radix: 16));
  } catch (_) {
    return const Color(0xFFAAB3C0);
  }
}
