// Supabase Edge Function: ai-router
// Streams chat completions from Qwen, Claude, OpenAI, or Gemini.
// API keys are BYOK (bring your own key) — sent by the client per request,
// sourced from the user's own Settings, never stored as a Supabase secret.
// Auth is verified against Firebase ID tokens.

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { verifyFirebaseToken } from './verify-firebase.ts';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

interface ChatMessage {
  role: string;
  content: string;
}

interface RequestBody {
  provider: 'claude' | 'openai' | 'gemini' | 'qwen';
  model: string;
  messages: ChatMessage[];
  apiKey: string; // the user's own key for the chosen provider
}

function sseChunk(delta: string): string {
  return `data: ${JSON.stringify({ delta })}\n\n`;
}

function sseDone(): string {
  return `data: [DONE]\n\n`;
}

function sseError(message: string): string {
  return `data: ${JSON.stringify({ error: message })}\n\n`;
}

async function streamClaude(
  apiKey: string,
  model: string,
  messages: ChatMessage[],
  controller: ReadableStreamDefaultController,
) {
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model,
      max_tokens: 4096,
      stream: true,
      messages: messages.filter((m) => m.role !== 'system'),
    }),
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`Claude API error (${response.status}): ${errText}`);
  }

  const reader = response.body!.getReader();
  const decoder = new TextDecoder();
  const encoder = new TextEncoder();
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
      if (!payload) continue;

      try {
        const event = JSON.parse(payload);
        if (event.type === 'content_block_delta' && event.delta?.text) {
          controller.enqueue(encoder.encode(sseChunk(event.delta.text)));
        }
      } catch {
        continue;
      }
    }
  }
}

async function streamOpenAI(
  apiKey: string,
  model: string,
  messages: ChatMessage[],
  controller: ReadableStreamDefaultController,
) {
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({ model, stream: true, messages }),
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`OpenAI API error (${response.status}): ${errText}`);
  }

  const reader = response.body!.getReader();
  const decoder = new TextDecoder();
  const encoder = new TextEncoder();
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
      if (payload === '[DONE]') continue;

      try {
        const event = JSON.parse(payload);
        const delta = event.choices?.[0]?.delta?.content;
        if (delta) controller.enqueue(encoder.encode(sseChunk(delta)));
      } catch {
        continue;
      }
    }
  }
}

async function streamGemini(
  apiKey: string,
  model: string,
  messages: ChatMessage[],
  controller: ReadableStreamDefaultController,
) {
  const contents = messages
    .filter((m) => m.role !== 'system')
    .map((m) => ({
      role: m.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: m.content }],
    }));

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:streamGenerateContent?key=${apiKey}&alt=sse`,
    {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ contents }),
    },
  );

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`Gemini API error (${response.status}): ${errText}`);
  }

  const reader = response.body!.getReader();
  const decoder = new TextDecoder();
  const encoder = new TextEncoder();
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
      if (!payload) continue;

      try {
        const event = JSON.parse(payload);
        const delta = event.candidates?.[0]?.content?.parts?.[0]?.text;
        if (delta) controller.enqueue(encoder.encode(sseChunk(delta)));
      } catch {
        continue;
      }
    }
  }
}

async function streamQwen(
  apiKey: string,
  model: string,
  messages: ChatMessage[],
  controller: ReadableStreamDefaultController,
) {
  const response = await fetch(
    'https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions',
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({ model, stream: true, messages }),
    },
  );

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`Qwen API error (${response.status}): ${errText}`);
  }

  const reader = response.body!.getReader();
  const decoder = new TextDecoder();
  const encoder = new TextEncoder();
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
      if (payload === '[DONE]') continue;

      try {
        const event = JSON.parse(payload);
        const delta = event.choices?.[0]?.delta?.content;
        if (delta) controller.enqueue(encoder.encode(sseChunk(delta)));
      } catch {
        continue;
      }
    }
  }
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: CORS_HEADERS });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  }

  const user = await verifyFirebaseToken(req);
  if (!user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
      status: 400,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  }

  const { provider, model, messages, apiKey } = body;

  if (!provider || !model || !Array.isArray(messages)) {
    return new Response(JSON.stringify({ error: 'Missing provider, model, or messages' }), {
      status: 400,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  }

  if (!apiKey || apiKey.trim().length === 0) {
    return new Response(
      JSON.stringify({
        error: `No API key provided for ${provider}. Add one in Settings → AI Providers.`,
      }),
      { status: 400, headers: { ...CORS_HEADERS, 'content-type': 'application/json' } },
    );
  }

  const stream = new ReadableStream({
    async start(controller) {
      const encoder = new TextEncoder();
      try {
        switch (provider) {
          case 'claude':
            await streamClaude(apiKey, model, messages, controller);
            break;
          case 'openai':
            await streamOpenAI(apiKey, model, messages, controller);
            break;
          case 'gemini':
            await streamGemini(apiKey, model, messages, controller);
            break;
          case 'qwen':
            await streamQwen(apiKey, model, messages, controller);
            break;
          default:
            controller.enqueue(encoder.encode(sseError(`Unknown provider: ${provider}`)));
        }
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Unknown streaming error';
        controller.enqueue(encoder.encode(sseError(message)));
      } finally {
        controller.enqueue(encoder.encode(sseDone()));
        controller.close();
      }
    },
  });

  return new Response(stream, {
    headers: {
      ...CORS_HEADERS,
      'content-type': 'text/event-stream',
      'cache-control': 'no-cache',
      connection: 'keep-alive',
    },
  });
});
