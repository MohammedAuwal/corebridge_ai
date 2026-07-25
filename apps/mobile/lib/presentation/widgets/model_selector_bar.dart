import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/scaffold_key_provider.dart';
import '../../core/providers/selected_model_provider.dart';
import '../../core/theme/app_theme.dart';

class ModelSelectorBar extends ConsumerWidget {
  const ModelSelectorBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedModelProvider);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () {
                final scaffoldKey = ref.read(scaffoldKeyProvider);
                scaffoldKey.currentState?.openDrawer();
              },
            ),
            const Spacer(),
            PopupMenuButton<AiModelOption>(
              initialValue: selected,
              onSelected: (option) => ref.read(selectedModelProvider.notifier).state = option,
              color: AppColors.surfaceRaised,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
              itemBuilder: (context) => availableModels
                  .map((option) => PopupMenuItem(value: option, child: Text(option.label)))
                  .toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(selected.label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
              child: const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
