import '../../core/constants/ai_models.dart';

/// Per-user, per-provider API keys AND model strings.
///
/// The model fields are the whole point of "bring your own model": a
/// user's Claude key might only work with claude-sonnet-5, another
/// user's with claude-opus-4-8 or claude-haiku-4-5-20251001. We never
/// hardcode a version in the app — whatever the user types here (or
/// leaves blank, falling back to AiModels.defaultFor) is what actually
/// gets sent to ai-router.
class UserApiKeys {
  final String? claude;
  final String? openai;
  final String? gemini;
  final String? qwen;

  final String? claudeModel;
  final String? openaiModel;
  final String? geminiModel;
  final String? qwenModel;

  const UserApiKeys({
    this.claude,
    this.openai,
    this.gemini,
    this.qwen,
    this.claudeModel,
    this.openaiModel,
    this.geminiModel,
    this.qwenModel,
  });

  factory UserApiKeys.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserApiKeys();
    return UserApiKeys(
      claude: map['claude'] as String?,
      openai: map['openai'] as String?,
      gemini: map['gemini'] as String?,
      qwen: map['qwen'] as String?,
      claudeModel: map['claudeModel'] as String?,
      openaiModel: map['openaiModel'] as String?,
      geminiModel: map['geminiModel'] as String?,
      qwenModel: map['qwenModel'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (claude != null) 'claude': claude,
      if (openai != null) 'openai': openai,
      if (gemini != null) 'gemini': gemini,
      if (qwen != null) 'qwen': qwen,
      if (claudeModel != null) 'claudeModel': claudeModel,
      if (openaiModel != null) 'openaiModel': openaiModel,
      if (geminiModel != null) 'geminiModel': geminiModel,
      if (qwenModel != null) 'qwenModel': qwenModel,
    };
  }

  String? forProvider(String provider) {
    switch (provider) {
      case 'claude':
        return claude;
      case 'openai':
        return openai;
      case 'gemini':
        return gemini;
      case 'qwen':
        return qwen;
      default:
        return null;
    }
  }

  /// The model string to actually send to ai-router for [provider].
  /// User's own override if they set one (non-empty), otherwise the
  /// current recommended default. This is the single source of truth
  /// for "which model" — the UI picker only ever selects a provider.
  String modelFor(String provider) {
    final override = _modelOverrideFor(provider)?.trim();
    if (override != null && override.isNotEmpty) return override;
    return AiModels.defaultFor(provider);
  }

  String? _modelOverrideFor(String provider) {
    switch (provider) {
      case 'claude':
        return claudeModel;
      case 'openai':
        return openaiModel;
      case 'gemini':
        return geminiModel;
      case 'qwen':
        return qwenModel;
      default:
        return null;
    }
  }

  UserApiKeys copyWith({
    String? claude,
    String? openai,
    String? gemini,
    String? qwen,
    String? claudeModel,
    String? openaiModel,
    String? geminiModel,
    String? qwenModel,
  }) {
    return UserApiKeys(
      claude: claude ?? this.claude,
      openai: openai ?? this.openai,
      gemini: gemini ?? this.gemini,
      qwen: qwen ?? this.qwen,
      claudeModel: claudeModel ?? this.claudeModel,
      openaiModel: openaiModel ?? this.openaiModel,
      geminiModel: geminiModel ?? this.geminiModel,
      qwenModel: qwenModel ?? this.qwenModel,
    );
  }
}
