// Supabase Edge Function: export-artifact
// Accepts artifact title/content/format directly from the authenticated
// client (the client already has the content in the editor — no need to
// re-fetch from Firestore here), converts it to the requested file format,
// uploads the result to Supabase Storage under a per-user temp path, and
// returns a short-lived signed download URL.

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';
import { PDFDocument, StandardFonts, rgb } from 'https://esm.sh/pdf-lib@1.17.1';
import { Document, Packer, Paragraph, TextRun } from 'https://esm.sh/docx@8.5.0';
import { BlobWriter, BlobReader, ZipWriter } from 'https://esm.sh/@zip.js/zip.js@2.7.44';
import { verifyFirebaseToken } from '../ai-router/verify-firebase.ts';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

type ExportFormat = 'md' | 'pdf' | 'docx' | 'zip';

interface ExportRequestBody {
  artifactId: string;
  title: string;
  content: string;
  format: ExportFormat;
}

const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

async function buildMarkdown(content: string): Promise<Uint8Array> {
  return new TextEncoder().encode(content);
}

async function buildPdf(title: string, content: string): Promise<Uint8Array> {
  const pdfDoc = await PDFDocument.create();
  const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
  const boldFont = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

  const pageWidth = 612;
  const pageHeight = 792;
  const margin = 56;
  const fontSize = 11;
  const lineHeight = fontSize * 1.4;
  const maxWidth = pageWidth - margin * 2;

  let page = pdfDoc.addPage([pageWidth, pageHeight]);
  let cursorY = pageHeight - margin;

  page.drawText(title, {
    x: margin,
    y: cursorY,
    size: 18,
    font: boldFont,
    color: rgb(0.11, 0.11, 0.11),
  });
  cursorY -= 32;

  const wrapLine = (line: string): string[] => {
    const words = line.split(' ');
    const wrapped: string[] = [];
    let current = '';

    for (const word of words) {
      const candidate = current ? `${current} ${word}` : word;
      const width = font.widthOfTextAtSize(candidate, fontSize);
      if (width > maxWidth && current) {
        wrapped.push(current);
        current = word;
      } else {
        current = candidate;
      }
    }
    if (current) wrapped.push(current);
    return wrapped.length > 0 ? wrapped : [''];
  };

  const rawLines = content.split('\n');

  for (const rawLine of rawLines) {
    const wrappedLines = wrapLine(rawLine);

    for (const line of wrappedLines) {
      if (cursorY < margin) {
        page = pdfDoc.addPage([pageWidth, pageHeight]);
        cursorY = pageHeight - margin;
      }
      page.drawText(line, {
        x: margin,
        y: cursorY,
        size: fontSize,
        font,
        color: rgb(0.15, 0.15, 0.15),
      });
      cursorY -= lineHeight;
    }
  }

  return pdfDoc.save();
}

async function buildDocx(title: string, content: string): Promise<Uint8Array> {
  const paragraphs = [
    new Paragraph({
      children: [new TextRun({ text: title, bold: true, size: 32 })],
    }),
    new Paragraph({ text: '' }),
    ...content.split('\n').map(
      (line) =>
        new Paragraph({
          children: [new TextRun({ text: line, size: 22 })],
        }),
    ),
  ];

  const doc = new Document({
    sections: [{ properties: {}, children: paragraphs }],
  });

  const blob = await Packer.toBlob(doc);
  return new Uint8Array(await blob.arrayBuffer());
}

async function buildZip(title: string, content: string): Promise<Uint8Array> {
  const zipWriter = new ZipWriter(new BlobWriter('application/zip'));
  await zipWriter.add(`${title}.md`, new BlobReader(new Blob([content])));
  const zipBlob = await zipWriter.close();
  return new Uint8Array(await zipBlob.arrayBuffer());
}

function contentTypeFor(format: ExportFormat): string {
  switch (format) {
    case 'md':
      return 'text/markdown';
    case 'pdf':
      return 'application/pdf';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'zip':
      return 'application/zip';
  }
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

  let body: ExportRequestBody;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
      status: 400,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  }

  const { artifactId, title, content, format } = body;

  if (!artifactId || !title || content === undefined || !format) {
    return new Response(JSON.stringify({ error: 'Missing artifactId, title, content, or format' }), {
      status: 400,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  }

  let fileBytes: Uint8Array;
  try {
    switch (format) {
      case 'md':
        fileBytes = await buildMarkdown(content);
        break;
      case 'pdf':
        fileBytes = await buildPdf(title, content);
        break;
      case 'docx':
        fileBytes = await buildDocx(title, content);
        break;
      case 'zip':
        fileBytes = await buildZip(title, content);
        break;
      default:
        return new Response(JSON.stringify({ error: `Unsupported format: ${format}` }), {
          status: 400,
          headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
        });
    }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Unknown export error';
    return new Response(JSON.stringify({ error: `Export generation failed: ${message}` }), {
      status: 500,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  }

  const safeTitle = title.replace(/[^a-zA-Z0-9-_]/g, '_');
  const storagePath = `${user.uid}/exports/${artifactId}-${Date.now()}-${safeTitle}.${format}`;

  const { error: uploadError } = await supabaseAdmin.storage
    .from('files')
    .upload(storagePath, fileBytes, {
      contentType: contentTypeFor(format),
      upsert: true,
    });

  if (uploadError) {
    return new Response(JSON.stringify({ error: `Storage upload failed: ${uploadError.message}` }), {
      status: 500,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  }

  const { data: signedUrlData, error: signedUrlError } = await supabaseAdmin.storage
    .from('files')
    .createSignedUrl(storagePath, 3600);

  if (signedUrlError || !signedUrlData) {
    return new Response(JSON.stringify({ error: 'Failed to create signed URL' }), {
      status: 500,
      headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
    });
  }

  return new Response(JSON.stringify({ url: signedUrlData.signedUrl }), {
    status: 200,
    headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
  });
});
