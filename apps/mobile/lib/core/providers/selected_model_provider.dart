import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/ai_models.dart';

class AiModelOption {
  final String provider;
  final String model;
  final String label;
  final bool supportsThinking;

  const AiModelOption({
    required this.provider,
    required this.model,
    required this.label,
    this.supportsThinking = false,
  });
}

final availableModels = <AiModelOption>[
  AiModelOption(provider: 'claude', model: AiModels.claudeDefault, label: 'Claude Sonnet 5', supportsThinking: true),
  AiModelOption(provider: 'openai', model: AiModels.openAiDefault, label: 'GPT-5.6', supportsThinking: false),
  AiModelOption(provider: 'gemini', model: AiModels.geminiDefault, label: 'Gemini 3.1 Pro', supportsThinking: true),
  AiModelOption(provider: 'qwen', model: AiModels.qwenDefault, label: 'Qwen3.7 Max', supportsThinking: true),
];

final selectedModelProvider = StateProvider<AiModelOption>((ref) => availableModels.first);

/// Whether the user has switched on "show thinking" for models that
/// support it. Has no effect for providers where supportsThinking is
/// false (the toggle is hidden in the UI for those).
final thinkingModeEnabledProvider = StateProvider<bool>((ref) => false);

/// Carries a draft message typed on Home into the Chat screen.
final draftMessageProvider = StateProvider<String>((ref) => '');
