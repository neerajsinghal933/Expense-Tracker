import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulse_money/data/db/app_database.dart';
import 'package:pulse_money/data/repositories/merchant_rule_repository.dart';
import 'package:pulse_money/data/repositories/transaction_repository.dart';
import 'package:pulse_money/domain/constants/category_constants.dart';
import 'package:pulse_money/services/categorization/categorization_service.dart';
import 'package:pulse_money/services/parser/parser_service.dart';
import 'package:pulse_money/services/transaction_ingest_service.dart';

void main() {
  late AppDatabase db;
  late TransactionIngestService ingest;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    ingest = TransactionIngestService(
      parser: ParserService(),
      transactions: TransactionRepository(db),
      categorization: CategorizationService(MerchantRuleRepository(db)),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('inserts parsed SMS with category', () async {
    final result = await ingest.ingestSms(
      smsId: 'sms-test-1',
      sender: 'HDFCBK',
      body: 'Rs. 500 debited at Amazon Pay',
      timestampMs: DateTime(2026, 5, 6).millisecondsSinceEpoch,
    );

    expect(result.status, IngestStatus.inserted);

    final rows = await TransactionRepository(db).getAll();
    expect(rows.length, 1);
    expect(rows.first.sourceSmsId, 'sms-test-1');
    expect(rows.first.amount, 500);
    expect(rows.first.categoryId, CategoryIds.shopping);
  });

  test('skips duplicate sourceSmsId', () async {
    await ingest.ingestSms(
      smsId: 'dup-1',
      sender: 'BANK',
      body: 'Rs. 100 debited',
      timestampMs: 1,
    );
    final second = await ingest.ingestSms(
      smsId: 'dup-1',
      sender: 'BANK',
      body: 'Rs. 200 debited',
      timestampMs: 2,
    );

    expect(second.status, IngestStatus.duplicate);
    final rows = await TransactionRepository(db).getAll();
    expect(rows.length, 1);
    expect(rows.first.amount, 100);
  });
}
