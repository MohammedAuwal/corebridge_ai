import { doc, getDoc, setDoc } from 'firebase/firestore';
import { firestore } from '../remote/firebase/firebase-config';

export interface UserApiKeys {
  claude?: string;
  openai?: string;
  gemini?: string;
  qwen?: string;
}

const USERS_COLLECTION = 'users';

export async function getUserApiKeys(uid: string): Promise<UserApiKeys> {
  const snap = await getDoc(doc(firestore, USERS_COLLECTION, uid));
  if (!snap.exists()) return {};
  return (snap.data().apiKeys as UserApiKeys) ?? {};
}

export async function saveUserApiKeys(uid: string, apiKeys: UserApiKeys): Promise<void> {
  await setDoc(
    doc(firestore, USERS_COLLECTION, uid),
    { apiKeys, updatedAt: Date.now() },
    { merge: true },
  );
}
