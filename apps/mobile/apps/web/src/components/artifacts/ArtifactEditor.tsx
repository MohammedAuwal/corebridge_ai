'use client';

import { useCallback } from 'react';
import dynamic from 'next/dynamic';
import type { Artifact } from '@/domain/entities/artifact';

const MonacoEditor = dynamic(() => import('@monaco-editor/react'), { ssr: false });

interface ArtifactEditorProps {
  artifact: Artifact;
  value: string;
  onChange: (value: string) => void;
}

const LANGUAGE_MAP: Record<string, string> = {
  typescript: 'typescript',
  javascript: 'javascript',
  python: 'python',
  dart: 'dart',
  json: 'json',
  yaml: 'yaml',
  html: 'html',
  css: 'css',
  sql: 'sql',
};

export function ArtifactEditor({ artifact, value, onChange }: ArtifactEditorProps) {
  const handleChange = useCallback(
    (next: string | undefined) => onChange(next ?? ''),
    [onChange],
  );

  if (artifact.type === 'code') {
    const language = LANGUAGE_MAP[artifact.language ?? 'plaintext'] ?? 'plaintext';
    return (
      <MonacoEditor
        height="100%"
        language={language}
        value={value}
        theme="vs-dark"
        onChange={handleChange}
        options={{
          fontSize: 13,
          minimap: { enabled: false },
          scrollBeyondLastLine: false,
          wordWrap: 'on',
          padding: { top: 16 },
          fontFamily: 'var(--font-jetbrains-mono), monospace',
        }}
      />
    );
  }

  // Markdown and document artifacts use a plain textarea editor paired
  // with the live preview panel — TipTap can replace this for rich-text
  // documents once the Files/Knowledge Base module is wired in.
  return (
    <textarea
      value={value}
      onChange={(e) => onChange(e.target.value)}
      className="h-full w-full resize-none bg-surface p-4 font-mono text-sm text-text-primary outline-none"
      spellCheck={false}
    />
  );
}
