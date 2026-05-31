import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/ui_helpers.dart';
import '../../data/db/app_database.dart';
import '../../services/analytics/analytics_service.dart';

enum TrendMode { daily, weekly, monthly, yearly }

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  TrendMode _trendMode = TrendMode.daily;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(monthlyAnalyticsProvider(_month));
    final transactions =
        ref.watch(transactionsStreamProvider).valueOrNull ?? [];
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final currency = profile?.preferredCurrency ?? 'INR';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            tooltip: 'Stats dashboard',
            icon: const Icon(Icons.query_stats_outlined),
            onPressed: () => context.push('/analytics/stats'),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              _month = DateTime(_month.year, _month.month - 1);
            }),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              _month = DateTime(_month.year, _month.month + 1);
            }),
          ),
        ],
      ),
      body: summaryAsync.when(
        data: (summary) {
          final insights = ref.read(analyticsServiceProvider).insights(summary);
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(_month),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const TabBar(
                          tabs: [Tab(text: 'Expense'), Tab(text: 'Income')],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _AnalyticsTab(
                        summary: summary,
                        transactions: transactions,
                        currency: currency,
                        mode: _trendMode,
                        onModeChanged: (mode) =>
                            setState(() => _trendMode = mode),
                        categories: summary.byCategoryExpense,
                        total: summary.totalExpense,
                        isIncome: false,
                        insights: insights,
                        month: _month,
                      ),
                      _AnalyticsTab(
                        summary: summary,
                        transactions: transactions,
                        currency: currency,
                        mode: _trendMode,
                        onModeChanged: (mode) =>
                            setState(() => _trendMode = mode),
                        categories: summary.byCategoryIncome,
                        total: summary.totalIncome,
                        isIncome: true,
                        insights: const [],
                        month: _month,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab({
    required this.summary,
    required this.transactions,
    required this.currency,
    required this.mode,
    required this.onModeChanged,
    required this.categories,
    required this.total,
    required this.isIncome,
    required this.insights,
    required this.month,
  });

  final MonthlySummary summary;
  final List<Transaction> transactions;
  final String currency;
  final TrendMode mode;
  final ValueChanged<TrendMode> onModeChanged;
  final List<CategorySpend> categories;
  final double total;
  final bool isIncome;
  final List<AnalyticsInsight> insights;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final savings = summary.totalIncome - summary.totalExpense;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isIncome
                  ? const [Color(0xFF064E3B), Color(0xFF0F766E)]
                  : const [Color(0xFF172554), Color(0xFF312E81)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Income',
                  value: '$currency ${summary.totalIncome.toStringAsFixed(0)}',
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Expense',
                  value: '$currency ${summary.totalExpense.toStringAsFixed(0)}',
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Savings',
                  value: '$currency ${savings.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text('Category mix', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: Row(
            children: [
              Expanded(
                  child: _PieBreakdown(categories: categories, total: total)),
              const SizedBox(width: 10),
              Expanded(
                  child: _CategoryList(
                      categories: categories,
                      total: total,
                      currency: currency)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Trend', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            SegmentedButton<TrendMode>(
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              segments: const [
                ButtonSegment(value: TrendMode.daily, label: Text('D')),
                ButtonSegment(value: TrendMode.weekly, label: Text('W')),
                ButtonSegment(value: TrendMode.monthly, label: Text('M')),
                ButtonSegment(value: TrendMode.yearly, label: Text('Y')),
              ],
              selected: {mode},
              onSelectionChanged: (value) => onModeChanged(value.first),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GlassContainer(
          borderRadius: 8,
          child: SizedBox(
            height: 165,
            child: _TrendChart(
              points:
                  _trendPoints(transactions, summary, mode, month, isIncome),
              color: isIncome ? AppColors.successGreen : AppColors.accentStart,
            ),
          ),
        ),
        if (!isIncome) ...[
          const SizedBox(height: 16),
          Text('Insights', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...insights.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassContainer(
                borderRadius: 8,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.auto_awesome_outlined),
                  title: Text(i.title),
                  subtitle: Text(i.body),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PieBreakdown extends StatelessWidget {
  const _PieBreakdown({required this.categories, required this.total});

  final List<CategorySpend> categories;
  final double total;

  @override
  Widget build(BuildContext context) {
    final source = categories.isEmpty
        ? const [
            CategorySpend(
                categoryId: 'empty',
                categoryName: 'No data',
                colorHex: 'AAB3C0',
                amount: 1)
          ]
        : categories.take(8).toList();
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 24,
        sections: source.map((c) {
          final pct = total > 0 ? c.amount / total * 100 : 0.0;
          return PieChartSectionData(
            value: c.amount,
            title: total > 0 ? '${pct.toStringAsFixed(0)}%' : '',
            color: _color(c.colorHex),
            radius: 58,
            titleStyle: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryList extends StatefulWidget {
  const _CategoryList({
    required this.categories,
    required this.total,
    required this.currency,
  });

  final List<CategorySpend> categories;
  final double total;
  final String currency;

  @override
  State<_CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<_CategoryList> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return const Center(child: Text('No category data'));
    }
    return Scrollbar(
      controller: _controller,
      thumbVisibility: widget.categories.length > 4,
      child: ListView.builder(
        controller: _controller,
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          final c = widget.categories[index];
          final pct = widget.total > 0 ? c.amount / widget.total * 100 : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _color(c.colorHex),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.categoryName,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  '${widget.currency} ${c.amount.toStringAsFixed(0)} · ${pct.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points, required this.color});

  final List<double> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final spots = points.isEmpty
        ? [const FlSpot(0, 0)]
        : points
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList();
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.16),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}

List<double> _trendPoints(
  List<Transaction> txs,
  MonthlySummary summary,
  TrendMode mode,
  DateTime month,
  bool income,
) {
  bool include(Transaction t) {
    if (income) return t.type == 'credit' || t.type == 'refund';
    return t.type == 'debit' || t.type == 'emi' || t.type == 'atm_withdrawal';
  }

  switch (mode) {
    case TrendMode.daily:
      if (!income) return summary.dailySpend;
      final days =
          List<double>.filled(DateTime(month.year, month.month + 1, 0).day, 0);
      for (final t in txs.where(include)) {
        final d = DateTime.fromMillisecondsSinceEpoch(t.timestamp);
        if (d.year == month.year && d.month == month.month) {
          days[d.day - 1] += t.amount;
        }
      }
      return days;
    case TrendMode.weekly:
      final weeks = List<double>.filled(5, 0);
      for (final t in txs.where(include)) {
        final d = DateTime.fromMillisecondsSinceEpoch(t.timestamp);
        if (d.year == month.year && d.month == month.month) {
          final index = ((d.day - 1) / 7).floor().clamp(0, 4);
          weeks[index] += t.amount;
        }
      }
      return weeks;
    case TrendMode.monthly:
      final start = DateTime(month.year, month.month - 11);
      final values = List<double>.filled(12, 0);
      for (final t in txs.where(include)) {
        final d = DateTime.fromMillisecondsSinceEpoch(t.timestamp);
        final index = (d.year - start.year) * 12 + d.month - start.month;
        if (index >= 0 && index < values.length) values[index] += t.amount;
      }
      return values;
    case TrendMode.yearly:
      final startYear = month.year - 4;
      final values = List<double>.filled(5, 0);
      for (final t in txs.where(include)) {
        final d = DateTime.fromMillisecondsSinceEpoch(t.timestamp);
        final index = d.year - startYear;
        if (index >= 0 && index < values.length) values[index] += t.amount;
      }
      return values;
  }
}

Color _color(String hex) {
  try {
    return Color(int.parse('FF$hex', radix: 16));
  } catch (_) {
    return const Color(0xFFAAB3C0);
  }
}
