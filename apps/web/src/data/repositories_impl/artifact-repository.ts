import {
  addDoc,
  collection,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} from 'firebase/firestore';
import { firestore } from '../remote/firebase/firebase-config';
import type { Artifact, ArtifactVersion } from '@/domain/entities/artifact';

const ARTIFACTS_COLLECTION = 'artifacts';
const VERSIONS_SUBCOLLECTION = 'versions';

export async function saveArtifactVersion(
  artifactId: string,
  content: string,
): Promise<ArtifactVersion> {
  const versionsRef = collection(firestore, ARTIFACTS_COLLECTION, artifactId, VERSIONS_SUBCOLLECTION);

  const versionDoc = await addDoc(versionsRef, {
    content,
    createdAt: Date.now(),
  });

  await updateDoc(doc(firestore, ARTIFACTS_COLLECTION, artifactId), {
    currentVersionId: versionDoc.id,
    updatedAt: Date.now(),
  });

  return {
    versionId: versionDoc.id,
    content,
    createdAt: Date.now(),
  };
}

export async function loadArtifactVersions(artifactId: string): Promise<ArtifactVersion[]> {
  const versionsRef = collection(firestore, ARTIFACTS_COLLECTION, artifactId, VERSIONS_SUBCOLLECTION);
  const snapshot = await getDocs(query(versionsRef, orderBy('createdAt', 'desc')));

  return snapshot.docs.map((d) => ({
    versionId: d.id,
    content: d.data().content as string,
    createdAt: d.data().createdAt as number,
  }));
}

export async function createArtifact(params: {
  ownerId: string;
  conversationId: string;
  projectId?: string;
  title: string;
  type: Artifact['type'];
  language?: string;
  initialContent: string;
}): Promise<{ artifact: Artifact; version: ArtifactVersion }> {
  const now = Date.now();

  const artifactRef = await addDoc(collection(firestore, ARTIFACTS_COLLECTION), {
    ownerId: params.ownerId,
    conversationId: params.conversationId,
    projectId: params.projectId ?? null,
    title: params.title,
    type: params.type,
    language: params.language ?? null,
    currentVersionId: '',
    createdAt: now,
    updatedAt: now,
  });

  const versionsRef = collection(firestore, ARTIFACTS_COLLECTION, artifactRef.id, VERSIONS_SUBCOLLECTION);
  const versionDoc = await addDoc(versionsRef, {
    content: params.initialContent,
    createdAt: now,
  });

  await updateDoc(artifactRef, { currentVersionId: versionDoc.id });

  return {
    artifact: {
      id: artifactRef.id,
      ownerId: params.ownerId,
      conversationId: params.conversationId,
      projectId: params.projectId,
      title: params.title,
      type: params.type,
      language: params.language,
      currentVersionId: versionDoc.id,
      createdAt: now,
      updatedAt: now,
    },
    version: {
      versionId: versionDoc.id,
      content: params.initialContent,
      createdAt: now,
    },
  };
}
