import { notFound } from 'next/navigation'
import { Container } from '@/components/layout/container'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent } from '@/components/ui/card'
import { ColorHalo } from '@/components/effects/color-halo'
import { getProjectServer, getProjectPrdServer, getProjectOverviewServer } from '@/lib/api/projects'
import { formatMoney, formatRelative } from '@/lib/utils/format'
import { ProjectActions } from './actions.client'

export const revalidate = 30

export default async function ProjectDetailPage({ params }: { params: { id: string } }) {
  let detail
  try {
    detail = await getProjectServer(params.id)
  } catch {
    notFound()
  }
  const [prd, overview] = await Promise.all([
    getProjectPrdServer(params.id).catch(() => []),
    getProjectOverviewServer(params.id).catch(() => null),
  ])

  return (
    <>
      <section className="relative py-12 overflow-hidden">
        <ColorHalo intensity="low" />
        <Container className="relative">
          <div className="flex items-center gap-2 mb-4 text-xs text-fg-muted font-mono">
            <a href="/projects" className="hover:text-fg">需求广场</a>
            <span>/</span>
            <span>项目详情</span>
          </div>
          <div className="flex items-center justify-between gap-4 flex-wrap mb-3">
            <h1 className="text-3xl font-medium tracking-tight max-w-3xl">{detail.title}</h1>
            <Badge variant="outline">{detail.status}</Badge>
          </div>
          <p className="text-xs text-fg-faint font-mono">发布于 {formatRelative(detail.created_at)}</p>
        </Container>
      </section>

      <Container className="pb-20 grid md:grid-cols-3 gap-6">
        <div className="md:col-span-2 space-y-5">
          <Card>
            <CardContent className="pt-6">
              <h2 className="text-sm font-mono uppercase tracking-wider text-fg-muted mb-3">项目描述</h2>
              <p className="text-fg leading-relaxed whitespace-pre-line">{detail.description}</p>
            </CardContent>
          </Card>

          {overview && (
            <Card>
              <CardContent className="pt-6">
                <h2 className="text-sm font-mono uppercase tracking-wider text-fg-muted mb-3">概览</h2>
                <dl className="grid grid-cols-2 gap-y-3 gap-x-6 text-sm">
                  {overview.budget_cents != null && (
                    <><dt className="text-fg-faint">预算</dt><dd>{formatMoney(overview.budget_cents)}</dd></>
                  )}
                  {overview.deadline && (
                    <><dt className="text-fg-faint">期限</dt><dd>{overview.deadline}</dd></>
                  )}
                  {overview.tech_stack && (
                    <><dt className="text-fg-faint">技术栈</dt><dd>{overview.tech_stack.join(' / ')}</dd></>
                  )}
                  {overview.phases && (
                    <><dt className="text-fg-faint">阶段</dt><dd>{overview.phases.join(' → ')}</dd></>
                  )}
                </dl>
              </CardContent>
            </Card>
          )}

          {prd && prd.length > 0 && (
            <Card>
              <CardContent className="pt-6">
                <h2 className="text-sm font-mono uppercase tracking-wider text-fg-muted mb-4">PRD</h2>
                <div className="space-y-4">
                  {/* eslint-disable-next-line @typescript-eslint/no-explicit-any */}
                  {prd.map((c: any) => (
                    <article key={c.id}>
                      <h3 className="font-medium mb-1.5">{c.title}</h3>
                      <p className="text-fg-muted text-sm leading-relaxed whitespace-pre-line">{c.content}</p>
                    </article>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}
        </div>

        <aside className="space-y-4">
          {detail.owner && (
            <Card>
              <CardContent className="pt-5">
                <div className="text-xs font-mono uppercase tracking-wider text-fg-muted mb-3">项目方</div>
                <a href={`/users/${detail.owner.id}`} className="flex items-center gap-3 group">
                  <div className="w-10 h-10 rounded-pill bg-fg/5 grid place-items-center overflow-hidden">
                    {detail.owner.avatar ? <img src={detail.owner.avatar} alt={detail.owner.name} className="w-full h-full object-cover" /> : <span>{detail.owner.name?.[0]}</span>}
                  </div>
                  <span className="font-medium group-hover:underline">{detail.owner.name}</span>
                </a>
              </CardContent>
            </Card>
          )}
          <ProjectActions projectId={detail.id} />
        </aside>
      </Container>
    </>
  )
}
