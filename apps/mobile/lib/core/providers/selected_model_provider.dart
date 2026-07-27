import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A provider option in the UI picker. Deliberately has NO model field —
/// the picker only ever selects a brand (Claude / ChatGPT / Gemini /
/// Qwen). The actual model string is resolved per-user at send time
/// from UserApiKeys.modelFor(provider), since different users' API
/// keys work with different model versions and we can't know which.
class AiModelOption {
  final String provider;
  final String label;
  final bool supportsThinking;
  final bool supportsVision;
  const AiModelOption({
    required this.provider,
    required this.label,
    this.supportsThinking = false,
    this.supportsVision = false,
  });
}

final availableModels = <AiModelOption>[
  AiModelOption(provider: 'claude', label: 'Claude', supportsThinking: true, supportsVision: true),
  AiModelOption(provider: 'openai', label: 'ChatGPT', supportsThinking: false, supportsVision: true),
  AiModelOption(provider: 'gemini', label: 'Gemini', supportsThinking: true, supportsVision: true),
  AiModelOption(provider: 'qwen', label: 'Qwen', supportsThinking: true, supportsVision: true),
];

final selectedModelProvider = StateProvider<AiModelOption>((ref) => availableModels.first);

/// Whether the user has switched on "show thinking" for models that
/// support it. Has no effect for providers where supportsThinking is
/// false (the toggle is hidden in the UI for those).
final thinkingModeEnabledProvider = StateProvider<bool>((ref) => false);

/// Carries a draft message typed on Home into the Chat screen.
final draftMessageProvider = StateProvider<String>((ref) => '');
