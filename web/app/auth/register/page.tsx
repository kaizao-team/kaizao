import Link from 'next/link'
import { RegisterForm } from './register-form.client'

export const metadata = { title: '注册 · KAIZAO' }

export default function RegisterPage({ searchParams }: { searchParams: { role?: string } }) {
  const initialRole = searchParams.role === '2' ? 2 : searchParams.role === '1' ? 1 : undefined
  return (
    <div className="glass rounded-lg w-full max-w-sm p-7">
      <h1 className="text-2xl font-medium tracking-tight mb-1">加入 KAIZAO</h1>
      <p className="text-sm text-fg-muted mb-6">选择身份后即可注册</p>
      <RegisterForm initialRole={initialRole} />
      <p className="mt-6 text-xs text-fg-muted text-center">
        已有账号？<Link href="/auth/login" className="text-fg underline">登录</Link>
      </p>
    </div>
  )
}
