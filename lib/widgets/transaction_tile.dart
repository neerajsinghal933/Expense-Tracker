import 'package:flutter/material.dart';

class TransactionTile extends StatelessWidget {
  final String merchant;
  final String category;
  final String amount;
  final String date;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.merchant,
    required this.category,
    required this.amount,
    required this.date,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        child: Text(merchant.isNotEmpty ? merchant[0].toUpperCase() : '?'),
      ),
      title: Text(merchant),
      subtitle: Text(category),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(date, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
