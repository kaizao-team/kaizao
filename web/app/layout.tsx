import './globals.css'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'KAIZAO · AI 驱动的软件需求撮合平台',
  description: '把模糊的需求变成可交付的项目。AI Agent 拆解需求、撮合分级团队、协同交付。',
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000'),
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="zh-CN">
      <body>{children}</body>
    </html>
  )
}
