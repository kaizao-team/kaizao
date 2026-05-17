import * as React from 'react'
import { cn } from '@/lib/utils/cn'

export function Container({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn('container max-w-6xl', className)} {...props} />
}
