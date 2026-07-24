import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _destinations = [
    _NavDestination('/home', LucideIcons.home, 'Home'),
    _NavDestination('/chat', LucideIcons.messageSquare, 'Chat'),
    _NavDestination('/projects', LucideIcons.folderKanban, 'Projects'),
    _NavDestination('/artifacts', LucideIcons.fileCode, 'Artifacts'),
    _NavDestination('/files', LucideIcons.files, 'Files'),
    _NavDestination('/knowledge-base', LucideIcons.bookOpen, 'Knowledge'),
    _NavDestination('/prompt-library', LucideIcons.library, 'Prompts'),
    _NavDestination('/history', LucideIcons.history, 'History'),
    _NavDestination('/settings', LucideIcons.settings, 'Settings'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _destinations.indexWhere((d) => d.path == location);
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    final currentIndex = _currentIndex(context);

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: (i) => context.go(_destinations[i].path),
              labelType: NavigationRailLabelType.all,
              destinations: _destinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        label: Text(d.label),
                      ))
                  .toList(),
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
        selectedIndex: currentIndex.clamp(0, 4),
        onDestinationSelected: (i) => context.go(_destinations[i].path),
        destinations: _destinations
            .take(5)
            .map((d) => NavigationDestination(icon: Icon(d.icon), label: d.label))
            .toList(),
      ),
    );
  }
}

class _NavDestination {
  final String path;
  final IconData icon;
  final String label;

  const _NavDestination(this.path, this.icon, this.label);
}
