import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Privacy Policy',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Your Data Stays Private',
            content:
                '''Pulse Money is built on privacy-first principles. All your financial data stays on your device.

• No cloud storage
• No backend servers
• No data collection
• No third-party analytics
• No ad tracking''',
          ),
          _Section(
            title: 'Local Storage Only',
            content:
                '''Your transactions, budgets, and personal information are stored locally in an encrypted SQLite database.

The app only accesses what it needs:
• SMS messages (when enabled) for transaction detection
• Camera (if you add receipts)
• Local file storage''',
          ),
          _Section(
            title: 'SMS Permission',
            content: '''SMS access is used solely for:
• Reading bank transaction alerts
• Categorizing expenses automatically
• Understanding spending patterns

This data is processed 100% locally and never sent anywhere.''',
          ),
          _Section(
            title: 'Offline Operation',
            content:
                '''Pulse Money works completely offline. It doesn\'t require internet connection for:
• Transaction tracking
• Budget management
• Analytics and insights
• Report generation''',
          ),
          _Section(
            title: 'What You Control',
            content: '''You have full control over:
• SMS permission (can be disabled anytime)
• Data deletion
• Export options
• Backup management''',
          ),
          _Section(
            title: 'Changes to This Policy',
            content:
                '''We may update this policy from time to time. Changes will be posted in the app.

Version 1.0 - Last updated: May 26, 2026''',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
