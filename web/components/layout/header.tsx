'use client'
import Link from 'next/link'
import { useAuth } from '@/lib/auth/use-auth'
import { Button } from '@/components/ui/button'
import { Container } from './container'

const NAV = [
  { href: '/projects', label: '需求广场' },
  { href: '/experts', label: '团队广场' },
  { href: '/about', label: '关于' },
]

export function Header() {
  const { isLoggedIn } = useAuth()
  return (
    <header className="sticky top-0 z-40 backdrop-blur-glass bg-bg/70 border-b border-fg/5">
      <Container className="flex h-14 items-center justify-between">
        <Link href="/" className="font-mono text-sm tracking-wider font-medium">KAIZAO</Link>
        <nav className="hidden md:flex gap-6">
          {NAV.map((n) => (
            <Link key={n.href} href={n.href} className="text-sm text-fg-muted hover:text-fg transition-colors">
              {n.label}
            </Link>
          ))}
        </nav>
        <div className="flex gap-2">
          {isLoggedIn ? (
            <Button asChild variant="glass" size="sm"><Link href="/dashboard">控制台</Link></Button>
          ) : (
            <>
              <Button asChild variant="ghost" size="sm"><Link href="/auth/login">登录</Link></Button>
              <Button asChild size="sm"><Link href="/auth/register">注册</Link></Button>
            </>
          )}
        </div>
      </Container>
    </header>
  )
}
