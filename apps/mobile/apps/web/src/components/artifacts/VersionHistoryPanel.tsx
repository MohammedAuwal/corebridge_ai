'use client';

import { formatDistanceToNow } from 'date-fns';
import { useArtifactStore } from './artifactStore';
import type { ArtifactVersion } from '@/domain/entities/artifact';

interface VersionHistoryPanelProps {
  artifactId: string;
  versions: ArtifactVersion[];
  currentContent: string;
  onRestore: (version: ArtifactVersion) => void;
}

export function VersionHistoryPanel({ artifactId, versions, currentContent, onRestore }: VersionHistoryPanelProps) {
  const toggleVersionHistory = useArtifactStore((s) => s.toggleVersionHistory);

  return (
    <div className="flex h-full w-64 shrink-0 flex-col border-l border-border bg-surface">
      <div className="flex items-center justify-between border-b border-border px-3 py-2">
        <span className="text-sm font-medium text-text-primary">Version history</span>
        <button
          onClick={() => toggleVersionHistory(artifactId)}
          className="text-xs text-text-muted hover:text-text-primary"
        >
          Close
        </button>
      </div>
      <div className="flex-1 overflow-auto p-2">
        {versions.length === 0 && (
          <p className="p-2 text-xs text-text-muted">No saved versions yet.</p>
        )}
        {versions.map((version, index) => (
          <div
            key={version.versionId}
            className="mb-2 rounded-md border border-border p-2 hover:border-accent"
          >
            <div className="flex items-center justify-between">
              <span className="text-xs font-medium text-text-primary">
                {index === 0 ? 'Latest' : `Version ${versions.length - index}`}
              </span>
              <span className="text-[10px] text-text-muted">
                {formatDistanceToNow(new Date(version.createdAt), { addSuffix: true })}
              </span>
            </div>
            {index !== 0 && (
              <button
                onClick={() => onRestore(version)}
                className="mt-1 text-xs text-accent hover:text-accent-hover"
              >
                Restore this version
              </button>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
