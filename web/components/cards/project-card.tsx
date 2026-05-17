import React from 'react'
import Link from 'next/link'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { formatMoney, formatRelative } from '@/lib/utils/format'
import type { Project } from '@/lib/api/types'

export function ProjectCard({ p }: { p: Project }) {
  return (
    <Link href={`/projects/${p.id}`} className="block group">
      <Card className="transition-shadow group-hover:shadow-lg h-full">
        <CardContent className="pt-5">
          <div className="flex items-start justify-between gap-3 mb-2">
            <h3 className="font-medium text-base line-clamp-2 group-hover:text-fg">{p.title}</h3>
            <Badge variant="outline" className="shrink-0">{p.status}</Badge>
          </div>
          <p className="text-fg-muted text-sm line-clamp-2 mb-4">{p.description}</p>
          <div className="flex items-center justify-between text-xs text-fg-faint font-mono">
            <span>{p.budget_cents ? formatMoney(p.budget_cents) : '面议'}</span>
            <span>{formatRelative(p.created_at)}</span>
          </div>
          {p.tags && p.tags.length > 0 && (
            <div className="mt-3 flex flex-wrap gap-1">
              {p.tags.slice(0, 3).map((t) => (
                <span key={t} className="text-[10px] font-mono text-fg-muted bg-fg/5 px-2 py-0.5 rounded-pill">{t}</span>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </Link>
  )
}
