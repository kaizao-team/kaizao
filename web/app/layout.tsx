import './globals.css'
import type { Metadata } from 'next'
import { GeistSans } from 'geist/font/sans'
import { GeistMono } from 'geist/font/mono'
import { AuthProvider } from '@/lib/auth/use-auth'
import { getServerSession } from '@/lib/auth/session'

export const metadata: Metadata = {
  title: 'KAIZAO · AI 驱动的软件需求撮合平台',
  description: '把模糊的需求变成可交付的项目。AI Agent 拆解需求、撮合分级团队、协同交付。',
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000'),
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const session = getServerSession()
  return (
    <html lang="zh-CN" className={`${GeistSans.variable} ${GeistMono.variable}`}>
      <body className="font-sans">
        <AuthProvider value={session}>{children}</AuthProvider>
      </body>
    </html>
  )
}
