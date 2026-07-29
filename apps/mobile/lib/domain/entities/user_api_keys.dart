import '../../core/constants/ai_models.dart';

/// Per-user, per-provider API keys, model strings, and a default
/// provider choice — so a user only has to pick "Claude" once in
/// Settings and every new chat opens with that provider pre-selected.
class UserApiKeys {
  final String? claude;
  final String? openai;
  final String? gemini;
  final String? qwen;

  final String? claudeModel;
  final String? openaiModel;
  final String? geminiModel;
  final String? qwenModel;

  /// Provider key ('claude'/'openai'/'gemini'/'qwen') the user picked as
  /// their default in API Providers. Null/empty means no preference set
  /// yet — the app falls back to whatever selectedModelProvider was
  /// already seeded with (Claude).
  final String? defaultProvider;

  const UserApiKeys({
    this.claude,
    this.openai,
    this.gemini,
    this.qwen,
    this.claudeModel,
    this.openaiModel,
    this.geminiModel,
    this.qwenModel,
    this.defaultProvider,
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
      defaultProvider: map['defaultProvider'] as String?,
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
      if (defaultProvider != null) 'defaultProvider': defaultProvider,
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
    String? defaultProvider,
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
      defaultProvider: defaultProvider ?? this.defaultProvider,
    );
  }
}
