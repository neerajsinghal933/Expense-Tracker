import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../../domain/constants/category_constants.dart';

class TransactionRepository {
  TransactionRepository(this.db);

  final AppDatabase db;

  Future<void> insertTransaction(TransactionsCompanion companion) async {
    await db.into(db.transactions).insert(companion);
  }

  Future<List<Transaction>> getAll() {
    return (db.select(db.transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .get();
  }

  Stream<List<Transaction>> watchAllTransactions() {
    return (db.select(db.transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .watch();
  }

  Future<Transaction?> findBySourceSmsId(String sourceSmsId) {
    return (db.select(db.transactions)
          ..where((t) => t.sourceSmsId.equals(sourceSmsId)))
        .getSingleOrNull();
  }

  Future<Transaction?> getById(String id) {
    return (db.select(db.transactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<Transaction?> watchById(String id) {
    return (db.select(db.transactions)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<void> updateCategory(String id, String categoryId) async {
    await (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        categoryId: Value(categoryId),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> updateTransaction(TransactionsCompanion companion) async {
    await (db.update(db.transactions)
          ..where((t) => t.id.equals(companion.id.value)))
        .write(
      TransactionsCompanion(
        sourceSmsId: companion.sourceSmsId,
        rawText: companion.rawText,
        amount: companion.amount,
        currency: companion.currency,
        type: companion.type,
        timestamp: companion.timestamp,
        merchantId: companion.merchantId,
        merchantName: companion.merchantName,
        categoryId: companion.categoryId,
        paymentMethod: companion.paymentMethod,
        balance: companion.balance,
        reference: companion.reference,
        confidence: companion.confidence,
        parsedBy: companion.parsedBy,
        createdAt: companion.createdAt,
        updatedAt: companion.updatedAt,
        isDuplicate: companion.isDuplicate,
      ),
    );
  }

  Future<void> deleteTransaction(String id) async {
    await (db.delete(db.transactions)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<Transaction>> watchUncategorized() {
    return (db.select(db.transactions)
          ..where(
            (t) =>
                t.categoryId.equals(CategoryIds.uncategorized) |
                t.categoryId.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .watch();
  }

  Future<List<Transaction>> forDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59, 999)
        .millisecondsSinceEpoch;
    return (db.select(db.transactions)
          ..where((t) => t.timestamp.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .get();
  }
}
