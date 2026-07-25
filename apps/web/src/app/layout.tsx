import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'CoreBridge AI',
  description: 'A premium AI workspace for chat, artifacts, and files.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      {/* Using standard system fonts via Tailwind (font-sans) instead of next/font
        to prevent network timeout crashes during Alpine/Vercel builds.
      */}
      <body className="font-sans antialiased bg-background text-text-primary">
        {children}
      </body>
    </html>
  );
}
