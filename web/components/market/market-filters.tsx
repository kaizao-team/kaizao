'use client'
import { Badge } from '@/components/ui/badge'
import { useRouter, useSearchParams } from 'next/navigation'

const STATUSES = [
  { label: '全部', value: '' },
  { label: '招标中', value: 'open' },
  { label: '已截止', value: 'closed' },
]

export function MarketFilters() {
  const router = useRouter()
  const sp = useSearchParams()
  const current = sp.get('status') ?? ''

  const setStatus = (v: string) => {
    const params = new URLSearchParams(sp.toString())
    if (v) params.set('status', v); else params.delete('status')
    router.push(`?${params.toString()}`)
  }

  return (
    <div className="flex flex-wrap gap-2">
      {STATUSES.map((s) => (
        <button key={s.value} onClick={() => setStatus(s.value)}>
          <Badge variant={current === s.value ? 'default' : 'glass'} className="cursor-pointer">{s.label}</Badge>
        </button>
      ))}
    </div>
  )
}
