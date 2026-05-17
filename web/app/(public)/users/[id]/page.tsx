import { notFound } from 'next/navigation'
import { Container } from '@/components/layout/container'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { ColorHalo } from '@/components/effects/color-halo'
import { getUserServer } from '@/lib/api/users'

export const revalidate = 60

export default async function PublicUserPage({ params }: { params: { id: string } }) {
  let user
  try { user = await getUserServer(params.id) } catch { notFound() }

  return (
    <>
      <section className="relative py-12 overflow-hidden">
        <ColorHalo intensity="low" />
        <Container className="relative flex items-center gap-5">
          <div className="w-20 h-20 rounded-pill bg-fg/5 grid place-items-center overflow-hidden">
            {user.avatar ? <img src={user.avatar} alt={user.name} className="w-full h-full object-cover" /> : <span className="text-2xl">{user.name?.[0]}</span>}
          </div>
          <div>
            <h1 className="text-3xl font-medium tracking-tight mb-2">{user.name}</h1>
            <Badge variant="glass">{user.role === 1 ? '项目方' : user.role === 2 ? '团队方' : '用户'}</Badge>
          </div>
        </Container>
      </section>
      <Container className="pb-20">
        <Card>
          <CardContent className="pt-5 text-sm text-fg-muted">
            {user.credit_score != null && <p>信用分：{user.credit_score}</p>}
            <p className="mt-3 text-xs text-fg-faint">完整信息请下载 App 查看</p>
          </CardContent>
        </Card>
      </Container>
    </>
  )
}
