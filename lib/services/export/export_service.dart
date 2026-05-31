import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../services/analytics/analytics_service.dart';

class ExportService {
  ExportService({
    required TransactionRepository transactions,
    required CategoryRepository categories,
    required AnalyticsService analytics,
  })  : _transactions = transactions,
        _categories = categories,
        _analytics = analytics;

  final TransactionRepository _transactions;
  final CategoryRepository _categories;
  final AnalyticsService _analytics;

  Future<String> exportMonthlyReport({int? year, int? month}) async {
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;
    final summary = await _analytics.monthlySummary(y, m);
    final txs = await _transactions.getAll();
    final start = DateTime(y, m).millisecondsSinceEpoch;
    final end = DateTime(y, m + 1).millisecondsSinceEpoch;
    final monthTxs =
        txs.where((t) => t.timestamp >= start && t.timestamp < end).toList();
    final catMap = await _categories.getMap();

    final excel = Excel.createExcel();
    final txSheet = excel['Transactions'];
    final summarySheet = excel['Summary'];

    txSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Merchant'),
      TextCellValue('Category'),
      TextCellValue('Type'),
      TextCellValue('Amount'),
      TextCellValue('Currency'),
      TextCellValue('Payment'),
    ]);

    final dateFmt = DateFormat('dd-MMM-yyyy');
    for (final t in monthTxs) {
      final cat = catMap[t.categoryId ?? '']?.name ?? 'Uncategorized';
      txSheet.appendRow([
        TextCellValue(
          dateFmt.format(
            DateTime.fromMillisecondsSinceEpoch(t.timestamp),
          ),
        ),
        TextCellValue(t.merchantName ?? ''),
        TextCellValue(cat),
        TextCellValue(t.type),
        DoubleCellValue(t.amount),
        TextCellValue(t.currency),
        TextCellValue(t.paymentMethod ?? ''),
      ]);
    }

    summarySheet.appendRow([
      TextCellValue('Expense Tracker Report'),
    ]);
    summarySheet.appendRow([
      TextCellValue('Month'),
      TextCellValue(DateFormat('MMMM yyyy').format(DateTime(y, m))),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total expense'),
      DoubleCellValue(summary.totalExpense),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total income'),
      DoubleCellValue(summary.totalIncome),
    ]);
    summarySheet.appendRow([TextCellValue('')]);
    summarySheet.appendRow([
      TextCellValue('Expense categories'),
      TextCellValue('Amount'),
    ]);
    for (final c in summary.byCategoryExpense) {
      summarySheet.appendRow([
        TextCellValue(c.categoryName),
        DoubleCellValue(c.amount),
      ]);
    }

    summarySheet.appendRow([TextCellValue('')]);
    summarySheet.appendRow([
      TextCellValue('Income categories'),
      TextCellValue('Amount'),
    ]);
    for (final c in summary.byCategoryIncome) {
      summarySheet.appendRow([
        TextCellValue(c.categoryName),
        DoubleCellValue(c.amount),
      ]);
    }

    try {
      final dynamic encoded = excel.encode();
      if (encoded == null)
        throw Exception('Failed to encode Excel file (null)');

      List<int> bytes;
      if (encoded is List<int>) {
        bytes = encoded;
      } else if (encoded is Map) {
        // Some versions of the excel package may return a Map when multiple
        // byte streams are produced. Instead of failing when there are
        // multiple entries (which caused "Bad state: Too many elements"),
        // choose the largest byte stream as a pragmatic fallback.
        List<List<int>> streams = [];
        for (final v in encoded.values) {
          if (v is List<int>) streams.add(v);
        }
        if (streams.isEmpty) {
          throw Exception(
              'Failed to encode Excel file: no byte streams found in encoded Map');
        }
        // Pick the largest stream (most likely the full workbook)
        streams.sort((a, b) => b.length.compareTo(a.length));
        bytes = streams.first;
      } else {
        throw Exception(
            'Failed to encode Excel file: unexpected encoder return type: ${encoded.runtimeType}');
      }

      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'expense_report_${y}_${m.toString().padLeft(2, '0')}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e, st) {
      // Provide a clearer error and include stack trace for debugging.
      throw Exception('Export failed: $e\n$st');
    }
  }

  Future<void> shareReport({int? year, int? month}) async {
    final path = await exportMonthlyReport(year: year, month: month);
    await Share.shareXFiles([XFile(path)], text: 'Expense Tracker report');
  }
}
