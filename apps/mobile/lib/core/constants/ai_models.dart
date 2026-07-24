/// Central place for default AI model strings.
///
/// The ai-router Edge Function never hardcodes a model — it only routes
/// by `provider`. That means updating a model here (or passing a fresh
/// string from Settings at runtime) is the ONLY change needed when a
/// provider ships a new release. No Edge Function redeploy required.
///
/// Last verified: July 24, 2026 — re-check provider docs periodically,
/// since these strings change every few weeks in this market.
class AiModels {
  AiModels._();

  static const String claudeDefault = 'claude-sonnet-5';
  static const String claudeFast = 'claude-haiku-4-5-20251001';
  static const String claudeMax = 'claude-opus-4-8';

  static const String openAiDefault = 'gpt-5.6-sol';
  static const String openAiBalanced = 'gpt-5.6-terra';
  static const String openAiFast = 'gpt-5.6-luna';

  static const String geminiDefault = 'gemini-3.1-pro';
  static const String geminiFast = 'gemini-3.6-flash';

  static const String qwenDefault = 'qwen3.7-max';
  static const String qwenFast = 'qwen-plus';

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
