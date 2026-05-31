import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get sourceSmsId => text().nullable()();
  TextColumn get rawText => text()();
  RealColumn get amount => real()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get type => text()();
  IntColumn get timestamp => integer()();
  TextColumn get merchantId => text().nullable()();
  TextColumn get merchantName => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get paymentMethod => text().nullable()();
  RealColumn get balance => real().nullable()();
  TextColumn get reference => text().nullable()();
  RealColumn get confidence => real().withDefault(const Constant(0.0))();
  TextColumn get parsedBy => text().withDefault(const Constant('manual'))();
  IntColumn get createdAt =>
      integer().clientDefault(() => DateTime.now().millisecondsSinceEpoch)();
  IntColumn get updatedAt =>
      integer().clientDefault(() => DateTime.now().millisecondsSinceEpoch)();
  BoolColumn get isDuplicate => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class MerchantRules extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get pattern => text().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get categoryId => text().nullable()();
  BoolColumn get autoApply => boolean().withDefault(const Constant(false))();
  IntColumn get usageCount => integer().withDefault(const Constant(0))();
  BoolColumn get isUserDefined =>
      boolean().withDefault(const Constant(false))();
  IntColumn get createdAt =>
      integer().clientDefault(() => DateTime.now().millisecondsSinceEpoch)();
  IntColumn get updatedAt =>
      integer().clientDefault(() => DateTime.now().millisecondsSinceEpoch)();

  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  IntColumn get createdAt =>
      integer().clientDefault(() => DateTime.now().millisecondsSinceEpoch)();
  IntColumn get updatedAt =>
      integer().clientDefault(() => DateTime.now().millisecondsSinceEpoch)();

  @override
  Set<Column> get primaryKey => {id};
}

class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  TextColumn get period => text()();
  RealColumn get amount => real()();
  IntColumn get createdAt =>
      integer().clientDefault(() => DateTime.now().millisecondsSinceEpoch)();
  IntColumn get updatedAt =>
      integer().clientDefault(() => DateTime.now().millisecondsSinceEpoch)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserProfileRow')
class Profiles extends Table {
  @override
  String get tableName => 'user_profile';

  TextColumn get id => text()();
  TextColumn get fullName => text()();
  TextColumn get username => text()();
  TextColumn get preferredCurrency =>
      text().withDefault(const Constant('INR'))();
  RealColumn get monthlyIncome => real().nullable()();
  TextColumn get avatarPath => text().nullable()();
  IntColumn get createdAt =>
      integer().clientDefault(() => DateTime.now().millisecondsSinceEpoch)();
  IntColumn get updatedAt =>
      integer().clientDefault(() => DateTime.now().millisecondsSinceEpoch)();

  @override
  Set<Column> get primaryKey => {id};
}

class AnalyticsCache extends Table {
  @override
  String get tableName => 'analytics_cache';

  TextColumn get id => text()();
  TextColumn get cacheKey => text()();
  TextColumn get payload => text()();
  IntColumn get updatedAt =>
      integer().clientDefault(() => DateTime.now().millisecondsSinceEpoch)();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Transactions,
  MerchantRules,
  Categories,
  Budgets,
  Profiles,
  AnalyticsCache,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'expense_tracker.sqlite'));
      return NativeDatabase(file);
    });
  }

  static Future<AppDatabase> open() async => AppDatabase();

  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());
}
