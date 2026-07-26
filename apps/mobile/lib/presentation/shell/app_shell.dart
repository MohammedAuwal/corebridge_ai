import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/providers.dart';
import '../../core/providers/conversation_provider.dart';
import '../../core/providers/scaffold_key_provider.dart';
import '../../core/providers/conversation_provider.dart';
import '../../core/providers/scaffold_key_provider.dart';
import '../../core/theme/app_theme.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _mainItems = [
    _NavItem('/home', Icons.home_outlined, 'Home'),
    _NavItem('/chat', Icons.chat_bubble_outline_rounded, 'Chat'),
    _NavItem('/projects', Icons.folder_special_outlined, 'Projects'),
    _NavItem('/artifacts', Icons.code_outlined, 'Artifacts'),
    _NavItem('/files', Icons.folder_copy_outlined, 'Files'),
    _NavItem('/knowledge-base', Icons.menu_book_outlined, 'Knowledge Base'),
    _NavItem('/prompt-library', Icons.library_books_outlined, 'Prompt Library'),
    _NavItem('/history', Icons.forum_outlined, 'Conversations'),
    _NavItem('/history', Icons.history_rounded, 'History'),
  ];

  static const _settingsItems = [
    _NavItem('/settings', Icons.settings_outlined, 'Settings'),
    _NavItem('/settings', Icons.power_settings_new_rounded, 'API Providers'),
    _NavItem('/usage-stats', Icons.bar_chart_rounded, 'Usage & Stats'),
  ];

  Widget _buildDrawerContent(BuildContext context, WidgetRef ref, {required bool inDrawer}) {
    final email = ref.watch(firebaseServiceProvider).auth.currentUser?.email ?? '';
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Container(
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CoreBridge AI', style: Theme.of(context).textTheme.titleLarge),
                        Text('Your AI workspace', style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ),
                  if (inDrawer)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ..._mainItems.map((item) => _drawerTile(context, ref, item, currentPath, inDrawer)),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                  ..._settingsItems.map((item) => _drawerTile(context, ref, item, currentPath, inDrawer)),
                ],
              ),
            ),
            const Divider(height: 1),
            InkWell(
              onTap: () => _showAccountMenu(context, ref),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        email.isNotEmpty ? email[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(email, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(BuildContext context, WidgetRef ref, _NavItem item, String currentPath, bool inDrawer) {
    final isSelected = item.path == currentPath;
    return ListTile(
      leading: Icon(item.icon, color: isSelected ? AppColors.accentBlue : AppColors.textSecondary, size: 20),
      title: Text(item.label, style: TextStyle(color: isSelected ? AppColors.accentBlue : AppColors.textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
      selected: isSelected,
      selectedTileColor: AppColors.accentBlue.withValues(alpha: 0.08),
      dense: true,
      onTap: () {
        if (inDrawer) Navigator.of(context).pop();
        if (item.path == '/chat') {
          ref.read(activeConversationIdProvider.notifier).state = null;
        }
        context.go(item.path);
      },
    );
  }

  void _showAccountMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceRaised,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
      builder: (sheetContext) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          title: const Text('Sign out'),
          onTap: () {
            Navigator.pop(sheetContext);
            ref.read(firebaseServiceProvider).signOut();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            SizedBox(width: 260, child: _buildDrawerContent(context, ref, inDrawer: false)),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      key: ref.watch(scaffoldKeyProvider),
      drawer: Drawer(
        width: 280,
        backgroundColor: AppColors.surface,
        child: _buildDrawerContent(context, ref, inDrawer: true),
      ),
      body: child,
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final String label;
  const _NavItem(this.path, this.icon, this.label);
}
