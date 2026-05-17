import Link from 'next/link'
import { Container } from '@/components/layout/container'
import { Button } from '@/components/ui/button'
import { ColorHalo } from '@/components/effects/color-halo'

export default function NotFound() {
  return (
    <main className="relative min-h-screen grid place-items-center overflow-hidden">
      <ColorHalo intensity="low" />
      <Container className="relative text-center">
        <div className="font-mono text-fg-faint text-xs mb-4">404</div>
        <h1 className="text-4xl font-medium tracking-tight mb-3">页面不存在</h1>
        <p className="text-fg-muted mb-8">你访问的页面可能被移动或删除</p>
        <Button asChild><Link href="/">回到首页</Link></Button>
      </Container>
    </main>
  )
}
