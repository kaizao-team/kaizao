import Link from 'next/link'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import type { Expert } from '@/lib/api/types'

export function ExpertCard({ e }: { e: Expert }) {
  return (
    <Link href={`/experts/${e.id}`} className="block group">
      <Card className="transition-shadow group-hover:shadow-lg h-full">
        <CardContent className="pt-5">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-12 h-12 rounded-pill bg-fg/5 grid place-items-center overflow-hidden">
              {e.avatar ? <img src={e.avatar} alt={e.name} className="w-full h-full object-cover" /> : <span className="font-mono text-fg-muted">{e.name?.[0]}</span>}
            </div>
            <div className="min-w-0">
              <div className="font-medium truncate">{e.name}</div>
              {e.rate_level && <Badge variant="glass" className="mt-1 text-[10px]">{e.rate_level}</Badge>}
            </div>
          </div>
          {e.skills && e.skills.length > 0 && (
            <div className="flex flex-wrap gap-1 mb-3">
              {e.skills.slice(0, 4).map((s) => (
                <span key={s} className="text-[10px] font-mono text-fg-muted bg-fg/5 px-2 py-0.5 rounded-pill">{s}</span>
              ))}
            </div>
          )}
          <div className="text-xs text-fg-faint font-mono">{e.bid_count != null ? `参与 ${e.bid_count} 个项目` : ''}</div>
        </CardContent>
      </Card>
    </Link>
  )
}
