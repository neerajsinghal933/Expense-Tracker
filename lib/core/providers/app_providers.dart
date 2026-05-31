import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/merchant_rule_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/analytics/stats_dashboard_screen.dart';
import '../../features/budgets/budgets_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/privacy_policy_screen.dart';
import '../../features/profile/data_usage_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/transactions/transaction_detail_screen.dart';
import '../../features/transactions/transactions_screen.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/app_bootstrap_service.dart';
import '../../services/categorization/categorization_service.dart';
import '../../services/export/export_service.dart';
import '../../services/import/excel_import_service.dart';
import '../../services/parser/parser_service.dart';
import '../../services/settings/app_settings_service.dart';
import '../../services/sms/sms_service.dart';
import '../../services/transaction_ingest_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final appSettingsControllerProvider =
    ChangeNotifierProvider<AppSettingsController>((ref) {
  return AppSettingsController();
});

final bootstrapProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  await AppBootstrapService(db).ensureInitialized();
});

final parserServiceProvider = Provider<ParserService>((ref) => ParserService());

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  ref.watch(bootstrapProvider);
  return CategoryRepository(ref.watch(appDatabaseProvider));
});

final merchantRuleRepositoryProvider = Provider<MerchantRuleRepository>((ref) {
  return MerchantRuleRepository(ref.watch(appDatabaseProvider));
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(appDatabaseProvider));
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(appDatabaseProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(appDatabaseProvider));
});

final categorizationServiceProvider = Provider<CategorizationService>((ref) {
  return CategorizationService(ref.watch(merchantRuleRepositoryProvider));
});

final transactionIngestServiceProvider =
    Provider<TransactionIngestService>((ref) {
  return TransactionIngestService(
    parser: ref.watch(parserServiceProvider),
    transactions: ref.watch(transactionRepositoryProvider),
    categorization: ref.watch(categorizationServiceProvider),
  );
});

final smsServiceProvider = Provider<SmsService>((ref) {
  return SmsService(ingest: ref.watch(transactionIngestServiceProvider));
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(
    transactions: ref.watch(transactionRepositoryProvider),
    db: ref.watch(appDatabaseProvider),
  );
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(
    transactions: ref.watch(transactionRepositoryProvider),
    categories: ref.watch(categoryRepositoryProvider),
    analytics: ref.watch(analyticsServiceProvider),
  );
});

final excelImportServiceProvider = Provider<ExcelImportService>((ref) {
  return ExcelImportService(
    transactions: ref.watch(transactionRepositoryProvider),
    categories: ref.watch(categoryRepositoryProvider),
  );
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  ref.watch(bootstrapProvider);
  return ref.watch(profileRepositoryProvider).loadProfile();
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});

final transactionsStreamProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchAllTransactions();
});

final transactionByIdProvider =
    StreamProvider.family<Transaction?, String>((ref, id) {
  return ref.watch(transactionRepositoryProvider).watchById(id);
});

final uncategorizedStreamProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchUncategorized();
});

final budgetsStreamProvider = StreamProvider<List<Budget>>((ref) {
  return ref.watch(budgetRepositoryProvider).watchAll();
});

final monthlyAnalyticsProvider =
    FutureProvider.family<MonthlySummary, DateTime>((ref, month) async {
  // Watch transactions stream to trigger updates when transactions change
  ref.watch(transactionsStreamProvider);

  // Compute analytics from current transactions
  return ref.watch(analyticsServiceProvider).monthlySummary(
        month.year,
        month.month,
      );
});

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(userProfileProvider, (_, __) => refresh.value++);

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: refresh,
    redirect: (context, state) {
      final profileState = ref.read(userProfileProvider);
      if (profileState.isLoading) return null;

      final hasProfile = profileState.asData?.value != null;
      final onOnboarding = state.matchedLocation == '/onboarding';

      if (!hasProfile && !onOnboarding) return '/onboarding';
      if (hasProfile && onOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/data-usage',
        builder: (context, state) => const DataUsageScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => TransactionDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
            routes: [
              GoRoute(
                path: 'stats',
                builder: (context, state) => const StatsDashboardScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/budgets',
            builder: (context, state) => const BudgetsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
