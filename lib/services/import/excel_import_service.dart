import 'dart:io';

import 'package:drift/drift.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/constants/category_constants.dart';

class ImportPreview {
  const ImportPreview({
    required this.filePath,
    required this.rows,
    required this.errors,
  });

  final String filePath;
  final List<ImportRow> rows;
  final List<String> errors;

  int get validCount => rows.where((r) => r.isValid && !r.isDuplicate).length;
  int get duplicateCount => rows.where((r) => r.isDuplicate).length;
}

class ImportRow {
  const ImportRow({
    required this.rowNumber,
    required this.amount,
    required this.type,
    required this.timestamp,
    required this.merchantName,
    required this.categoryId,
    required this.categoryName,
    required this.currency,
    required this.paymentMethod,
    required this.note,
    required this.errors,
    required this.warnings,
    required this.isDuplicate,
  });

  final int rowNumber;
  final double amount;
  final String type;
  final int timestamp;
  final String merchantName;
  final String? categoryId;
  final String categoryName;
  final String currency;
  final String? paymentMethod;
  final String note;
  final List<String> errors;
  final List<String> warnings;
  final bool isDuplicate;

  bool get isValid => errors.isEmpty && amount > 0;
}

class ImportCommitResult {
  const ImportCommitResult({required this.inserted, required this.skipped});

  final int inserted;
  final int skipped;
}

class ExcelImportService {
  ExcelImportService({
    required TransactionRepository transactions,
    required CategoryRepository categories,
    Uuid? uuid,
  })  : _transactions = transactions,
        _categories = categories,
        _uuid = uuid ?? const Uuid();

  final TransactionRepository _transactions;
  final CategoryRepository _categories;
  final Uuid _uuid;

  Future<ImportPreview> preview(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return ImportPreview(
        filePath: path,
        rows: const [],
        errors: const ['Selected file was not found.'],
      );
    }

    final bytes = await file.readAsBytes();
    final workbook = Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) {
      return ImportPreview(
        filePath: path,
        rows: const [],
        errors: const ['Workbook has no readable sheets.'],
      );
    }

    final sheet =
        workbook.tables['Transactions'] ?? workbook.tables.values.first;
    if (sheet.rows.isEmpty) {
      return ImportPreview(
        filePath: path,
        rows: const [],
        errors: const ['No transaction rows were found.'],
      );
    }

    final header = sheet.rows.first.map(_cellText).toList();
    final columns = _mapColumns(header);
    final required = ['date', 'type', 'amount'];
    final missing =
        required.where((name) => !columns.containsKey(name)).toList();
    if (missing.isNotEmpty) {
      return ImportPreview(
        filePath: path,
        rows: const [],
        errors: ['Missing required column(s): ${missing.join(', ')}.'],
      );
    }

    final existing = await _transactions.getAll();
    final categories = await _categories.getAll();
    final categoryByName = {
      for (final c in categories) c.name.trim().toLowerCase(): c,
    };
    final rows = <ImportRow>[];
    final seenKeys = <String>{};

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.every((cell) => _cellText(cell).trim().isEmpty)) continue;

      final errors = <String>[];
      final warnings = <String>[];
      final amount = _parseAmount(_value(row, columns, 'amount'));
      if (amount == null || amount <= 0) errors.add('Invalid amount');

      final timestamp = _parseDate(_value(row, columns, 'date'));
      if (timestamp == null) errors.add('Invalid date');

      final type = _normalizeType(_value(row, columns, 'type'));
      if (type == null) errors.add('Invalid type');

      final categoryLabel = _value(row, columns, 'category');
      var category = categoryByName[categoryLabel.trim().toLowerCase()];
      if (category == null && categoryLabel.trim().isNotEmpty) {
        warnings.add('Unknown category mapped to Other');
      }
      category ??= categoryByName['other'];

      final merchant = _value(row, columns, 'merchant').trim();
      final payment = _value(row, columns, 'payment').trim();
      final note = _value(row, columns, 'note').trim();
      final currency = _value(row, columns, 'currency').trim().isEmpty
          ? 'INR'
          : _value(row, columns, 'currency').trim().toUpperCase();
      final safeTimestamp = timestamp ?? 0;
      final safeAmount = amount ?? 0;
      final safeType = type ?? 'debit';
      final duplicate = _isDuplicate(
            existing,
            amount: safeAmount,
            type: safeType,
            timestamp: safeTimestamp,
            merchant: merchant,
          ) ||
          !seenKeys.add(
              _duplicateKey(safeAmount, safeType, safeTimestamp, merchant));

      rows.add(
        ImportRow(
          rowNumber: i + 1,
          amount: safeAmount,
          type: safeType,
          timestamp: safeTimestamp,
          merchantName: merchant,
          categoryId: category?.id ?? CategoryIds.other,
          categoryName: category?.name ?? 'Other',
          currency: currency,
          paymentMethod: payment.isEmpty ? null : payment,
          note: note,
          errors: errors,
          warnings: warnings,
          isDuplicate: duplicate,
        ),
      );
    }

    return ImportPreview(filePath: path, rows: rows, errors: const []);
  }

  Future<ImportCommitResult> commit(
    ImportPreview preview, {
    bool includeDuplicates = false,
  }) async {
    var inserted = 0;
    var skipped = 0;
    for (final row in preview.rows) {
      if (!row.isValid || (row.isDuplicate && !includeDuplicates)) {
        skipped++;
        continue;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      await _transactions.insertTransaction(
        TransactionsCompanion.insert(
          id: _uuid.v4(),
          rawText:
              row.note.isEmpty ? 'Excel import: ${row.merchantName}' : row.note,
          amount: row.amount,
          currency: Value(row.currency),
          type: row.type,
          timestamp: row.timestamp,
          merchantName:
              Value(row.merchantName.isEmpty ? null : row.merchantName),
          categoryId: Value(row.categoryId),
          paymentMethod: Value(row.paymentMethod),
          confidence: const Value(1),
          parsedBy: const Value('excel_import'),
          isDuplicate: Value(row.isDuplicate),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      inserted++;
    }
    return ImportCommitResult(inserted: inserted, skipped: skipped);
  }

  static Map<String, int> _mapColumns(List<String> header) {
    final aliases = <String, List<String>>{
      'date': ['date', 'timestamp', 'transaction date'],
      'merchant': ['merchant', 'description', 'name', 'payee'],
      'category': ['category'],
      'type': ['type', 'transaction type'],
      'amount': ['amount', 'value'],
      'currency': ['currency'],
      'payment': ['payment', 'payment method', 'method'],
      'note': ['note', 'notes', 'raw sms', 'raw text', 'description'],
    };
    final mapped = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      final normalized = header[i].trim().toLowerCase();
      for (final entry in aliases.entries) {
        if (entry.value.contains(normalized)) mapped[entry.key] = i;
      }
    }
    return mapped;
  }

  static String _value(List<Data?> row, Map<String, int> columns, String key) {
    final index = columns[key];
    if (index == null || index >= row.length) return '';
    return _cellText(row[index]);
  }

  static String _cellText(Data? cell) {
    final value = cell?.value;
    if (value == null) return '';
    if (value is TextCellValue) return value.value.text ?? '';
    if (value is DateCellValue) {
      return DateFormat('dd-MMM-yyyy').format(value.asDateTimeLocal());
    }
    return value.toString();
  }

  static double? _parseAmount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9\.\-]'), '');
    return double.tryParse(cleaned);
  }

  static int? _parseDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final formats = [
      'dd-MMM-yyyy',
      'dd MMM yyyy',
      'dd/MM/yyyy',
      'd/M/yyyy',
      'yyyy-MM-dd',
      'MM/dd/yyyy',
      'dd-MM-yyyy',
    ];
    for (final pattern in formats) {
      try {
        return DateFormat(pattern).parseStrict(value).millisecondsSinceEpoch;
      } catch (_) {}
    }
    final parsed = DateTime.tryParse(value);
    return parsed?.millisecondsSinceEpoch;
  }

  static String? _normalizeType(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) return null;
    if (['credit', 'income', 'refund'].contains(value)) {
      return value == 'income' ? 'credit' : value;
    }
    if (['debit', 'expense', 'spent'].contains(value)) return 'debit';
    if (value.contains('emi')) return 'emi';
    if (value.contains('atm')) return 'atm_withdrawal';
    return null;
  }

  static bool _isDuplicate(
    List<Transaction> existing, {
    required double amount,
    required String type,
    required int timestamp,
    required String merchant,
  }) {
    final importedDay = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final merchantKey = merchant.trim().toLowerCase();
    return existing.any((tx) {
      final day = DateTime.fromMillisecondsSinceEpoch(tx.timestamp);
      return tx.amount.toStringAsFixed(2) == amount.toStringAsFixed(2) &&
          tx.type == type &&
          day.year == importedDay.year &&
          day.month == importedDay.month &&
          day.day == importedDay.day &&
          ((tx.merchantName ?? '').trim().toLowerCase() == merchantKey ||
              merchantKey.isEmpty);
    });
  }

  static String _duplicateKey(
    double amount,
    String type,
    int timestamp,
    String merchant,
  ) {
    final day = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${amount.toStringAsFixed(2)}|$type|${day.year}-${day.month}-${day.day}|${merchant.trim().toLowerCase()}';
  }
}
