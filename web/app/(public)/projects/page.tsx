import { Container } from '@/components/layout/container'
import { ProjectCard } from '@/components/cards/project-card'
import { MarketFilters } from '@/components/market/market-filters'
import { listProjectsServer } from '@/lib/api/market'
import { ColorHalo } from '@/components/effects/color-halo'

export const metadata = { title: '需求广场 · KAIZAO' }
export const revalidate = 30

export default async function ProjectsPage({
  searchParams,
}: {
  searchParams: { page?: string; status?: string }
}) {
  const page = Number(searchParams.page ?? 1)
  const data = await listProjectsServer({
    page,
    size: 24,
    status: searchParams.status || undefined,
  }).catch(() => ({ list: [], total: 0, page, size: 24 }))

  return (
    <>
      <section className="relative py-16 overflow-hidden">
        <ColorHalo intensity="low" />
        <Container className="relative">
          <h1 className="text-4xl font-medium tracking-tight mb-3">需求广场</h1>
          <p className="text-fg-muted mb-8">浏览正在寻找团队的项目</p>
          <MarketFilters />
        </Container>
      </section>
      <Container className="pb-20">
        {data.list.length === 0 ? (
          <div className="glass rounded-lg p-12 text-center text-fg-muted">暂无需求</div>
        ) : (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-5">
            {data.list.map((p) => <ProjectCard key={p.id} p={p} />)}
          </div>
        )}
        {data.total > data.size && (
          <Pager page={page} total={data.total} size={data.size} />
        )}
      </Container>
    </>
  )
}

function Pager({ page, total, size }: { page: number; total: number; size: number }) {
  const pages = Math.ceil(total / size)
  return (
    <nav className="mt-10 flex justify-center gap-2 font-mono text-sm">
      {Array.from({ length: Math.min(pages, 7) }, (_, i) => i + 1).map((n) => (
        <a key={n} href={`?page=${n}`} className={`px-3 py-1.5 rounded-md ${n === page ? 'bg-fg text-bg' : 'glass'}`}>{n}</a>
      ))}
    </nav>
  )
}
