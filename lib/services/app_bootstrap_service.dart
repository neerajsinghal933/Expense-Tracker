import 'package:drift/drift.dart';

import '../data/db/app_database.dart';
import '../domain/constants/category_constants.dart';

class AppBootstrapService {
  AppBootstrapService(this._db);

  final AppDatabase _db;

  Future<void> ensureInitialized() async {
    await _seedCategoriesIfEmpty();
  }

  Future<void> _seedCategoriesIfEmpty() async {
    final existing = await _db.select(_db.categories).get();
    final existingIds = existing.map((c) => c.id).toSet();

    for (final entry in DefaultCategories.entries) {
      if (existingIds.contains(entry.$1)) continue;
      await _db.into(_db.categories).insert(
            CategoriesCompanion.insert(
              id: entry.$1,
              name: entry.$2,
              colorHex: Value(entry.$3),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }
}
