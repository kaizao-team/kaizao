import * as React from 'react'
import { cn } from '@/lib/utils/cn'

export interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  variant?: 'default' | 'glass' | 'outline'
}

export function Badge({ className, variant = 'default', ...props }: BadgeProps) {
  const variants = {
    default: 'bg-fg text-bg',
    glass: 'glass text-fg',
    outline: 'border border-fg/15 text-fg',
  }
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1.5 rounded-pill px-3 py-1 text-xs font-mono uppercase tracking-wider',
        variants[variant],
        className
      )}
      {...props}
    />
  )
}
