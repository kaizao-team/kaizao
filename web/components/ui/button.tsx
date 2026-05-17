import * as React from 'react'
import { Slot } from '@radix-ui/react-slot'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils/cn'

const buttonVariants = cva(
  'inline-flex items-center justify-center gap-1.5 font-medium text-sm transition-all focus-visible:outline-none disabled:opacity-50 disabled:pointer-events-none',
  {
    variants: {
      variant: {
        default: 'bg-fg text-bg shadow-glass hover:opacity-90',
        glass: 'glass text-fg hover:bg-white/70',
        ghost: 'text-fg-muted hover:text-fg hover:bg-fg/5',
        link: 'text-fg underline-offset-4 hover:underline',
      },
      size: {
        sm: 'h-8 px-3 rounded-md text-xs',
        default: 'h-10 px-4 rounded-md',
        lg: 'h-11 px-6 rounded-lg',
        pill: 'h-10 px-5 rounded-pill',
      },
    },
    defaultVariants: { variant: 'default', size: 'default' },
  }
)

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean
}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : 'button'
    return <Comp ref={ref} className={cn(buttonVariants({ variant, size }), className)} {...props} />
  }
)
Button.displayName = 'Button'
