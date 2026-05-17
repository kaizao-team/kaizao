import Link from 'next/link'
import { LoginForm } from './login-form.client'

export const metadata = { title: '登录 · KAIZAO' }

export default function LoginPage({ searchParams }: { searchParams: { from?: string } }) {
  return (
    <div className="glass rounded-lg w-full max-w-sm p-7">
      <h1 className="text-2xl font-medium tracking-tight mb-1">欢迎回来</h1>
      <p className="text-sm text-fg-muted mb-6">登录以继续</p>
      <LoginForm from={searchParams.from} />
      <p className="mt-6 text-xs text-fg-muted text-center">
        还没账号？<Link href="/auth/register" className="text-fg underline">立即注册</Link>
      </p>
    </div>
  )
}
