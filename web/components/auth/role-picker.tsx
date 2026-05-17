'use client'
import { cn } from '@/lib/utils/cn'

interface Props {
  value?: 1 | 2
  onChange: (v: 1 | 2) => void
}

const ROLES = [
  { v: 1 as const, title: '我是项目方', desc: '有想法、找团队做出来' },
  { v: 2 as const, title: '我是团队方', desc: '有技能、想接到合适的项目' },
]

export function RolePicker({ value, onChange }: Props) {
  return (
    <div className="grid grid-cols-2 gap-3">
      {ROLES.map((r) => (
        <button
          key={r.v}
          type="button"
          onClick={() => onChange(r.v)}
          className={cn(
            'glass rounded-lg p-4 text-left transition-all',
            value === r.v ? 'ring-2 ring-fg shadow-lg' : 'hover:bg-white/70'
          )}
        >
          <div className="font-medium mb-1">{r.title}</div>
          <div className="text-xs text-fg-muted">{r.desc}</div>
        </button>
      ))}
    </div>
  )
}
