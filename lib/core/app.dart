import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/app_providers.dart';
import 'theme/app_theme.dart';

final appInitProvider = FutureProvider<void>((ref) async {
  await ref.watch(bootstrapProvider.future);
  await ref.read(appSettingsControllerProvider).load();
  // Initialize SMS service without requesting permissions
  // Permissions will be requested through smart onboarding flow
  try {
    await ref.read(smsServiceProvider).initialize();
  } catch (_) {}
});

class ExpenseApp extends ConsumerWidget {
  const ExpenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final init = ref.watch(appInitProvider);
    final router = ref.watch(routerProvider);
    final settings = ref.watch(appSettingsControllerProvider).state;

    return init.when(
      data: (_) => MaterialApp.router(
        title: 'Pulse Money',
        theme: AppTheme.lightTheme(settings.fontFamily),
        darkTheme: AppTheme.darkTheme(settings.fontFamily),
        themeMode: ThemeMode.dark,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
      loading: () => MaterialApp(
        theme: AppTheme.darkTheme(settings.fontFamily),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => MaterialApp(
        theme: AppTheme.darkTheme(settings.fontFamily),
        home: Scaffold(body: Center(child: Text('Startup error: $e'))),
      ),
    );
  }
}
