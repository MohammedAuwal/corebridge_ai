'use client';

import { ArtifactWorkspace } from '@/components/artifacts/ArtifactWorkspace';
import { useArtifactStore } from '@/components/artifacts/artifactStore';
import { saveArtifactVersion } from '@/data/repositories_impl/artifact-repository';
import { auth } from '@/data/remote/firebase/firebase-config';
import { SUPABASE_FUNCTIONS_URL } from '@/data/remote/supabase/supabase-config';

export default function WorkspacePage() {
  const isPanelOpen = useArtifactStore((s) => s.isPanelOpen);
  const openTabs = useArtifactStore((s) => s.openTabs);
  const activeTabId = useArtifactStore((s) => s.activeTabId);

  const handleSaveVersion = async (artifactId: string, content: string) => {
    return saveArtifactVersion(artifactId, content);
  };

  const handleExport = async (artifactId: string, format: 'md' | 'pdf' | 'docx' | 'zip') => {
    const tab = openTabs.find((t) => t.artifact.id === artifactId);
    const idToken = await auth.currentUser?.getIdToken();

    if (!tab || !idToken) {
      throw new Error('No active artifact or not signed in.');
    }

    const response = await fetch(`${SUPABASE_FUNCTIONS_URL}/export-artifact`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${idToken}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        artifactId,
        title: tab.artifact.title,
        content: tab.draftContent,
        format,
      }),
    });

    if (!response.ok) {
      const errBody = await response.json().catch(() => ({ error: 'Unknown export error' }));
      throw new Error(errBody.error ?? 'Export failed');
    }

    const { url } = await response.json();
    return url as string;
  };

  return (
    <div className="flex h-screen">
      <div className="flex-1 overflow-auto p-6">
        <p className="text-text-secondary">Chat panel renders here (40% width once an artifact opens).</p>
      </div>
      {isPanelOpen && activeTabId && (
        <ArtifactWorkspace onSaveVersion={handleSaveVersion} onExport={handleExport} />
      )}
    </div>
  );
}
