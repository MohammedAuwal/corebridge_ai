'use client';

import { useEffect, useRef } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import mermaid from 'mermaid';
import type { Artifact } from '@/domain/entities/artifact';

interface ArtifactPreviewProps {
  artifact: Artifact;
  content: string;
}

mermaid.initialize({ startOnLoad: false, theme: 'dark' });

function MermaidBlock({ code }: { code: string }) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    let cancelled = false;
    const id = `mermaid-${Math.random().toString(36).slice(2)}`;

    mermaid.render(id, code).then(({ svg }) => {
      if (!cancelled && ref.current) ref.current.innerHTML = svg;
    }).catch(() => {
      if (!cancelled && ref.current) ref.current.innerHTML = '<p class="text-red-500">Diagram render error</p>';
    });

    return () => {
      cancelled = true;
    };
  }, [code]);

  return <div ref={ref} className="my-4 flex justify-center" />;
}

export function ArtifactPreview({ artifact, content }: ArtifactPreviewProps) {
  if (artifact.type === 'diagram') {
    return (
      <div className="h-full overflow-auto bg-surface p-4">
        <MermaidBlock code={content} />
      </div>
    );
  }

  if (artifact.type === 'markdown' || artifact.type === 'document') {
    return (
      <div className="prose prose-invert h-full max-w-none overflow-auto bg-surface p-6">
        <ReactMarkdown
          remarkPlugins={[remarkGfm]}
          components={{
            code({ className, children, ...props }) {
              const match = /language-mermaid/.exec(className ?? '');
              if (match) {
                return <MermaidBlock code={String(children).trim()} />;
              }
              return (
                <code className={className} {...props}>
                  {children}
                </code>
              );
            },
          }}
        >
          {content}
        </ReactMarkdown>
      </div>
    );
  }

  // Code artifacts: read-only mirror of the editor content, useful once
  // multi-file code artifacts are supported and this becomes a diff view.
  return (
    <pre className="h-full overflow-auto bg-surface p-4 font-mono text-sm text-text-primary">
      <code>{content}</code>
    </pre>
  );
}
