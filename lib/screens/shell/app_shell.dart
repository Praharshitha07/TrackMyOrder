import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Responsive navigation shell.
/// Mobile (< 600): Bottom NavigationBar
/// Tablet/Desktop (≥ 600): NavigationRail
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _destinations = [
    _NavDest('/home', Icons.home_outlined, Icons.home, 'Home'),
    _NavDest(
      '/orders',
      Icons.inventory_2_outlined,
      Icons.inventory_2,
      'Orders',
    ),
    _NavDest(
      '/analytics',
      Icons.bar_chart_outlined,
      Icons.bar_chart,
      'Analytics',
    ),
    _NavDest('/profile', Icons.person_outline, Icons.person, 'Profile'),
  ];

  int _indexOf(String location) {
    for (var i = 0; i < _destinations.length; i++) {
      if (location.startsWith(_destinations[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _indexOf(location);
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) => context.go(_destinations[i].path),
              labelType: NavigationRailLabelType.all,
              useIndicator: true,
              destinations: _destinations.map((d) {
                return NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                );
              }).toList(),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.local_shipping,
                      color: AppTheme.electricLime,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TMO',
                      style: const TextStyle(
                        color: AppTheme.electricLime,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => context.go(_destinations[i].path),
        destinations: _destinations.map((d) {
          return NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
          );
        }).toList(),
      ),
    );
  }
}

class _NavDest {
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavDest(this.path, this.icon, this.selectedIcon, this.label);
}
