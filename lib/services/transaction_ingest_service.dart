import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../data/db/app_database.dart';
import '../data/repositories/transaction_repository.dart';
import '../domain/constants/category_constants.dart';
import 'categorization/categorization_service.dart';
import 'parser/parsed_transaction.dart';
import 'parser/parser_service.dart';

enum IngestStatus { inserted, duplicate, ignored }

class IngestResult {
  final IngestStatus status;
  final String transactionId;
  final bool needsCategory;

  const IngestResult({
    required this.status,
    required this.transactionId,
    this.needsCategory = false,
  });
}

class TransactionIngestService {
  TransactionIngestService({
    required ParserService parser,
    required TransactionRepository transactions,
    required CategorizationService categorization,
    Uuid? uuid,
  })  : _parser = parser,
        _transactions = transactions,
        _categorization = categorization,
        _uuid = uuid ?? const Uuid();

  final ParserService _parser;
  final TransactionRepository _transactions;
  final CategorizationService _categorization;
  final Uuid _uuid;

  Future<IngestResult> ingestSms({
    required String smsId,
    required String sender,
    required String body,
    required int timestampMs,
  }) async {
    final existing = await _transactions.findBySourceSmsId(smsId);
    if (existing != null) {
      return IngestResult(
        status: IngestStatus.duplicate,
        transactionId: existing.id,
      );
    }

    final parsed = await _parser.parseSms(
      smsId: smsId,
      sender: sender,
      body: body,
      timestampMs: timestampMs,
    );

    // Heuristic: skip non-transactional messages. If there's no amount, low
    // confidence, or type is unknown, treat as not a transaction and ignore.
    final isProbablyTransaction = parsed.amount > 0 &&
        parsed.type != TransactionType.unknown &&
        parsed.confidence >= 0.25;

    if (!isProbablyTransaction) {
      return IngestResult(
        status: IngestStatus.ignored,
        transactionId: '',
        needsCategory: false,
      );
    }

    final category = await _categorization.categorize(parsed);
    final transactionId = _uuid.v4();

    await _transactions.insertTransaction(
      _toCompanion(
        transactionId: transactionId,
        smsId: smsId,
        parsed: parsed,
        categoryId: category.categoryId,
      ),
    );

    return IngestResult(
      status: IngestStatus.inserted,
      transactionId: transactionId,
      needsCategory: category.categoryId == CategoryIds.uncategorized,
    );
  }

  TransactionsCompanion _toCompanion({
    required String transactionId,
    required String smsId,
    required ParsedTransaction parsed,
    required String categoryId,
  }) {
    return TransactionsCompanion.insert(
      id: transactionId,
      sourceSmsId: Value(smsId),
      rawText: parsed.rawText,
      amount: parsed.amount,
      currency: Value(parsed.currency),
      type: parsed.type.name,
      timestamp: parsed.timestamp.millisecondsSinceEpoch,
      merchantName: Value(parsed.merchantName),
      categoryId: Value(categoryId),
      paymentMethod: Value(parsed.paymentMethod),
      balance: Value(parsed.balance),
      reference: Value(parsed.reference),
      confidence: Value(parsed.confidence),
      parsedBy: Value(parsed.parsedBy),
      isDuplicate: const Value(false),
    );
  }
}
