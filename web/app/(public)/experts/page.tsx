import { Container } from '@/components/layout/container'
import { ExpertCard } from '@/components/cards/expert-card'
import { listExpertsServer } from '@/lib/api/market'
import { ColorHalo } from '@/components/effects/color-halo'

export const metadata = { title: '团队广场 · KAIZAO' }
export const revalidate = 30

export default async function ExpertsPage({ searchParams }: { searchParams: { page?: string } }) {
  const page = Number(searchParams.page ?? 1)
  const data = await listExpertsServer({ page, size: 24 }).catch(() => ({ list: [], total: 0, page, size: 24 }))

  return (
    <>
      <section className="relative py-16 overflow-hidden">
        <ColorHalo intensity="low" />
        <Container className="relative">
          <h1 className="text-4xl font-medium tracking-tight mb-3">团队广场</h1>
          <p className="text-fg-muted">浏览入驻的 T 级团队</p>
        </Container>
      </section>
      <Container className="pb-20">
        {data.list.length === 0 ? (
          <div className="glass rounded-lg p-12 text-center text-fg-muted">暂无团队</div>
        ) : (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-5">
            {data.list.map((e) => <ExpertCard key={e.id} e={e} />)}
          </div>
        )}
      </Container>
    </>
  )
}
