import '../db/app_database.dart';

class CategoryRepository {
  CategoryRepository(this.db);

  final AppDatabase db;

  Future<List<Category>> getAll() => db.select(db.categories).get();

  Stream<List<Category>> watchAll() => db.select(db.categories).watch();

  Future<Category?> getById(String id) {
    return (db.select(db.categories)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  Future<Map<String, Category>> getMap() async {
    final list = await getAll();
    return {for (final c in list) c.id: c};
  }
}
