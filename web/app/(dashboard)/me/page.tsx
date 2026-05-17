import Link from 'next/link'
import { Container } from '@/components/layout/container'
import { Header } from '@/components/layout/header'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { ColorHalo } from '@/components/effects/color-halo'
import { getMeServer } from '@/lib/api/users'

export const metadata = { title: '个人中心 · KAIZAO' }

export default async function MePage() {
  const me = await getMeServer()
  return (
    <>
      <Header />
      <section className="relative py-10 overflow-hidden">
        <ColorHalo intensity="low" />
        <Container className="relative flex items-center gap-5">
          <div className="w-20 h-20 rounded-pill bg-fg/5 grid place-items-center overflow-hidden">
            {me.avatar ? <img src={me.avatar} alt={me.name} className="w-full h-full object-cover" /> : <span className="text-2xl">{me.name?.[0]}</span>}
          </div>
          <div>
            <h1 className="text-3xl font-medium tracking-tight mb-2">{me.name}</h1>
            <Badge variant="glass">{me.role === 1 ? '项目方' : me.role === 2 ? '团队方' : '用户'}</Badge>
          </div>
        </Container>
      </section>
      <Container className="pb-20 max-w-2xl space-y-4">
        <Card>
          <CardContent className="pt-5">
            <h2 className="text-sm font-mono uppercase tracking-wider text-fg-muted mb-3">资料</h2>
            <dl className="grid grid-cols-2 gap-y-3 text-sm">
              <dt className="text-fg-faint">ID</dt><dd className="font-mono">{me.id}</dd>
              <dt className="text-fg-faint">姓名</dt><dd>{me.name}</dd>
              <dt className="text-fg-faint">信用</dt><dd>{me.credit_score ?? '—'}</dd>
            </dl>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-5 text-sm text-fg-muted">
            <p>资料修改、技能管理、钱包提现等功能请使用 App。</p>
            <p className="mt-2"><Link href="/dashboard" className="text-fg underline">回到控制台</Link></p>
          </CardContent>
        </Card>
      </Container>
    </>
  )
}
