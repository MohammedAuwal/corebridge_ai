/**
 * Central place for default AI model strings.
 *
 * The ai-router Edge Function routes purely by `provider` and never
 * hardcodes a model — so bumping a value here is the ONLY change
 * needed when Anthropic/OpenAI/Google/Alibaba ship a new release.
 *
 * Last verified: July 24, 2026.
 */
export const AI_MODELS = {
  claude: {
    default: 'claude-sonnet-5',
    fast: 'claude-haiku-4-5-20251001',
    max: 'claude-opus-4-8',
  },
  openai: {
    default: 'gpt-5.6-sol',
    balanced: 'gpt-5.6-terra',
    fast: 'gpt-5.6-luna',
  },
  gemini: {
    default: 'gemini-3.1-pro',
    fast: 'gemini-3.6-flash',
  },
  qwen: {
    default: 'qwen3.7-max',
    fast: 'qwen-plus',
  },
} as const;

export type AiProvider = keyof typeof AI_MODELS;

export function defaultModelFor(provider: AiProvider): string {
  return AI_MODELS[provider].default;
}
