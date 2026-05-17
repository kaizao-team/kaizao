'use client'
import * as React from 'react'
import { useRouter } from 'next/navigation'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { sendSmsCode, login } from '@/lib/api/auth'

export function LoginForm({ from }: { from?: string }) {
  const router = useRouter()
  const [mobile, setMobile] = React.useState('')
  const [code, setCode] = React.useState('')
  const [sending, setSending] = React.useState(false)
  const [submitting, setSubmitting] = React.useState(false)
  const [error, setError] = React.useState<string | null>(null)
  const [cooldown, setCooldown] = React.useState(0)

  React.useEffect(() => {
    if (cooldown > 0) {
      const t = setTimeout(() => setCooldown(cooldown - 1), 1000)
      return () => clearTimeout(t)
    }
  }, [cooldown])

  const sendCode = async () => {
    if (!/^1\d{10}$/.test(mobile)) { setError('请输入有效手机号'); return }
    setError(null); setSending(true)
    try {
      await sendSmsCode({ mobile, scene: 'login' })
      setCooldown(60)
    } catch (e: any) {
      setError(e?.message ?? '发送失败')
    } finally { setSending(false) }
  }

  const submit = async (ev: React.FormEvent) => {
    ev.preventDefault()
    if (!mobile || !code) { setError('请填写完整'); return }
    setError(null); setSubmitting(true)
    try {
      await login({ mobile, sms_code: code })
      router.replace(from || '/dashboard')
      router.refresh()
    } catch (e: any) {
      setError(e?.message ?? '登录失败')
    } finally { setSubmitting(false) }
  }

  return (
    <form onSubmit={submit} className="space-y-3">
      <Input value={mobile} onChange={(e) => setMobile(e.target.value)} placeholder="手机号" inputMode="numeric" maxLength={11} />
      <div className="flex gap-2">
        <Input value={code} onChange={(e) => setCode(e.target.value)} placeholder="验证码" inputMode="numeric" maxLength={6} />
        <Button type="button" variant="glass" disabled={sending || cooldown > 0} onClick={sendCode}>
          {cooldown > 0 ? `${cooldown}s` : '发送'}
        </Button>
      </div>
      {error && <p className="text-xs text-rose-600">{error}</p>}
      <Button type="submit" className="w-full" disabled={submitting}>
        {submitting ? '登录中…' : '登录'}
      </Button>
    </form>
  )
}
