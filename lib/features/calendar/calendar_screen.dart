import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/providers/app_providers.dart';
import '../../core/utils/format_utils.dart';
import '../../widgets/transaction_tile.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final currency = profile?.preferredCurrency ?? 'INR';

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focused,
            selectedDayPredicate: (day) => isSameDay(_selected, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selected = selected;
                _focused = focused;
              });
            },
            onPageChanged: (focused) => _focused = focused,
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
            ),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder(
              future: ref.read(transactionRepositoryProvider).forDay(_selected),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final txs = snapshot.data!;
                if (txs.isEmpty) {
                  return const Center(child: Text('No transactions this day'));
                }
                return ListView.builder(
                  itemCount: txs.length,
                  itemBuilder: (context, index) {
                    final tx = txs[index];
                    return TransactionTile(
                      merchant: transactionTitle(tx),
                      category: transactionSubtitle(tx),
                      amount: formatAmount(tx, currencyOverride: currency),
                      date: formatTransactionDate(tx.timestamp),
                      type: tx.type,
                      onTap: () => context.push('/transactions/${tx.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
