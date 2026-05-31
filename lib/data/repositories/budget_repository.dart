import 'package:drift/drift.dart';

import '../db/app_database.dart';

class BudgetRepository {
  BudgetRepository(this.db);

  final AppDatabase db;

  Stream<List<Budget>> watchAll() => db.select(db.budgets).watch();

  Future<void> upsert(BudgetsCompanion companion) async {
    await db.into(db.budgets).insertOnConflictUpdate(companion);
  }

  Future<void> delete(String id) async {
    await (db.delete(db.budgets)..where((b) => b.id.equals(id))).go();
  }

  Future<Budget?> forCategory(String categoryId, String period) {
    return (db.select(db.budgets)
          ..where(
            (b) => b.categoryId.equals(categoryId) & b.period.equals(period),
          ))
        .getSingleOrNull();
  }
}
