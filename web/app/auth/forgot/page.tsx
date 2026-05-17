import Link from 'next/link'
import { Button } from '@/components/ui/button'

export const metadata = { title: '找回密码 · KAIZAO' }

export default function ForgotPage() {
  return (
    <div className="glass rounded-lg w-full max-w-sm p-7 text-center">
      <h1 className="text-xl font-medium tracking-tight mb-3">找回密码</h1>
      <p className="text-sm text-fg-muted mb-6">
        当前 web 版只支持手机号 + 验证码登录，无需密码。<br />
        请直接使用登录页验证码登录。
      </p>
      <Button asChild className="w-full"><Link href="/auth/login">前往登录</Link></Button>
    </div>
  )
}
