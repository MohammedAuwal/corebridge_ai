// Verifies a Firebase Auth ID token inside a Deno Edge Function using
// Google's public JWKS — no Firebase Admin SDK needed (it isn't
// Deno-compatible). This is the standard approach for verifying
// Firebase tokens outside of Node/GCP environments.

import { jwtVerify, createRemoteJWKSet } from 'https://deno.land/x/jose@v5.6.3/index.ts';

const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID')!;
const JWKS_URL = 'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

const jwks = createRemoteJWKSet(new URL(JWKS_URL));

export interface VerifiedUser {
  uid: string;
  email?: string;
}

/**
 * Verifies a Firebase ID token and returns the caller's uid, or null
 * if the token is missing, malformed, expired, or fails signature checks.
 */
export async function verifyFirebaseToken(req: Request): Promise<VerifiedUser | null> {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) return null;

  const token = authHeader.slice(7);

  try {
    const { payload } = await jwtVerify(token, jwks, {
      issuer: `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`,
      audience: FIREBASE_PROJECT_ID,
    });

    if (!payload.sub || typeof payload.sub !== 'string') return null;

    // Firebase-specific claim checks the jose library doesn't do for us.
    const authTime = payload.auth_time as number | undefined;
    if (!authTime || authTime * 1000 > Date.now()) return null;

    return {
      uid: payload.sub,
      email: typeof payload.email === 'string' ? payload.email : undefined,
    };
  } catch {
    return null;
  }
}
