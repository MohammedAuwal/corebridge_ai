import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/ai_models.dart';

class AiModelOption {
  final String provider;
  final String model;
  final String label;

  const AiModelOption({required this.provider, required this.model, required this.label});
}

final availableModels = <AiModelOption>[
  AiModelOption(provider: 'claude', model: AiModels.claudeDefault, label: 'Claude Sonnet 5'),
  AiModelOption(provider: 'openai', model: AiModels.openAiDefault, label: 'GPT-5.6'),
  AiModelOption(provider: 'gemini', model: AiModels.geminiDefault, label: 'Gemini 3.1 Pro'),
  AiModelOption(provider: 'qwen', model: AiModels.qwenDefault, label: 'Qwen3.7 Max'),
];

final selectedModelProvider = StateProvider<AiModelOption>((ref) => availableModels.first);

/// Carries a draft message typed on Home into the Chat screen.
final draftMessageProvider = StateProvider<String>((ref) => '');
