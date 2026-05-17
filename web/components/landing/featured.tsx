import { Container } from '@/components/layout/container'
import { ProjectCard } from '@/components/cards/project-card'
import { ExpertCard } from '@/components/cards/expert-card'
import { listProjectsServer, listExpertsServer } from '@/lib/api/market'

export async function Featured() {
  const [projects, experts] = await Promise.all([
    listProjectsServer({ size: 6 }).catch(() => ({ list: [], total: 0, page: 1, size: 6 })),
    listExpertsServer({ size: 6 }).catch(() => ({ list: [], total: 0, page: 1, size: 6 })),
  ])

  return (
    <section className="py-20">
      <Container>
        <div className="flex items-baseline justify-between mb-8">
          <h2 className="text-3xl font-medium tracking-tight">最新需求</h2>
          <a href="/projects" className="text-sm text-fg-muted hover:text-fg">查看全部 →</a>
        </div>
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-5 mb-16">
          {projects.list.map((p) => <ProjectCard key={p.id} p={p} />)}
        </div>

        <div className="flex items-baseline justify-between mb-8">
          <h2 className="text-3xl font-medium tracking-tight">精选团队</h2>
          <a href="/experts" className="text-sm text-fg-muted hover:text-fg">查看全部 →</a>
        </div>
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-5">
          {experts.list.map((e) => <ExpertCard key={e.id} e={e} />)}
        </div>
      </Container>
    </section>
  )
}
