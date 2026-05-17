import Link from 'next/link'
import { Container } from '@/components/layout/container'
import { Header } from '@/components/layout/header'
import { ProjectCard } from '@/components/cards/project-card'
import { listMyProjects } from '@/lib/api/projects'

export const metadata = { title: '我的项目 · KAIZAO' }

export default async function MyProjectsPage() {
  const data = await listMyProjects({ size: 50 }).catch(() => ({ list: [], total: 0, page: 1, size: 50 }))
  return (
    <>
      <Header />
      <Container className="py-10">
        <h1 className="text-3xl font-medium tracking-tight mb-6">我的项目</h1>
        {data.list.length === 0 ? (
          <div className="glass rounded-lg p-10 text-center text-fg-muted">
            还没有项目。<br />
            <Link href="/" className="text-fg underline mt-2 inline-block">在 App 中发布需求</Link>
          </div>
        ) : (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-5">
            {data.list.map((p) => <ProjectCard key={p.id} p={p} />)}
          </div>
        )}
      </Container>
    </>
  )
}
