import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/manual_transaction_sheet.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    _NavItem('/', Icons.home_outlined, Icons.home, 'Home'),
    _NavItem('/transactions', Icons.receipt_long_outlined, Icons.receipt_long,
        'Transactions'),
    _NavItem(
        '/analytics', Icons.insights_outlined, Icons.insights, 'Analytics'),
    _NavItem('/calendar', Icons.calendar_month_outlined, Icons.calendar_month,
        'Calendar'),
    _NavItem('/profile', Icons.person_outline, Icons.person, 'Profile'),
  ];

  int _selectedIndex(String location) {
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/analytics')) return 2;
    if (location.startsWith('/calendar')) return 3;
    if (location.startsWith('/profile') ||
        location.startsWith('/budgets') ||
        location.startsWith('/settings')) {
      return 4;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selected = _selectedIndex(location);

    return Scaffold(
      body: child,
      floatingActionButton: location == '/'
          ? FloatingActionButton(
              onPressed: () => showManualTransactionSheet(context),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (index) {
          final path = _destinations[index].path;
          if (!location.startsWith(path) || path != '/transactions') {
            context.go(path);
          } else if (path == '/transactions' && location.contains('/')) {
            context.go('/transactions');
          }
        },
        destinations: _destinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.path, this.icon, this.selectedIcon, this.label);

  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
