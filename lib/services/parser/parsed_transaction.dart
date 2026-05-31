import 'package:meta/meta.dart';

enum TransactionType {
  debit,
  credit,
  refund,
  emi,
  atm_withdrawal,
  failed,
  unknown
}

@immutable
class ParsedTransaction {
  final String id;
  final String rawText;
  final double amount;
  final String currency;
  final TransactionType type;
  final DateTime timestamp;
  final String? merchantName;
  final String? paymentMethod;
  final String? reference;
  final double? balance;
  final double confidence;
  final String parsedBy;

  const ParsedTransaction({
    required this.id,
    required this.rawText,
    required this.amount,
    required this.currency,
    required this.type,
    required this.timestamp,
    this.merchantName,
    this.paymentMethod,
    this.reference,
    this.balance,
    required this.confidence,
    required this.parsedBy,
  });
}
