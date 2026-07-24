// Supabase Edge Function: file-process
// Called by the client right after a Supabase Storage upload of an image.
// Downloads the file server-side (using the service role key), uploads it
// to Cloudinary via a signed upload (keeping the API secret server-only),
// and returns the Cloudinary public ID + ready-to-use delivery URLs.
// The client is responsible for writing these onto the Firestore file doc —
// this function stays stateless with respect to Firestore.

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';
import { crypto } from 'https://deno.land/std@0.224.0/crypto/mod.ts';
import { encodeHex } from 'https://deno.land/std@0.224.0/encoding/hex.ts';
import { verifyFirebaseToken } from '../ai-router/verify-firebase.ts';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

interface FileProcessRequestBody {
  storagePath: string;
}

const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

async function sha1Hex(input: string): Promise<string> {
  const data = new TextEncoder().encode(input);
  const hashBuffer = await crypto.subtle.digest('SHA-1', data);
  return encodeHex(new Uint8Array(hashBuffer));
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: CORS_HEADERS });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  }

  const user = await verifyFirebaseToken(req);
  if (!user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  }

  let body: FileProcessRequestBody;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
      status: 400,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  }

  const { storagePath } = body;
  if (!storagePath) {
    return new Response(JSON.stringify({ error: 'Missing storagePath' }), {
      status: 400,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  }

  // Only process files the caller owns — storagePath is namespaced
  // `${uid}/...` at upload time (see FileRepositoryImpl.uploadFile).
  if (!storagePath.startsWith(`${user.uid}/`)) {
    return new Response(JSON.stringify({ error: 'Forbidden: not your file' }), {
      status: 403,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  }

  const { data: fileBlob, error: downloadError } = await supabaseAdmin.storage
    .from('files')
    .download(storagePath);

  if (downloadError || !fileBlob) {
    return new Response(JSON.stringify({ error: `Storage download failed: ${downloadError?.message}` }), {
      status: 500,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  }

  const cloudName = Deno.env.get('CLOUDINARY_CLOUD_NAME')!;
  const apiKey = Deno.env.get('CLOUDINARY_API_KEY')!;
  const apiSecret = Deno.env.get('CLOUDINARY_API_SECRET')!;

  const timestamp = Math.floor(Date.now() / 1000).toString();
  const folder = `corebridge/${user.uid}`;

  // Cloudinary signed uploads require signing every param sent (except
  // file/api_key/resource_type) in alphabetical order.
  const paramsToSign = `folder=${folder}&timestamp=${timestamp}${apiSecret}`;
  const signature = await sha1Hex(paramsToSign);

  const uploadForm = new FormData();
  uploadForm.append('file', fileBlob);
  uploadForm.append('api_key', apiKey);
  uploadForm.append('timestamp', timestamp);
  uploadForm.append('folder', folder);
  uploadForm.append('signature', signature);

  const cloudinaryResponse = await fetch(
    `https://api.cloudinary.com/v1_1/${cloudName}/image/upload`,
    { method: 'POST', body: uploadForm },
  );

  if (!cloudinaryResponse.ok) {
    const errText = await cloudinaryResponse.text();
    return new Response(JSON.stringify({ error: `Cloudinary upload failed: ${errText}` }), {
      status: 500,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  }

  const cloudinaryData = await cloudinaryResponse.json();
  const publicId: string = cloudinaryData.public_id;

  return new Response(
    JSON.stringify({
      cloudinaryId: publicId,
      thumbnailUrl: `https://res.cloudinary.com/${cloudName}/image/upload/w_400,q_auto,f_auto/${publicId}`,
      optimizedUrl: `https://res.cloudinary.com/${cloudName}/image/upload/q_auto,f_auto/${publicId}`,
    }),
    { status: 200, headers: { ...CORS_HEADERS, 'content-type': 'application/json' } },
  );
});
