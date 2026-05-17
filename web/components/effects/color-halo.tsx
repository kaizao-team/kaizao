import { cn } from '@/lib/utils/cn'

interface ColorHaloProps {
  className?: string
  intensity?: 'low' | 'medium' | 'high'
}

export function ColorHalo({ className, intensity = 'medium' }: ColorHaloProps) {
  const sizes = {
    low: { a: 200, b: 180 },
    medium: { a: 320, b: 280 },
    high: { a: 420, b: 360 },
  }[intensity]

  return (
    <div className={cn('pointer-events-none absolute inset-0 overflow-hidden', className)}>
      <div
        className="absolute -left-20 -top-20 rounded-full opacity-90"
        style={{
          width: sizes.a,
          height: sizes.a,
          background:
            'radial-gradient(circle at 30% 30%, rgba(255,145,200,.5), transparent 60%), radial-gradient(circle at 70% 60%, rgba(140,180,255,.55), transparent 60%)',
          filter: 'blur(24px)',
        }}
      />
      <div
        className="absolute -right-20 -bottom-20 rounded-full"
        style={{
          width: sizes.b,
          height: sizes.b,
          background:
            'radial-gradient(circle, rgba(180,255,200,.45), transparent 60%), radial-gradient(circle at 70% 40%, rgba(255,220,130,.4), transparent 60%)',
          filter: 'blur(28px)',
        }}
      />
    </div>
  )
}
