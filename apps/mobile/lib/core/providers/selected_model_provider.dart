import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/ai_models.dart';

class AiModelOption {
  final String provider;
  final String model;
  final String label;
  final bool supportsThinking;
  final bool supportsVision;

  const AiModelOption({
    required this.provider,
    required this.model,
    required this.label,
    this.supportsThinking = false,
    this.supportsVision = false,
  });
}

final availableModels = <AiModelOption>[
  AiModelOption(provider: 'claude', model: AiModels.claudeDefault, label: 'Claude Sonnet 5', supportsThinking: true, supportsVision: true),
  AiModelOption(provider: 'openai', model: AiModels.openAiDefault, label: 'GPT-5.6', supportsThinking: false, supportsVision: true),
  AiModelOption(provider: 'gemini', model: AiModels.geminiDefault, label: 'Gemini 3.1 Pro', supportsThinking: true, supportsVision: true),
  // Qwen3.7 Max itself is text-only — the checkbox here reflects that an
  // image will get silently rerouted to AiModels.qwenVision instead, not
  // that this exact model string handles images.
  AiModelOption(provider: 'qwen', model: AiModels.qwenDefault, label: 'Qwen3.7 Max', supportsThinking: true, supportsVision: true),
];

final selectedModelProvider = StateProvider<AiModelOption>((ref) => availableModels.first);

/// Whether the user has switched on "show thinking" for models that
/// support it. Has no effect for providers where supportsThinking is
/// false (the toggle is hidden in the UI for those).
final thinkingModeEnabledProvider = StateProvider<bool>((ref) => false);

/// Carries a draft message typed on Home into the Chat screen.
final draftMessageProvider = StateProvider<String>((ref) => '');
