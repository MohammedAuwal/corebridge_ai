export type ArtifactType = 'code' | 'markdown' | 'document' | 'chart' | 'diagram';

export interface ArtifactVersion {
  versionId: string;
  content: string;
  createdAt: number;
}

export interface Artifact {
  id: string;
  ownerId: string;
  conversationId: string;
  projectId?: string;
  title: string;
  type: ArtifactType;
  language?: string; // for code artifacts, e.g. 'typescript', 'python'
  currentVersionId: string;
  createdAt: number;
  updatedAt: number;
}
