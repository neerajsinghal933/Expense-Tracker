import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/app_providers.dart';
import '../data/db/app_database.dart';

Future<String?> showCategoryPicker(
  BuildContext context, {
  String? selectedId,
  bool Function(Category)? filter,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) =>
        _CategoryPickerSheet(selectedId: selectedId, filter: filter),
  );
}

class _CategoryPickerSheet extends ConsumerWidget {
  const _CategoryPickerSheet({this.selectedId, this.filter});

  final String? selectedId;
  final bool Function(Category)? filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return SafeArea(
      child: categoriesAsync.when(
        data: (categories) {
          final filtered = filter == null
              ? categories
              : categories.where((c) => filter!(c)).toList();
          return ListView(
            shrinkWrap: true,
            children: filtered
                .map(
                  (c) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(
                        int.parse('FF${c.colorHex ?? 'AAB3C0'}', radix: 16),
                      ),
                      radius: 14,
                    ),
                    title: Text(c.name),
                    trailing:
                        selectedId == c.id ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.pop(context, c.id),
                  ),
                )
                .toList(),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $e'),
        ),
      ),
    );
  }
}
