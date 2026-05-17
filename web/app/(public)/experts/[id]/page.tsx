import { notFound } from 'next/navigation'
import { Container } from '@/components/layout/container'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { ColorHalo } from '@/components/effects/color-halo'
import { getUserServer, getUserSkillsServer, getUserPortfoliosServer, getUserReviewsServer } from '@/lib/api/users'
import { formatDate } from '@/lib/utils/format'
import { ExpertActions } from './actions.client'

export const revalidate = 60

export default async function ExpertProfilePage({ params }: { params: { id: string } }) {
  let user
  try { user = await getUserServer(params.id) } catch { notFound() }
  const [skills, portfolios, reviews] = await Promise.all([
    getUserSkillsServer(params.id).catch(() => []),
    getUserPortfoliosServer(params.id).catch(() => []),
    getUserReviewsServer(params.id).catch(() => []),
  ])

  return (
    <>
      <section className="relative py-12 overflow-hidden">
        <ColorHalo intensity="low" />
        <Container className="relative flex items-center gap-5 flex-wrap">
          <div className="w-20 h-20 rounded-pill bg-fg/5 grid place-items-center overflow-hidden">
            {user.avatar ? <img src={user.avatar} alt={user.name} className="w-full h-full object-cover" /> : <span className="text-2xl">{user.name?.[0]}</span>}
          </div>
          <div className="min-w-0 flex-1">
            <h1 className="text-3xl font-medium tracking-tight mb-2">{user.name}</h1>
            <div className="flex flex-wrap items-center gap-2 text-sm text-fg-muted">
              {user.credit_score != null && <Badge variant="glass">信用 {user.credit_score}</Badge>}
              {skills && skills.length > 0 && <span>·</span>}
              {skills?.slice(0, 4).map((s) => (
                <span key={s} className="text-[11px] font-mono text-fg-muted">#{s}</span>
              ))}
            </div>
          </div>
          <ExpertActions />
        </Container>
      </section>

      <Container className="pb-20 grid md:grid-cols-3 gap-6">
        <div className="md:col-span-2 space-y-5">
          {portfolios && portfolios.length > 0 && (
            <Card><CardContent className="pt-6">
              <h2 className="text-sm font-mono uppercase tracking-wider text-fg-muted mb-4">作品</h2>
              <div className="grid sm:grid-cols-2 gap-4">
                {/* eslint-disable-next-line @typescript-eslint/no-explicit-any */}
                {portfolios.map((p: any) => (
                  <div key={p.id} className="rounded-lg overflow-hidden border border-fg/5">
                    {p.cover && <img src={p.cover} alt={p.title} className="aspect-video w-full object-cover" />}
                    <div className="p-3 text-sm font-medium">{p.title}</div>
                  </div>
                ))}
              </div>
            </CardContent></Card>
          )}
          {reviews && reviews.length > 0 && (
            <Card><CardContent className="pt-6">
              <h2 className="text-sm font-mono uppercase tracking-wider text-fg-muted mb-4">评价</h2>
              <ul className="divide-y divide-fg/5">
                {/* eslint-disable-next-line @typescript-eslint/no-explicit-any */}
                {reviews.map((r: any) => (
                  <li key={r.id} className="py-3">
                    <div className="flex items-center justify-between mb-1">
                      <span className="font-mono text-xs text-fg-faint">{formatDate(r.created_at)}</span>
                      <span className="font-mono text-sm">{r.score}/5</span>
                    </div>
                    <p className="text-sm text-fg-muted leading-relaxed">{r.content}</p>
                  </li>
                ))}
              </ul>
            </CardContent></Card>
          )}
        </div>
        <aside>
          {skills && skills.length > 0 && (
            <Card><CardContent className="pt-5">
              <h2 className="text-xs font-mono uppercase tracking-wider text-fg-muted mb-3">技能</h2>
              <div className="flex flex-wrap gap-1.5">
                {skills.map((s) => (
                  <span key={s} className="text-[11px] font-mono text-fg-muted bg-fg/5 px-2 py-0.5 rounded-pill">{s}</span>
                ))}
              </div>
            </CardContent></Card>
          )}
        </aside>
      </Container>
    </>
  )
}
