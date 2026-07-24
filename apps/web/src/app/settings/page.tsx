'use client';

import { useEffect, useState } from 'react';
import { onAuthStateChanged } from 'firebase/auth';
import { auth } from '@/data/remote/firebase/firebase-config';
import {
  getUserApiKeys,
  saveUserApiKeys,
  type UserApiKeys,
} from '@/data/repositories_impl/user-settings-repository';

const PROVIDER_FIELDS: { key: keyof UserApiKeys; label: string; placeholder: string; helpUrl: string }[] = [
  { key: 'claude', label: 'Anthropic (Claude)', placeholder: 'sk-ant-...', helpUrl: 'https://console.anthropic.com/settings/keys' },
  { key: 'openai', label: 'OpenAI', placeholder: 'sk-...', helpUrl: 'https://platform.openai.com/api-keys' },
  { key: 'gemini', label: 'Google Gemini', placeholder: 'AIza...', helpUrl: 'https://aistudio.google.com/apikey' },
  { key: 'qwen', label: 'Qwen (Alibaba)', placeholder: 'sk-...', helpUrl: 'https://modelstudio.console.alibabacloud.com' },
];

export default function SettingsPage() {
  const [uid, setUid] = useState<string | null>(null);
  const [apiKeys, setApiKeys] = useState<UserApiKeys>({});
  const [isSaving, setIsSaving] = useState(false);
  const [savedMessage, setSavedMessage] = useState(false);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (!user) return;
      setUid(user.uid);
      const keys = await getUserApiKeys(user.uid);
      setApiKeys(keys);
    });
    return unsubscribe;
  }, []);

  const handleSave = async () => {
    if (!uid) return;
    setIsSaving(true);
    try {
      await saveUserApiKeys(uid, apiKeys);
      setSavedMessage(true);
      setTimeout(() => setSavedMessage(false), 2000);
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <div className="mx-auto max-w-2xl p-8">
      <h1 className="text-2xl font-semibold text-text-primary">AI Providers</h1>
      <p className="mt-1 text-sm text-text-secondary">
        Add your own API keys for each provider you want to use. Keys are stored
        privately on your account and sent only to that provider when you chat —
        CoreBridge never sees or stores them anywhere else.
      </p>

      <div className="mt-6 space-y-5">
        {PROVIDER_FIELDS.map((field) => (
          <div key={field.key}>
            <label className="mb-1 flex items-center justify-between text-sm font-medium text-text-primary">
              {field.label}
              
                href={field.helpUrl}
                target="_blank"
                rel="noreferrer"
                className="text-xs font-normal text-accent hover:text-accent-hover"
              >
                Get a key →
              </a>
            </label>
            <input
              type="password"
              value={apiKeys[field.key] ?? ''}
              onChange={(e) => setApiKeys((prev) => ({ ...prev, [field.key]: e.target.value }))}
              placeholder={field.placeholder}
              className="w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary outline-none focus:border-accent"
              autoComplete="off"
              spellCheck={false}
            />
          </div>
        ))}
      </div>

      <div className="mt-6 flex items-center gap-3">
        <button
          onClick={handleSave}
          disabled={isSaving || !uid}
          className="rounded-md bg-accent px-4 py-2 text-sm font-medium text-white hover:bg-accent-hover disabled:opacity-50"
        >
          {isSaving ? 'Saving…' : 'Save keys'}
        </button>
        {savedMessage && <span className="text-sm text-text-secondary">Saved.</span>}
      </div>
    </div>
  );
}
