import { Container } from '@/components/layout/container'
import { Header } from '@/components/layout/header'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { listNotifications } from '@/lib/api/notifications'
import { formatRelative } from '@/lib/utils/format'

export const metadata = { title: '通知 · KAIZAO' }

export default async function NotificationsPage() {
  const data = await listNotifications({ size: 50 }).catch(() => ({ list: [], total: 0, page: 1, size: 50 }))
  return (
    <>
      <Header />
      <Container className="py-10 max-w-2xl">
        <h1 className="text-3xl font-medium tracking-tight mb-6">通知</h1>
        {data.list.length === 0 ? (
          <div className="glass rounded-lg p-10 text-center text-fg-muted">暂无通知</div>
        ) : (
          <ul className="space-y-3">
            {data.list.map((n) => (
              <li key={n.id}>
                <Card><CardContent className="pt-5">
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="font-medium">{n.title}</span>
                        {!n.read && <Badge variant="outline">未读</Badge>}
                      </div>
                      {n.body && <p className="text-sm text-fg-muted line-clamp-2">{n.body}</p>}
                    </div>
                    <span className="font-mono text-xs text-fg-faint shrink-0">{formatRelative(n.created_at)}</span>
                  </div>
                </CardContent></Card>
              </li>
            ))}
          </ul>
        )}
      </Container>
    </>
  )
}
