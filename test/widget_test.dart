import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_money/core/app.dart';
import 'package:pulse_money/core/providers/app_providers.dart';
import 'package:pulse_money/data/db/app_database.dart';

void main() {
  testWidgets('ExpenseApp shows onboarding when no profile', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            final db = AppDatabase.memory();
            ref.onDispose(db.close);
            return db;
          }),
          userProfileProvider.overrideWith((ref) async => null),
          transactionsStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const ExpenseApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Pulse Money'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
  });
}
