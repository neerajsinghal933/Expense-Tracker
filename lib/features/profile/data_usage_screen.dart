import 'package:flutter/material.dart';

class DataUsageScreen extends StatelessWidget {
  const DataUsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data & Storage')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'How We Use Your Data',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _InfoCard(
            icon: Icons.phone_android,
            title: 'Local Storage',
            description:
                'All data is stored on your device in an encrypted database. No cloud sync.',
          ),
          _InfoCard(
            icon: Icons.sms,
            title: 'SMS Analysis',
            description:
                'SMS messages are analyzed locally to detect transactions. Messages are never sent anywhere.',
          ),
          _InfoCard(
            icon: Icons.lock,
            title: 'Encryption',
            description:
                'Local database is encrypted using industry-standard encryption. Your data is protected.',
          ),
          _InfoCard(
            icon: Icons.language,
            title: 'Offline First',
            description:
                'The app functions 100% offline. No internet connection needed for any feature.',
          ),
          const SizedBox(height: 24),
          _Section(
            title: 'Permissions Explained',
            items: [
              _PermissionItem(
                permission: 'Read SMS',
                purpose:
                    'To detect and categorize bank transactions automatically',
                required: false,
              ),
              _PermissionItem(
                permission: 'Receive SMS',
                purpose: 'To process incoming SMS in the background',
                required: false,
              ),
              _PermissionItem(
                permission: 'Post Notifications',
                purpose: 'To send budget alerts and reminders',
                required: false,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Your Rights',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '✓ You can delete all data anytime\n'
            '✓ You can export your data\n'
            '✓ You can disable SMS permission\n'
            '✓ You can revoke any permission\n'
            '✓ Your data never leaves your device',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
  });

  final String title;
  final List<_PermissionItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _PermissionItemWidget(item: item)),
      ],
    );
  }
}

class _PermissionItem {
  const _PermissionItem({
    required this.permission,
    required this.purpose,
    required this.required,
  });

  final String permission;
  final String purpose;
  final bool required;
}

class _PermissionItemWidget extends StatelessWidget {
  const _PermissionItemWidget({required this.item});

  final _PermissionItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                item.permission,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: item.required
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.required ? 'Required' : 'Optional',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.purpose,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
