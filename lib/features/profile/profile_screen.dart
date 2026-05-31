import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/ui_helpers.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/profile_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile saved yet.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      child: Text(
                        profile.fullName.isNotEmpty
                            ? profile.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ProfileRow(label: 'Name', value: profile.fullName),
                    _ProfileRow(label: 'Username', value: profile.username),
                    _ProfileRow(
                      label: 'Currency',
                      value: profile.preferredCurrency,
                    ),
                    _ProfileRow(
                      label: 'Monthly income',
                      value: profile.monthlyIncome == null
                          ? 'Not set'
                          : '${profile.preferredCurrency} ${profile.monthlyIncome!.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _editProfile(context, ref, profile),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit profile'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading:
                          const Icon(Icons.account_balance_wallet_outlined),
                      title: const Text('Budgets'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/budgets'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.file_download_outlined),
                      title: const Text('Export report'),
                      onTap: () async {
                        try {
                          await ref.read(exportServiceProvider).shareReport();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Export failed: $e')),
                            );
                          }
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('Settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/settings'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final nameController = TextEditingController(text: profile.fullName);
    final userController = TextEditingController(text: profile.username);
    final incomeController = TextEditingController(
      text: profile.monthlyIncome?.toStringAsFixed(0) ?? '',
    );
    var currency = profile.preferredCurrency;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              TextField(
                controller: userController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              DropdownButtonFormField<String>(
                value: currency,
                items: ['INR', 'USD', 'EUR', 'GBP']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => currency = v ?? currency,
                decoration: const InputDecoration(labelText: 'Currency'),
              ),
              TextField(
                controller: incomeController,
                decoration: const InputDecoration(labelText: 'Monthly income'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );

    if (saved == true) {
      final income = double.tryParse(incomeController.text.trim());
      await ref.read(profileRepositoryProvider).saveProfile(
            ProfilesCompanion(
              id: Value(profile.id),
              fullName: Value(nameController.text.trim()),
              username: Value(userController.text.trim()),
              preferredCurrency: Value(currency),
              monthlyIncome:
                  income == null ? const Value.absent() : Value(income),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );
      ref.invalidate(userProfileProvider);
    }

    nameController.dispose();
    userController.dispose();
    incomeController.dispose();
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
