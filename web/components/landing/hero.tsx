import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { ColorHalo } from '@/components/effects/color-halo'
import { Container } from '@/components/layout/container'

export function Hero() {
  return (
    <section className="relative overflow-hidden pt-24 pb-28">
      <ColorHalo intensity="high" />
      <Container className="relative">
        <Badge variant="glass" className="mb-6">
          <span className="inline-block w-1.5 h-1.5 rounded-full bg-gradient-to-br from-pink-400 to-blue-400" />
          POWERED BY AI · v2
        </Badge>
        <h1 className="text-5xl md:text-6xl font-medium tracking-tight leading-[1.04] max-w-3xl">
          把模糊的需求<br />变成<span className="text-gradient-hero">可交付的项目</span>
        </h1>
        <p className="mt-6 text-fg-muted max-w-xl text-base leading-relaxed">
          AI Agent 拆解需求、撮合 T1–T10 分级团队、全流程透明协同。
          一句话起步，从 PRD 到验收一站完成。
        </p>
        <div className="mt-10 flex flex-wrap gap-3">
          <Button asChild size="lg"><Link href="/auth/register?role=1">我是项目方 · 发起项目</Link></Button>
          <Button asChild size="lg" variant="glass"><Link href="/auth/register?role=2">我是团队方 · 接需求</Link></Button>
        </div>
      </Container>
    </section>
  )
}
