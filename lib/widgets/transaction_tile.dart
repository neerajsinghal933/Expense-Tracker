import 'package:flutter/material.dart';

class TransactionTile extends StatelessWidget {
  final String merchant;
  final String category;
  final String amount;
  final String date;
  final String type;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.merchant,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = type.toLowerCase() == 'credit';
    final amountColor = isCredit ? Colors.green : Colors.red;
    final arrowIcon = isCredit ? Icons.arrow_upward : Icons.arrow_downward;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: amountColor.withOpacity(0.1),
        child: Text(
          merchant.isNotEmpty ? merchant[0].toUpperCase() : '?',
          style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(merchant),
      subtitle: Text(category),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(arrowIcon, color: amountColor, size: 16),
          const SizedBox(width: 4),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
              Text(date, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
