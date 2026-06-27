import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../services/import/excel_import_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          const ListTile(
            title: Text('SMS permissions'),
            subtitle: Text('Required to read bank SMS on this device only'),
          ),
          ListTile(
            leading: const Icon(Icons.sms_outlined),
            title: const Text('Grant SMS access'),
            onTap: () async {
              final granted =
                  await ref.read(smsServiceProvider).requestPermissions();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      granted ? 'SMS permission granted' : 'Permission denied',
                    ),
                  ),
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Export all-time Excel report'),
            subtitle: const Text('Includes every transaction saved locally'),
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
            leading: const Icon(Icons.upload_file_outlined),
            title: const Text('Import from Excel'),
            subtitle:
                const Text('Review rows first. Existing data is kept safe.'),
            onTap: () => _startImport(context, ref),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              initialValue:
                  ref.watch(appSettingsControllerProvider).state.fontFamily,
              decoration: const InputDecoration(
                labelText: 'Font family',
                prefixIcon: Icon(Icons.text_fields_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'inter', child: Text('Inter')),
                DropdownMenuItem(value: 'lato', child: Text('Lato')),
                DropdownMenuItem(
                    value: 'creepster', child: Text('Creepster horror')),
              ],
              onChanged: (value) async {
                if (value == null) return;
                await ref
                    .read(appSettingsControllerProvider)
                    .setFontFamily(value);
              },
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('Privacy'),
            subtitle: Text(
              'Offline-first. No cloud sync. Financial data stays on this device.',
            ),
          ),
          ListTile(
            title: const Text('App version'),
            subtitle: Text('0.2.0'),
          ),
        ],
      ),
    );
  }

  Future<void> _startImport(BuildContext context, WidgetRef ref) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Back up before importing'),
        content: const Text(
          'Import keeps existing data by default, but a fresh Excel backup is strongly recommended before adding rows from another file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(exportServiceProvider).shareReport();
              } catch (_) {}
            },
            child: const Text('Back up now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Choose file'),
          ),
        ],
      ),
    );
    if (proceed != true || !context.mounted) return;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xlsm', 'xls'],
      withData: false,
    );
    final path = picked?.files.single.path;
    if (path == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Reading workbook...')),
    );

    final preview = await ref.read(excelImportServiceProvider).preview(path);
    if (!context.mounted) return;
    if (preview.errors.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(preview.errors.join('\n'))),
      );
      return;
    }

    final commit = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _ImportReviewScreen(preview: preview),
      ),
    );
    if (commit != true || !context.mounted) return;

    try {
      final result = await ref.read(excelImportServiceProvider).commit(preview);
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Import complete: ${result.inserted} added, ${result.skipped} skipped.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }
}

class _ImportReviewScreen extends StatelessWidget {
  const _ImportReviewScreen({required this.preview});

  final ImportPreview preview;

  @override
  Widget build(BuildContext context) {
    final validRows = preview.rows.where((r) => r.isValid).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review import'),
        actions: [
          TextButton(
            onPressed: preview.validCount == 0
                ? null
                : () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                        child: _ImportStat('Rows', '${preview.rows.length}')),
                    Expanded(child: _ImportStat('Valid', '$validRows')),
                    Expanded(
                        child: _ImportStat('New', '${preview.validCount}')),
                    Expanded(
                        child: _ImportStat(
                            'Duplicates', '${preview.duplicateCount}')),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: preview.rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final row = preview.rows[index];
                final date = row.timestamp == 0
                    ? 'Invalid date'
                    : DateFormat('dd MMM yyyy').format(
                        DateTime.fromMillisecondsSinceEpoch(row.timestamp),
                      );
                final problems = [
                  ...row.errors,
                  ...row.warnings,
                  if (row.isDuplicate) 'Duplicate skipped',
                ];
                return ListTile(
                  leading: Icon(
                    row.errors.isNotEmpty
                        ? Icons.error_outline
                        : row.isDuplicate
                            ? Icons.copy_outlined
                            : Icons.check_circle_outline,
                    color: row.errors.isNotEmpty
                        ? Colors.redAccent
                        : row.isDuplicate
                            ? Colors.orangeAccent
                            : Colors.greenAccent,
                  ),
                  title: Text(
                    '${row.currency} ${row.amount.toStringAsFixed(2)} · ${row.type}',
                  ),
                  subtitle: Text(
                    [
                      row.merchantName.isEmpty
                          ? 'No merchant'
                          : row.merchantName,
                      row.categoryName,
                      date,
                      if (problems.isNotEmpty) problems.join(', '),
                    ].join(' · '),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: preview.validCount == 0
                ? null
                : () => Navigator.pop(context, true),
            icon: const Icon(Icons.playlist_add_check_outlined),
            label: Text('Import ${preview.validCount} new rows'),
          ),
        ),
      ),
    );
  }
}

class _ImportStat extends StatelessWidget {
  const _ImportStat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
