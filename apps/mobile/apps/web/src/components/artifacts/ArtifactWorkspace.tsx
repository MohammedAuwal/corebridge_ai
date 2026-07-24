'use client';

import { useCallback, useRef, useState } from 'react';
import { Download, Copy, History, Maximize2, Minimize2 } from 'lucide-react';
import { useArtifactStore } from './artifactStore';
import { ArtifactTabs } from './ArtifactTabs';
import { ArtifactEditor } from './ArtifactEditor';
import { ArtifactPreview } from './ArtifactPreview';
import { VersionHistoryPanel } from './VersionHistoryPanel';
import { useAutosave } from './useAutosave';
import type { ArtifactVersion } from '@/domain/entities/artifact';

interface ArtifactWorkspaceProps {
  /** Persists a new version and returns its ArtifactVersion record. */
  onSaveVersion: (artifactId: string, content: string) => Promise<ArtifactVersion>;
  /** Triggers the export-artifact Edge Function and returns a download URL. */
  onExport: (artifactId: string, format: 'md' | 'pdf' | 'docx' | 'zip') => Promise<string>;
}

export function ArtifactWorkspace({ onSaveVersion, onExport }: ArtifactWorkspaceProps) {
  const openTabs = useArtifactStore((s) => s.openTabs);
  const activeTabId = useArtifactStore((s) => s.activeTabId);
  const isPanelOpen = useArtifactStore((s) => s.isPanelOpen);
  const panelWidthPct = useArtifactStore((s) => s.panelWidthPct);
  const setPanelWidthPct = useArtifactStore((s) => s.setPanelWidthPct);
  const updateDraft = useArtifactStore((s) => s.updateDraft);
  const markSaved = useArtifactStore((s) => s.markSaved);
  const setSaving = useArtifactStore((s) => s.setSaving);
  const toggleVersionHistory = useArtifactStore((s) => s.toggleVersionHistory);

  const [isFullscreen, setIsFullscreen] = useState(false);
  const [isExporting, setIsExporting] = useState(false);
  const dragStateRef = useRef<{ startX: number; startPct: number } | null>(null);

  const activeTab = openTabs.find((t) => t.artifact.id === activeTabId);

  const handleSave = useCallback(
    async (artifactId: string, content: string) => {
      setSaving(artifactId, true);
      try {
        const version = await onSaveVersion(artifactId, content);
        markSaved(artifactId, content, version);
      } catch (err) {
        setSaving(artifactId, false);
        console.error('Autosave failed:', err);
      }
    },
    [onSaveVersion, markSaved, setSaving],
  );

  useAutosave(
    activeTab?.draftContent ?? '',
    activeTab?.isDirty ?? false,
    (content) => activeTab && handleSave(activeTab.artifact.id, content),
  );

  const handleDragStart = (e: React.MouseEvent) => {
    dragStateRef.current = { startX: e.clientX, startPct: panelWidthPct };

    const handleMouseMove = (moveEvent: MouseEvent) => {
      if (!dragStateRef.current) return;
      const deltaX = dragStateRef.current.startX - moveEvent.clientX;
      const deltaPct = (deltaX / window.innerWidth) * 100;
      setPanelWidthPct(dragStateRef.current.startPct + deltaPct);
    };

    const handleMouseUp = () => {
      dragStateRef.current = null;
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };

    window.addEventListener('mousemove', handleMouseMove);
    window.addEventListener('mouseup', handleMouseUp);
  };

  const handleExportClick = async (format: 'md' | 'pdf' | 'docx' | 'zip') => {
    if (!activeTab) return;
    setIsExporting(true);
    try {
      const url = await onExport(activeTab.artifact.id, format);
      window.open(url, '_blank');
    } finally {
      setIsExporting(false);
    }
  };

  const handleCopy = () => {
    if (activeTab) navigator.clipboard.writeText(activeTab.draftContent);
  };

  const handleRestore = (version: ArtifactVersion) => {
    if (!activeTab) return;
    updateDraft(activeTab.artifact.id, version.content);
  };

  if (!isPanelOpen || !activeTab) return null;

  return (
    <div
      className="flex h-full flex-col border-l border-border bg-canvas"
      style={{ width: isFullscreen ? '100%' : `${panelWidthPct}%` }}
    >
      {/* Resize handle */}
      {!isFullscreen && (
        <div
          onMouseDown={handleDragStart}
          className="absolute -left-1 top-0 h-full w-2 cursor-col-resize hover:bg-accent/20"
        />
      )}

      <ArtifactTabs />

      {/* Toolbar */}
      <div className="flex items-center justify-between border-b border-border px-3 py-2">
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium text-text-primary">{activeTab.artifact.title}</span>
          {activeTab.isSaving && <span className="text-xs text-text-muted">Saving…</span>}
          {!activeTab.isSaving && !activeTab.isDirty && (
            <span className="text-xs text-text-muted">Saved</span>
          )}
        </div>
        <div className="flex items-center gap-1">
          <button
            onClick={() => toggleVersionHistory(activeTab.artifact.id)}
            className="rounded p-1.5 text-text-secondary hover:bg-surface-raised"
            title="Version history"
          >
            <History size={16} />
          </button>
          <button
            onClick={handleCopy}
            className="rounded p-1.5 text-text-secondary hover:bg-surface-raised"
            title="Copy content"
          >
            <Copy size={16} />
          </button>
          <div className="group relative">
            <button
              disabled={isExporting}
              className="rounded p-1.5 text-text-secondary hover:bg-surface-raised disabled:opacity-50"
              title="Export"
            >
              <Download size={16} />
            </button>
            <div className="absolute right-0 top-full z-10 hidden w-32 rounded-md border border-border bg-surface-raised shadow-raised group-hover:block">
              {(['md', 'pdf', 'docx', 'zip'] as const).map((format) => (
                <button
                  key={format}
                  onClick={() => handleExportClick(format)}
                  className="block w-full px-3 py-2 text-left text-xs text-text-secondary hover:bg-canvas"
                >
                  .{format}
                </button>
              ))}
            </div>
          </div>
          <button
            onClick={() => setIsFullscreen((v) => !v)}
            className="rounded p-1.5 text-text-secondary hover:bg-surface-raised"
            title={isFullscreen ? 'Exit fullscreen' : 'Fullscreen'}
          >
            {isFullscreen ? <Minimize2 size={16} /> : <Maximize2 size={16} />}
          </button>
        </div>
      </div>

      {/* Split editor/preview + optional version history */}
      <div className="flex flex-1 overflow-hidden">
        <div className="flex flex-1 overflow-hidden">
          <div className="w-1/2 border-r border-border">
            <ArtifactEditor
              artifact={activeTab.artifact}
              value={activeTab.draftContent}
              onChange={(content) => updateDraft(activeTab.artifact.id, content)}
            />
          </div>
          <div className="w-1/2">
            <ArtifactPreview artifact={activeTab.artifact} content={activeTab.draftContent} />
          </div>
        </div>

        {activeTab.showVersionHistory && (
          <VersionHistoryPanel
            artifactId={activeTab.artifact.id}
            versions={activeTab.versions}
            currentContent={activeTab.draftContent}
            onRestore={handleRestore}
          />
        )}
      </div>
    </div>
  );
}
