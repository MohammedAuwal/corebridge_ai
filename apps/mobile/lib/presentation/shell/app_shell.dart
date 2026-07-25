import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/providers.dart';
import '../../core/theme/app_theme.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _primaryDestinations = [
    _NavDestination('/home', Icons.home_rounded, Icons.home_outlined, 'Home'),
    _NavDestination('/chat', Icons.chat_bubble_rounded, Icons.chat_bubble_outline, 'Chat'),
    _NavDestination('/projects', Icons.folder_special_rounded, Icons.folder_special_outlined, 'Projects'),
    _NavDestination('/artifacts', Icons.code_rounded, Icons.code_outlined, 'Artifacts'),
    _NavDestination('/files', Icons.folder_copy_rounded, Icons.folder_copy_outlined, 'Files'),
  ];

  static const _moreDestinations = [
    _NavDestination('/knowledge-base', Icons.menu_book_rounded, Icons.menu_book_outlined, 'Knowledge Base'),
    _NavDestination('/prompt-library', Icons.library_books_rounded, Icons.library_books_outlined, 'Prompt Library'),
    _NavDestination('/history', Icons.history_rounded, Icons.history_outlined, 'History'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _primaryDestinations.indexWhere((d) => d.path == location);
    return index == -1 ? -1 : index;
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _moreDestinations.map((d) {
              return ListTile(
                leading: Icon(d.filledIcon, color: AppColors.accentBlue),
                title: Text(d.label),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(d.path);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showAccountMenu(BuildContext context, WidgetRef ref) {
    final email = ref.read(firebaseServiceProvider).auth.currentUser?.email ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      gradient: AppColors.brandGradient,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      email.isNotEmpty ? email[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      email,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.vpn_key_rounded, color: AppColors.accentBlue),
                title: const Text('AI Provider API Keys'),
                subtitle: const Text('Manage your Claude, OpenAI, Gemini, Qwen keys'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go('/settings');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text('Sign out'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ref.read(firebaseServiceProvider).signOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    final currentIndex = _currentIndex(context);

    final topBar = SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
              child: const Text(
                'CoreBridge AI',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showAccountMenu(context, ref),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );

    if (isWide) {
      return Scaffold(
        body: Column(
          children: [
            topBar,
            const Divider(height: 1),
            Expanded(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: currentIndex.clamp(0, _primaryDestinations.length - 1),
                    onDestinationSelected: (i) => context.go(_primaryDestinations[i].path),
                    labelType: NavigationRailLabelType.all,
                    destinations: _primaryDestinations
                        .map((d) => NavigationRailDestination(
                              icon: Icon(d.outlineIcon),
                              selectedIcon: Icon(d.filledIcon),
                              label: Text(d.label),
                            ))
                        .toList(),
                    trailing: Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: IconButton(
                            tooltip: 'More',
                            icon: const Icon(Icons.more_horiz_rounded),
                            onPressed: () => _showMoreSheet(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          topBar,
          const Divider(height: 1),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex == -1 ? _primaryDestinations.length : currentIndex.clamp(0, _primaryDestinations.length),
        onDestinationSelected: (i) {
          if (i == _primaryDestinations.length) {
            _showMoreSheet(context);
            return;
          }
          context.go(_primaryDestinations[i].path);
        },
        destinations: [
          ..._primaryDestinations.map((d) => NavigationDestination(
                icon: Icon(d.outlineIcon),
                selectedIcon: Icon(d.filledIcon),
                label: d.label,
              )),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class _NavDestination {
  final String path;
  final IconData filledIcon;
  final IconData outlineIcon;
  final String label;

  const _NavDestination(this.path, this.filledIcon, this.outlineIcon, this.label);
}
