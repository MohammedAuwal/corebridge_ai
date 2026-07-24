import { auth } from '../remote/firebase/firebase-config';
import { SUPABASE_FUNCTIONS_URL } from '../remote/supabase/supabase-config';
import { getUserApiKeys } from './user-settings-repository';

interface ChatMessage {
  role: string;
  content: string;
}

/**
 * Streams a chat completion through ai-router, automatically attaching
 * the signed-in user's own API key for the chosen provider (BYOK).
 * Throws a clear error if that provider's key hasn't been set yet.
 */
export async function* streamAssistantReply(params: {
  provider: 'claude' | 'openai' | 'gemini' | 'qwen';
  model: string;
  messages: ChatMessage[];
}): AsyncGenerator<string> {
  const user = auth.currentUser;
  if (!user) throw new Error('Not signed in.');

  const idToken = await user.getIdToken();
  const apiKeys = await getUserApiKeys(user.uid);
  const apiKey = apiKeys[params.provider];

  if (!apiKey) {
    throw new Error(
      `No API key set for ${params.provider}. Add one in Settings → AI Providers.`,
    );
  }

  const response = await fetch(`${SUPABASE_FUNCTIONS_URL}/ai-router`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      provider: params.provider,
      model: params.model,
      messages: params.messages,
      apiKey,
    }),
  });

  if (!response.ok || !response.body) {
    const errBody = await response.json().catch(() => ({ error: 'Unknown error' }));
    throw new Error(errBody.error ?? 'ai-router request failed');
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });

    const lines = buffer.split('\n');
    buffer = lines.pop() ?? '';

    for (const line of lines) {
      if (!line.startsWith('data: ')) continue;
      const payload = line.slice(6).trim();
      if (payload === '[DONE]') return;

      try {
        const event = JSON.parse(payload);
        if (event.error) throw new Error(event.error);
        if (event.delta) yield event.delta as string;
      } catch (err) {
        if (err instanceof Error && event_is_provider_error(err)) throw err;
      }
    }
  }
}

function event_is_provider_error(err: Error): boolean {
  return !err.message.startsWith('Unexpected token'); // JSON.parse failures vs real thrown errors
}
