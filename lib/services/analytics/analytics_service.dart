import '../../data/db/app_database.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/constants/category_constants.dart';

class CategorySpend {
  final String categoryId;
  final String categoryName;
  final String colorHex;
  final double amount;

  const CategorySpend({
    required this.categoryId,
    required this.categoryName,
    required this.colorHex,
    required this.amount,
  });
}

class MonthlySummary {
  final int year;
  final int month;
  final double totalExpense;
  final double totalIncome;
  final List<CategorySpend> byCategoryExpense;
  final List<CategorySpend> byCategoryIncome;
  final List<double> dailySpend;

  const MonthlySummary({
    required this.year,
    required this.month,
    required this.totalExpense,
    required this.totalIncome,
    required this.byCategoryExpense,
    required this.byCategoryIncome,
    required this.dailySpend,
  });
}

class AnalyticsInsight {
  final String title;
  final String body;

  const AnalyticsInsight({required this.title, required this.body});
}

class AnalyticsService {
  AnalyticsService({
    required TransactionRepository transactions,
    required AppDatabase db,
  })  : _transactions = transactions,
        _db = db;

  final TransactionRepository _transactions;
  final AppDatabase _db;

  Future<MonthlySummary> monthlySummary(int year, int month) async {
    try {
      final txs = await _transactions.getAll();
      final start = DateTime(year, month).millisecondsSinceEpoch;
      final end = DateTime(year, month + 1).millisecondsSinceEpoch;
      final monthTxs =
          txs.where((t) => t.timestamp >= start && t.timestamp < end).toList();

      final categories = await _db.select(_db.categories).get();
      final catMap = {for (final c in categories) c.id: c};

      var expense = 0.0;
      var income = 0.0;
      final catTotals = <String, double>{};
      final catTotalsIncome = <String, double>{};
      final daysInMonth = DateTime(year, month + 1, 0).day; // last day of month
      final daily = List<double>.filled(daysInMonth, 0);

      for (final t in monthTxs) {
        if (t.type == 'failed' || t.amount <= 0) continue;

        final day = DateTime.fromMillisecondsSinceEpoch(t.timestamp).day;
        if (day < 1 || day > daily.length) continue;

        if (t.type == 'credit' || t.type == 'refund') {
          income += t.amount;
          final catId = t.categoryId ?? CategoryIds.other;
          catTotalsIncome[catId] = (catTotalsIncome[catId] ?? 0) + t.amount;
        } else {
          expense += t.amount;
          final catId = t.categoryId ?? CategoryIds.other;
          catTotals[catId] = (catTotals[catId] ?? 0) + t.amount;
          if (day <= daily.length) daily[day - 1] += t.amount;
        }
      }

      final byCategory = catTotals.entries.map((e) {
        final cat = catMap[e.key];
        return CategorySpend(
          categoryId: e.key,
          categoryName: cat?.name ?? e.key,
          colorHex: cat?.colorHex ?? 'AAB3C0',
          amount: e.value,
        );
      }).toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

      final byCategoryIncome = catTotalsIncome.entries.map((e) {
        final cat = catMap[e.key];
        return CategorySpend(
          categoryId: e.key,
          categoryName: cat?.name ?? e.key,
          colorHex: cat?.colorHex ?? 'AAB3C0',
          amount: e.value,
        );
      }).toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

      return MonthlySummary(
        year: year,
        month: month,
        totalExpense: expense,
        totalIncome: income,
        byCategoryExpense: byCategory,
        byCategoryIncome: byCategoryIncome,
        dailySpend: daily,
      );
    } catch (e) {
      // If anything goes wrong, return empty summary instead of crashing
      return MonthlySummary(
        year: year,
        month: month,
        totalExpense: 0,
        totalIncome: 0,
        byCategoryExpense: [],
        byCategoryIncome: [],
        dailySpend: List.filled(DateTime(year, month + 1, 0).day, 0),
      );
    }
  }

  List<AnalyticsInsight> insights(MonthlySummary summary) {
    final insights = <AnalyticsInsight>[];
    if (summary.byCategoryExpense.isNotEmpty) {
      final top = summary.byCategoryExpense.first;
      final concentration = summary.totalExpense > 0
          ? (top.amount / summary.totalExpense * 100)
          : 0.0;
      insights.add(AnalyticsInsight(
        title: 'Top spending category',
        body:
            '${top.categoryName} accounts for ${top.amount.toStringAsFixed(0)} this month.',
      ));
      insights.add(AnalyticsInsight(
        title: 'Category concentration',
        body:
            '${concentration.toStringAsFixed(0)}% of spending sits in ${top.categoryName}.',
      ));
    }
    if (summary.dailySpend.isNotEmpty) {
      final activeDays = summary.dailySpend.where((v) => v > 0).length;
      final average = activeDays == 0 ? 0 : summary.totalExpense / activeDays;
      var peakIndex = 0;
      for (var i = 1; i < summary.dailySpend.length; i++) {
        if (summary.dailySpend[i] > summary.dailySpend[peakIndex]) {
          peakIndex = i;
        }
      }
      insights.add(AnalyticsInsight(
        title: 'Average daily spend',
        body: '${average.toStringAsFixed(0)} across $activeDays active day(s).',
      ));
      if (summary.dailySpend[peakIndex] > 0) {
        insights.add(AnalyticsInsight(
          title: 'Peak spending day',
          body:
              'Day ${peakIndex + 1} was highest at ${summary.dailySpend[peakIndex].toStringAsFixed(0)}.',
        ));
      }
    }
    if (summary.totalIncome > 0) {
      final savings = summary.totalIncome - summary.totalExpense;
      final ratio = summary.totalExpense == 0
          ? 'No expenses yet'
          : '${(summary.totalIncome / summary.totalExpense).toStringAsFixed(2)}x';
      insights.add(AnalyticsInsight(
        title: savings >= 0 ? 'Positive cash flow' : 'Spending above income',
        body: savings >= 0
            ? 'You saved ${savings.toStringAsFixed(0)} vs income this month.'
            : 'Expenses exceed income by ${(-savings).toStringAsFixed(0)}.',
      ));
      insights.add(AnalyticsInsight(
        title: 'Income vs expense ratio',
        body: ratio,
      ));
    }
    return insights;
  }
}
