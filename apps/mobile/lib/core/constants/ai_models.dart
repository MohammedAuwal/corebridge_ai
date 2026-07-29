/// Central place for default AI model strings — used ONLY as a fallback
/// when a user hasn't connected a key yet (so the picker has something
/// to show) or when auto-detection fails outright. Once a key is
/// connected, ai-router's listModels action detects a real working
/// model for that specific key, and UserApiKeys.modelFor() prefers that
/// over anything here.
///
/// Last verified: July 29, 2026 — re-check provider docs periodically,
/// since these strings change every few weeks in this market.
class AiModels {
  AiModels._();

  static const String claudeDefault = 'claude-sonnet-5';
  static const String claudeFast = 'claude-haiku-4-5-20251001';
  static const String claudeMax = 'claude-opus-4-8';

  static const String openAiDefault = 'gpt-5.6-sol';
  static const String openAiBalanced = 'gpt-5.6-terra';
  static const String openAiFast = 'gpt-5.6-luna';

  static const String geminiDefault = 'gemini-3.1-pro-preview';
  static const String geminiFast = 'gemini-3.6-flash';

  static const String qwenDefault = 'qwen3.7-max';
  static const String qwenFast = 'qwen-plus';

  /// Last-resort fallback ONLY — used if a user has never connected a
  /// Qwen key (so auto-detection has never run) but somehow still sends
  /// an image, or if vision auto-detection itself fails. Once a key is
  /// connected, UserApiKeys.qwenVisionModel (detected from the user's
  /// own account) is always preferred over this.
  static const String qwenVision = 'qwen-vl-max';

  /// Maps a provider key to its recommended default model.
  static String defaultFor(String provider) {
    switch (provider) {
      case 'claude':
        return claudeDefault;
      case 'openai':
        return openAiDefault;
      case 'gemini':
        return geminiDefault;
      case 'qwen':
        return qwenDefault;
      default:
        throw ArgumentError('Unknown provider: $provider');
    }
  }
}
