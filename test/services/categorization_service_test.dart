import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulse_money/data/db/app_database.dart';
import 'package:pulse_money/data/repositories/merchant_rule_repository.dart';
import 'package:pulse_money/domain/constants/category_constants.dart';
import 'package:pulse_money/services/categorization/categorization_service.dart';
import 'package:pulse_money/services/parser/parsed_transaction.dart';

void main() {
  late AppDatabase db;
  late CategorizationService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = CategorizationService(MerchantRuleRepository(db));
  });

  tearDown(() async {
    await db.close();
  });

  test('keyword maps amazon to shopping', () async {
    final match = await service.categorize(_parsed(
      merchantName: 'AMAZON PAY',
      body: 'Rs 500 debited at AMAZON PAY',
    ));
    expect(match.categoryId, CategoryIds.shopping);
    expect(match.source, 'keyword');
  });

  test('keyword maps rolls mania to food', () async {
    final match = await service.categorize(_parsed(
      merchantName: 'ROLLS MANIA Amanora Mall',
      body: 'Sent Rs.100.00 To ROLLS MANIA Amanora Mall',
    ));
    expect(match.categoryId, CategoryIds.food);
    expect(match.source, 'keyword');
  });

  test('keyword maps grocery and shopping merchants', () async {
    final dmart = await service.categorize(_parsed(
      merchantName: 'D Mart',
      body: 'Rs 1200 paid to D Mart',
    ));
    final flipkart = await service.categorize(_parsed(
      merchantName: 'Flipkart',
      body: 'Rs 899 spent at Flipkart',
    ));

    expect(dmart.categoryId, CategoryIds.shopping);
    expect(flipkart.categoryId, CategoryIds.shopping);
  });

  test('learned merchant rule takes priority', () async {
    await MerchantRuleRepository(db).learnCategory(
      merchantName: 'LocalStore',
      categoryId: CategoryIds.food,
    );
    final match = await service.categorize(_parsed(
      merchantName: 'LocalStore',
      body: 'paid to LocalStore',
    ));
    expect(match.categoryId, CategoryIds.food);
    expect(match.source, 'learned');
  });

  test('low confidence returns uncategorized', () async {
    final match = await service.categorize(_parsed(
      body: 'promo offer valid today',
      confidence: 0.1,
    ));
    expect(match.categoryId, CategoryIds.uncategorized);
  });

  test('salary-like NEFT credit maps to salary income', () async {
    final match = await service.categorize(_parsed(
      body:
          'INR 1,40,661.00 deposited for NEFT Cr-CITI0000003-BNY MELLON TECHNOLOGY PRIVATE LTD',
      type: TransactionType.credit,
    ));

    expect(match.categoryId, CategoryIds.salary);
    expect(match.source, 'type');
  });
}

ParsedTransaction _parsed({
  String merchantName = '',
  String body = '',
  double confidence = 0.8,
  TransactionType type = TransactionType.debit,
}) {
  return ParsedTransaction(
    id: 'x',
    rawText: body,
    amount: 100,
    currency: 'INR',
    type: type,
    timestamp: DateTime.now(),
    merchantName: merchantName.isEmpty ? null : merchantName,
    confidence: confidence,
    parsedBy: 'test',
  );
}
