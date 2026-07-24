'use client';

import { X, Circle } from 'lucide-react';
import clsx from 'clsx';
import { useArtifactStore } from './artifactStore';

export function ArtifactTabs() {
  const openTabs = useArtifactStore((s) => s.openTabs);
  const activeTabId = useArtifactStore((s) => s.activeTabId);
  const setActiveTab = useArtifactStore((s) => s.setActiveTab);
  const closeTab = useArtifactStore((s) => s.closeTab);

  if (openTabs.length === 0) return null;

  return (
    <div className="flex items-center gap-1 overflow-x-auto border-b border-border bg-surface px-2">
      {openTabs.map((tab) => {
        const isActive = tab.artifact.id === activeTabId;
        return (
          <button
            key={tab.artifact.id}
            onClick={() => setActiveTab(tab.artifact.id)}
            className={clsx(
              'group flex items-center gap-2 rounded-t-md px-3 py-2 text-sm transition-colors',
              isActive
                ? 'bg-canvas text-text-primary'
                : 'text-text-secondary hover:bg-canvas/50',
            )}
          >
            {tab.isDirty && <Circle size={6} className="fill-accent text-accent" />}
            <span className="max-w-[160px] truncate">{tab.artifact.title}</span>
            <span
              role="button"
              tabIndex={-1}
              onClick={(e) => {
                e.stopPropagation();
                closeTab(tab.artifact.id);
              }}
              className="rounded p-0.5 opacity-0 hover:bg-border group-hover:opacity-100"
            >
              <X size={12} />
            </span>
          </button>
        );
      })}
    </div>
  );
}
