import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'webapp-template',
  description: 'A production-ready webapp template',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
