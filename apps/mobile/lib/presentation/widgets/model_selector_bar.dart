import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/conversation_provider.dart';
import '../../core/providers/scaffold_key_provider.dart';
import '../../core/theme/app_theme.dart';

/// Top bar for chat screens: hamburger menu on the left, a "new chat"
/// icon on the right — matches the hand-drawn reference exactly.
/// The model picker no longer lives up here; see ModelPickerChip,
/// which sits next to the composer instead.
class ModelSelectorBar extends ConsumerWidget {
  const ModelSelectorBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
              onPressed: () {
                final scaffoldKey = ref.read(scaffoldKeyProvider);
                scaffoldKey.currentState?.openDrawer();
              },
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.edit_square, color: AppColors.textPrimary),
              tooltip: 'New chat',
              onPressed: () {
                ref.read(activeConversationIdProvider.notifier).state = null;
                context.go('/chat');
              },
            ),
          ],
        ),
      ),
    );
  }
}
