import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/permission_onboarding_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionOnboardingDialog extends ConsumerWidget {
  const PermissionOnboardingDialog({
    super.key,
    this.onGranted,
    this.onSkipped,
  });

  final VoidCallback? onGranted;
  final VoidCallback? onSkipped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(permissionOnboardingProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: _buildContent(context, ref, state),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    PermissionOnboardingState state,
  ) {
    switch (state) {
      case PermissionOnboardingState.notStarted:
      case PermissionOnboardingState.explaining:
        return _ExplanationView(onRequestPressed: () async {
          final granted = await ref
              .read(permissionOnboardingProvider.notifier)
              .requestSmsPermission();
          if (granted && onGranted != null) {
            onGranted!();
          }
        }, onSkipPressed: () async {
          await ref
              .read(permissionOnboardingProvider.notifier)
              .skipPermissionForNow();
          if (onSkipped != null) {
            onSkipped!();
          }
          if (context.mounted) Navigator.pop(context);
        });

      case PermissionOnboardingState.requesting:
        return const _LoadingView();

      case PermissionOnboardingState.granted:
        return _SuccessView(
          onClose: () {
            if (onGranted != null) onGranted!();
            if (context.mounted) Navigator.pop(context);
          },
        );

      case PermissionOnboardingState.denied:
        return _DeniedView(
          onRetry: () async {
            final granted = await ref
                .read(permissionOnboardingProvider.notifier)
                .requestSmsPermission();
            if (granted && onGranted != null) {
              onGranted!();
            }
          },
          onClose: () {
            if (onSkipped != null) onSkipped!();
            if (context.mounted) Navigator.pop(context);
          },
        );

      case PermissionOnboardingState.permanentlyDenied:
        return _PermanentlyDeniedView(
          onClose: () {
            if (onSkipped != null) onSkipped!();
            if (context.mounted) Navigator.pop(context);
          },
        );
    }
  }
}

class _ExplanationView extends StatelessWidget {
  const _ExplanationView({
    required this.onRequestPressed,
    required this.onSkipPressed,
  });

  final VoidCallback onRequestPressed;
  final VoidCallback onSkipPressed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Enable Smart Expense Detection',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Let Pulse Money automatically detect and categorize transactions from your bank SMS alerts.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Benefits
            _BenefitItem(
              icon: Icons.auto_awesome,
              title: 'Automatic Detection',
              description: 'SMS transactions are detected automatically',
            ),
            const SizedBox(height: 12),
            _BenefitItem(
              icon: Icons.category,
              title: 'Smart Categorization',
              description: 'Expenses are categorized intelligently',
            ),
            const SizedBox(height: 12),
            _BenefitItem(
              icon: Icons.lock,
              title: 'Privacy First',
              description: 'All processing happens locally on your device',
            ),
            const SizedBox(height: 24),

            // Privacy Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'SMS data is processed 100% locally. Nothing is sent to servers.',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            FilledButton(
              onPressed: onRequestPressed,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Enable Smart Detection'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onSkipPressed,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Maybe Later'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Requesting Permission...',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 40,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Permission Granted!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Smart expense detection is now active. Your bank SMS will be automatically analyzed.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onClose,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }
}

class _DeniedView extends StatelessWidget {
  const _DeniedView({
    required this.onRetry,
    required this.onClose,
  });

  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              size: 40,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Permission Needed',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'SMS permission is required for automatic transaction detection. You can enable it anytime in Settings.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Try Again'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onClose,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Continue Without'),
          ),
        ],
      ),
    );
  }
}

class _PermanentlyDeniedView extends StatelessWidget {
  const _PermanentlyDeniedView({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 40,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Permission Permanently Denied',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'To enable smart expense detection, please grant SMS permission in your app settings.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => openAppSettings(),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Open Settings'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onClose,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
