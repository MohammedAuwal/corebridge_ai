import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _destinations = [
    _NavDestination('/home', Icons.home_outlined, 'Home'),
    _NavDestination('/chat', Icons.chat_bubble_outline, 'Chat'),
    _NavDestination('/projects', Icons.folder_special_outlined, 'Projects'),
    _NavDestination('/artifacts', Icons.code_outlined, 'Artifacts'),
    _NavDestination('/files', Icons.folder_copy_outlined, 'Files'),
    _NavDestination('/knowledge-base', Icons.menu_book_outlined, 'Knowledge'),
    _NavDestination('/prompt-library', Icons.library_books_outlined, 'Prompts'),
    _NavDestination('/history', Icons.history_outlined, 'History'),
    _NavDestination('/settings', Icons.settings_outlined, 'Settings'),
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
