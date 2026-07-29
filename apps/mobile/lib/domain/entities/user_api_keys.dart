import '../../core/constants/ai_models.dart';

/// Per-user, per-provider API keys AND model strings.
///
/// The model fields are the whole point of "bring your own model": a
/// user's Claude key might only work with claude-sonnet-5, another
/// user's with claude-opus-4-8. We never hardcode a version in the app
/// — whatever gets auto-detected for the user's own key (or what they
/// type manually, or today's recommended default as a last resort) is
/// what actually gets sent to ai-router.
///
/// qwenVisionModel is separate from qwenModel because Qwen's chat-tier
/// models (e.g. qwen3.7-max) and vision-capable models (the "-vl-"
/// line) are often different model ids on Alibaba's side — a message
/// with an image attached needs the vision one specifically.
class UserApiKeys {
  final String? claude;
  final String? openai;
  final String? gemini;
  final String? qwen;

  final String? claudeModel;
  final String? openaiModel;
  final String? geminiModel;
  final String? qwenModel;

  final String? qwenVisionModel;

  const UserApiKeys({
    this.claude,
    this.openai,
    this.gemini,
    this.qwen,
    this.claudeModel,
    this.openaiModel,
    this.geminiModel,
    this.qwenModel,
    this.qwenVisionModel,
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
      qwenVisionModel: map['qwenVisionModel'] as String?,
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
      if (qwenVisionModel != null) 'qwenVisionModel': qwenVisionModel,
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
  ///
  /// hasImages: when true and provider is 'qwen', resolves to the
  /// user's detected vision-capable model instead of their regular
  /// chat model override — Qwen's chat and vision model ids are often
  /// different, unlike Claude/OpenAI/Gemini where the default chat
  /// model already handles images.
  String modelFor(String provider, {bool hasImages = false}) {
    if (hasImages && provider == 'qwen') {
      final visionOverride = qwenVisionModel?.trim();
      if (visionOverride != null && visionOverride.isNotEmpty) return visionOverride;
      // No vision model detected yet for this key (e.g. key was
      // connected before this feature existed, or detection failed).
      // Falls back to the flagged-as-unverified constant as a last
      // resort rather than failing outright.
      return AiModels.qwenVision;
    }

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
    String? qwenVisionModel,
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
      qwenVisionModel: qwenVisionModel ?? this.qwenVisionModel,
    );
  }
}
