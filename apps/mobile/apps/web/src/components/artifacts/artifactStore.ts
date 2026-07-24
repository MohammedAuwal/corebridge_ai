import { create } from 'zustand';
import type { Artifact, ArtifactVersion } from '@/domain/entities/artifact';

export interface OpenArtifactTab {
  artifact: Artifact;
  draftContent: string;
  savedContent: string;
  versions: ArtifactVersion[];
  isDirty: boolean;
  isSaving: boolean;
  showVersionHistory: boolean;
}

interface ArtifactStoreState {
  openTabs: OpenArtifactTab[];
  activeTabId: string | null;
  isPanelOpen: boolean;
  panelWidthPct: number; // percentage of viewport the artifact panel takes

  openArtifact: (artifact: Artifact, content: string, versions: ArtifactVersion[]) => void;
  closeTab: (artifactId: string) => void;
  setActiveTab: (artifactId: string) => void;
  updateDraft: (artifactId: string, content: string) => void;
  markSaved: (artifactId: string, savedContent: string, newVersion: ArtifactVersion) => void;
  setSaving: (artifactId: string, isSaving: boolean) => void;
  toggleVersionHistory: (artifactId: string) => void;
  setPanelWidthPct: (pct: number) => void;
  closeAll: () => void;
}

export const useArtifactStore = create<ArtifactStoreState>((set, get) => ({
  openTabs: [],
  activeTabId: null,
  isPanelOpen: false,
  panelWidthPct: 55,

  openArtifact: (artifact, content, versions) => {
    const existing = get().openTabs.find((t) => t.artifact.id === artifact.id);
    if (existing) {
      set({ activeTabId: artifact.id, isPanelOpen: true });
      return;
    }
    set((state) => ({
      openTabs: [
        ...state.openTabs,
        {
          artifact,
          draftContent: content,
          savedContent: content,
          versions,
          isDirty: false,
          isSaving: false,
          showVersionHistory: false,
        },
      ],
      activeTabId: artifact.id,
      isPanelOpen: true,
    }));
  },

  closeTab: (artifactId) => {
    set((state) => {
      const remaining = state.openTabs.filter((t) => t.artifact.id !== artifactId);
      const wasActive = state.activeTabId === artifactId;
      return {
        openTabs: remaining,
        activeTabId: wasActive ? (remaining[remaining.length - 1]?.artifact.id ?? null) : state.activeTabId,
        isPanelOpen: remaining.length > 0,
      };
    });
  },

  setActiveTab: (artifactId) => set({ activeTabId: artifactId }),

  updateDraft: (artifactId, content) => {
    set((state) => ({
      openTabs: state.openTabs.map((t) =>
        t.artifact.id === artifactId
          ? { ...t, draftContent: content, isDirty: content !== t.savedContent }
          : t,
      ),
    }));
  },

  markSaved: (artifactId, savedContent, newVersion) => {
    set((state) => ({
      openTabs: state.openTabs.map((t) =>
        t.artifact.id === artifactId
          ? {
              ...t,
              savedContent,
              isDirty: false,
              isSaving: false,
              versions: [newVersion, ...t.versions],
            }
          : t,
      ),
    }));
  },

  setSaving: (artifactId, isSaving) => {
    set((state) => ({
      openTabs: state.openTabs.map((t) => (t.artifact.id === artifactId ? { ...t, isSaving } : t)),
    }));
  },

  toggleVersionHistory: (artifactId) => {
    set((state) => ({
      openTabs: state.openTabs.map((t) =>
        t.artifact.id === artifactId ? { ...t, showVersionHistory: !t.showVersionHistory } : t,
      ),
    }));
  },

  setPanelWidthPct: (pct) => set({ panelWidthPct: Math.min(80, Math.max(30, pct)) }),

  closeAll: () => set({ openTabs: [], activeTabId: null, isPanelOpen: false }),
}));
