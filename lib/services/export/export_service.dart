import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/constants/category_constants.dart';

class ExportService {
  ExportService({
    required TransactionRepository transactions,
    required CategoryRepository categories,
  })  : _transactions = transactions,
        _categories = categories;

  final TransactionRepository _transactions;
  final CategoryRepository _categories;

  Future<String> exportAllTimeReport() async {
    final txs = await _transactions.getAll();
    txs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final catMap = await _categories.getMap();
    var totalExpense = 0.0;
    var totalIncome = 0.0;
    final expenseByCategory = <String, double>{};
    final incomeByCategory = <String, double>{};

    for (final t in txs) {
      if (t.type == 'failed' || t.amount <= 0) continue;

      final catId = t.categoryId ?? CategoryIds.other;
      if (t.type == 'credit' || t.type == 'refund') {
        totalIncome += t.amount;
        incomeByCategory[catId] = (incomeByCategory[catId] ?? 0) + t.amount;
      } else {
        totalExpense += t.amount;
        expenseByCategory[catId] = (expenseByCategory[catId] ?? 0) + t.amount;
      }
    }

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
    for (final t in txs) {
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
      TextCellValue('Period'),
      TextCellValue('All time'),
    ]);
    summarySheet.appendRow([
      TextCellValue('Transactions exported'),
      IntCellValue(txs.length),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total expense'),
      DoubleCellValue(totalExpense),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total income'),
      DoubleCellValue(totalIncome),
    ]);
    summarySheet.appendRow([TextCellValue('')]);
    summarySheet.appendRow([
      TextCellValue('Expense categories'),
      TextCellValue('Amount'),
    ]);
    final expenseEntries = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in expenseEntries) {
      summarySheet.appendRow([
        TextCellValue(catMap[entry.key]?.name ?? entry.key),
        DoubleCellValue(entry.value),
      ]);
    }

    summarySheet.appendRow([TextCellValue('')]);
    summarySheet.appendRow([
      TextCellValue('Income categories'),
      TextCellValue('Amount'),
    ]);
    final incomeEntries = incomeByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in incomeEntries) {
      summarySheet.appendRow([
        TextCellValue(catMap[entry.key]?.name ?? entry.key),
        DoubleCellValue(entry.value),
      ]);
    }

    try {
      final dynamic encoded = excel.encode();
      if (encoded == null) {
        throw Exception('Failed to encode Excel file (null)');
      }

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
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'expense_report_all_time_$stamp.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e, st) {
      // Provide a clearer error and include stack trace for debugging.
      throw Exception('Export failed: $e\n$st');
    }
  }

  Future<void> shareReport({int? year, int? month}) async {
    final path = await exportAllTimeReport();
    await Share.shareXFiles([XFile(path)], text: 'Pulse Money all-time report');
  }
}
