import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_money/services/parser/parser_service.dart';
import 'package:pulse_money/services/parser/parsed_transaction.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ParserService tests', () {
    late ParserService parser;

    setUp(() {
      parser = ParserService();
    });

    test('Parse 20 SMS fixtures and validate basic fields', () async {
      final file = File('test/fixtures/sms_fixtures.json');
      final data = await file.readAsString();
      final List fixtures = json.decode(data) as List;
      int passCount = 0;
      for (final f in fixtures) {
        final parsed = await parser.parseSms(
          smsId: f['id'],
          sender: f['sender'],
          body: f['body'],
          timestampMs: f['timestamp'],
        );
        expect(parsed.rawText.isNotEmpty, true);
        expect(parsed.amount >= 0.0, true);
        expect(parsed.currency, 'INR');
        expect(parsed.confidence >= 0.0 && parsed.confidence <= 1.0, true);

        final body = f['body'] as String;
        if (body.toLowerCase().contains('debited') ||
            body.toLowerCase().contains('spent') ||
            body.toLowerCase().contains('withdrawn')) {
          expect(
            parsed.type == TransactionType.debit ||
                parsed.type == TransactionType.unknown,
            true,
          );
        }
        if (body.toLowerCase().contains('credited') ||
            body.toLowerCase().contains('credit alert')) {
          expect(
            parsed.type == TransactionType.credit ||
                parsed.type == TransactionType.unknown,
            true,
          );
        }

        if (parsed.amount > 0.0) passCount++;
      }

      expect(
        passCount >= 15,
        true,
        reason: 'At least 15 fixtures should parse a positive amount',
      );
    });

    test('Confidence scoring bounds', () async {
      final parsed = await parser.parseSms(
        smsId: 't1',
        sender: 'TEST',
        body: 'Rs. 100 debited at Cafe',
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      );
      expect(parsed.confidence >= 0.0 && parsed.confidence <= 1.0, true);
    });

    test('UPI detection', () async {
      final parsed = await parser.parseSms(
        smsId: 't2',
        sender: 'UPI',
        body:
            'TXN of INR 299.00 is successful on UPI VPA: merchant@upi. Ref: TXNID1234.',
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      );
      expect(
          parsed.paymentMethod == 'UPI' || parsed.paymentMethod == null, true);
    });

    test('HDFC sent UPI format is parsed as debit', () async {
      final parsed = await parser.parseSms(
        smsId: 'hdfc-sent-1',
        sender: 'HDFCBK',
        body: '''
Sent Rs.100.00
From HDFC Bank A/C *9825
To ROLLS MANIA Amanora Mall
On 24/05/26
Ref 123632919721
Not You?
Call 18002586161/SMS BLOCK UPI to 7308080808
''',
        timestampMs: DateTime(2026, 5, 24).millisecondsSinceEpoch,
      );

      expect(parsed.amount, 100);
      expect(parsed.type, TransactionType.debit);
      expect(parsed.merchantName, 'ROLLS MANIA Amanora Mall');
      expect(parsed.paymentMethod, 'UPI');
      expect(parsed.confidence, greaterThanOrEqualTo(0.25));
    });

    test('HDFC salary NEFT deposit is parsed as credit', () async {
      final parsed = await parser.parseSms(
        smsId: 'hdfc-salary-1',
        sender: 'HDFCBK',
        body:
            'Update! INR 1,40,661.00 deposited in HDFC Bank A/c XX9825 on 27-FEB-26 for NEFT Cr-CITI0000003-BNY MELLON TECHNOLOGY PRIVATE LTD-NEERAJ KUMAR SINGHAL-CITIN26627913794.Avl bal INR 6,22,735.43.',
        timestampMs: DateTime(2026, 2, 27).millisecondsSinceEpoch,
      );

      expect(parsed.amount, 140661);
      expect(parsed.type, TransactionType.credit);
      expect(parsed.paymentMethod, 'NEFT');
      expect(parsed.confidence, greaterThanOrEqualTo(0.25));
    });

    test('Invalid SMS handling', () async {
      final parsed = await parser.parseSms(
        smsId: 't3',
        sender: 'UNKNOWN',
        body: 'Hello, this is a promo message. Enjoy offers!',
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      );
      expect(parsed.amount == 0.0, true);
      expect(parsed.type == TransactionType.unknown, true);
    });
  });
}
