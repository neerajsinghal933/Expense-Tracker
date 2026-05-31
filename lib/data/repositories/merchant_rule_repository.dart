import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../../services/parser/merchant_utils.dart';

class MerchantRuleRepository {
  MerchantRuleRepository(this.db);

  final AppDatabase db;
  final _uuid = const Uuid();

  Future<List<MerchantRule>> getAllOrdered() {
    return (db.select(db.merchantRules)
          ..orderBy([
            (r) => OrderingTerm.desc(r.priority),
            (r) => OrderingTerm.desc(r.usageCount),
          ]))
        .get();
  }

  Future<void> learnCategory({
    required String merchantName,
    required String categoryId,
  }) async {
    final normalized = normalizeMerchantName(merchantName);
    if (normalized.isEmpty) return;

    final existing = await (db.select(db.merchantRules)
          ..where((r) => r.pattern.equals(normalized)))
        .getSingleOrNull();

    if (existing != null) {
      await (db.update(db.merchantRules)
            ..where((r) => r.id.equals(existing.id)))
          .write(
        MerchantRulesCompanion(
          categoryId: Value(categoryId),
          usageCount: Value(existing.usageCount + 1),
          isUserDefined: const Value(true),
          autoApply: const Value(true),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
      return;
    }

    await db.into(db.merchantRules).insert(
          MerchantRulesCompanion.insert(
            id: _uuid.v4(),
            name: merchantName,
            pattern: Value(normalized),
            categoryId: Value(categoryId),
            priority: const Value(100),
            autoApply: const Value(true),
            isUserDefined: const Value(true),
            usageCount: const Value(1),
          ),
        );
  }
}
