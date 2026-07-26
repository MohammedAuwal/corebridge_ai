import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/selected_model_provider.dart';
import '../../core/theme/app_theme.dart';

class ModelPickerChip extends ConsumerWidget {
  const ModelPickerChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedModelProvider);

    return PopupMenuButton<AiModelOption>(
      initialValue: selected,
      onSelected: (option) => ref.read(selectedModelProvider.notifier).state = option,
      color: AppColors.surfaceRaised,
      offset: const Offset(0, -8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
      itemBuilder: (context) => availableModels
          .map((option) => PopupMenuItem(value: option, child: Text(option.label)))
          .toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selected.label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
