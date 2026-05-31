import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulse_money/data/db/app_database.dart';
import 'package:pulse_money/data/repositories/transaction_repository.dart';
import 'package:pulse_money/domain/constants/category_constants.dart';
import 'package:pulse_money/services/analytics/analytics_service.dart';
import 'package:pulse_money/services/app_bootstrap_service.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository transactions;
  late AnalyticsService analytics;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await AppBootstrapService(db).ensureInitialized();
    transactions = TransactionRepository(db);
    analytics = AnalyticsService(transactions: transactions, db: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('monthly summary reflects deleted transactions', () async {
    final timestamp = DateTime(2026, 5, 24).millisecondsSinceEpoch;

    await transactions.insertTransaction(
      TransactionsCompanion.insert(
        id: 'tx-delete-refresh',
        rawText: 'Sent Rs.100.00 To ROLLS MANIA',
        amount: 100,
        type: 'debit',
        timestamp: timestamp,
        sourceSmsId: const Value('sms-delete-refresh'),
        categoryId: const Value(CategoryIds.food),
      ),
    );

    final beforeDelete = await analytics.monthlySummary(2026, 5);
    expect(beforeDelete.totalExpense, 100);
    expect(beforeDelete.byCategoryExpense.single.categoryId, CategoryIds.food);

    await transactions.deleteTransaction('tx-delete-refresh');

    final afterDelete = await analytics.monthlySummary(2026, 5);
    expect(afterDelete.totalExpense, 0);
    expect(afterDelete.byCategoryExpense, isEmpty);
  });
}
