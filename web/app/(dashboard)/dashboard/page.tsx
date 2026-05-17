import Link from 'next/link'
import { Container } from '@/components/layout/container'
import { Header } from '@/components/layout/header'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { ColorHalo } from '@/components/effects/color-halo'
import { getServerSession } from '@/lib/auth/session'
import { getDemanderHome, getExpertHome } from '@/lib/api/home'
import { LogoutButton } from './logout-button.client'

export const metadata = { title: '控制台 · KAIZAO' }

export default async function DashboardPage() {
  const { role } = getServerSession()
  const isDemander = role === 1
  const data = isDemander
    ? await getDemanderHome().catch(() => null)
    : await getExpertHome().catch(() => null)

  return (
    <>
      <Header />
      <section className="relative py-10 overflow-hidden">
        <ColorHalo intensity="low" />
        <Container className="relative flex items-center justify-between flex-wrap gap-4">
          <div>
            <p className="text-xs font-mono uppercase tracking-wider text-fg-muted mb-2">控制台</p>
            <h1 className="text-3xl font-medium tracking-tight">
              {isDemander ? '项目方主页' : '团队方主页'}
            </h1>
          </div>
          <div className="flex gap-2">
            <Button asChild variant="glass" size="sm"><Link href="/me">个人中心</Link></Button>
            <LogoutButton />
          </div>
        </Container>
      </section>

      <Container className="pb-20 grid md:grid-cols-2 gap-5">
        <Card>
          <CardContent className="pt-6">
            <div className="text-xs font-mono uppercase tracking-wider text-fg-muted mb-3">
              {isDemander ? '进行中的项目' : '进行中的投标'}
            </div>
            {(() => {
              const list = isDemander ? (data as any)?.ongoing_projects : (data as any)?.ongoing_bids
              if (!list || list.length === 0) {
                return <p className="text-sm text-fg-muted">暂无内容</p>
              }
              return (
                <ul className="space-y-2">
                  {list.map((it: any) => (
                    <li key={it.id ?? it.project_id} className="flex items-center justify-between text-sm">
                      <span>{it.title ?? it.project_title}</span>
                      <Badge variant="outline">{it.status}</Badge>
                    </li>
                  ))}
                </ul>
              )
            })()}
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="text-xs font-mono uppercase tracking-wider text-fg-muted mb-3">快捷入口</div>
            <div className="space-y-2 text-sm">
              <Link href="/me/projects" className="block hover:text-fg-muted">我的项目</Link>
              <Link href="/me/notifications" className="block hover:text-fg-muted">通知</Link>
              <Link href="/me" className="block hover:text-fg-muted">个人资料</Link>
            </div>
            <p className="mt-5 text-xs text-fg-faint">深度操作（发布需求、投标、IM 等）请使用 App</p>
          </CardContent>
        </Card>
      </Container>
    </>
  )
}
