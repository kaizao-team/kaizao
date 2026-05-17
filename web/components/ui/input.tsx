import * as React from 'react'
import { cn } from '@/lib/utils/cn'

export const Input = React.forwardRef<HTMLInputElement, React.InputHTMLAttributes<HTMLInputElement>>(
  ({ className, type, ...props }, ref) => (
    <input
      type={type}
      className={cn(
        'flex h-10 w-full rounded-md border border-fg/10 bg-bg px-3 py-2 text-sm placeholder:text-fg-faint focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-fg/20 disabled:opacity-50',
        className
      )}
      ref={ref}
      {...props}
    />
  )
)
Input.displayName = 'Input'
