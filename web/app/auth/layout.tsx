import Link from 'next/link'
import { ColorHalo } from '@/components/effects/color-halo'

export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="relative min-h-screen overflow-hidden">
      <ColorHalo intensity="high" />
      <header className="relative z-10 px-6 py-5">
        <Link href="/" className="font-mono text-sm tracking-wider font-medium">KAIZAO</Link>
      </header>
      <main className="relative z-10 grid place-items-center px-6 pb-16">{children}</main>
    </div>
  )
}
