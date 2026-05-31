import '../../data/db/app_database.dart';

String formatTransactionDate(int timestampMs) {
  final d = DateTime.fromMillisecondsSinceEpoch(timestampMs);
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day} ${months[d.month - 1]}';
}

String formatAmount(Transaction tx, {String? currencyOverride}) {
  final currency = currencyOverride ?? tx.currency;
  final prefix = tx.type == 'credit' ? '+' : '';
  return '$prefix$currency ${tx.amount.toStringAsFixed(2)}';
}

String transactionTitle(Transaction tx) {
  if (tx.merchantName != null && tx.merchantName!.trim().isNotEmpty) {
    return tx.merchantName!.trim();
  }
  return tx.type.toUpperCase();
}

String transactionSubtitle(Transaction tx) {
  final parts = <String>[
    tx.type,
    if (tx.paymentMethod != null) tx.paymentMethod!,
  ];
  return parts.join(' · ');
}
