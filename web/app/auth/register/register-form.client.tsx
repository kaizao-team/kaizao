'use client'
import * as React from 'react'
import { useRouter } from 'next/navigation'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { RolePicker } from '@/components/auth/role-picker'
import { sendSmsCode, register } from '@/lib/api/auth'

export function RegisterForm({ initialRole }: { initialRole?: 1 | 2 }) {
  const router = useRouter()
  const [step, setStep] = React.useState<1 | 2>(initialRole ? 2 : 1)
  const [role, setRole] = React.useState<1 | 2 | undefined>(initialRole)
  const [mobile, setMobile] = React.useState('')
  const [code, setCode] = React.useState('')
  const [cooldown, setCooldown] = React.useState(0)
  const [error, setError] = React.useState<string | null>(null)
  const [submitting, setSubmitting] = React.useState(false)

  React.useEffect(() => {
    if (cooldown > 0) {
      const t = setTimeout(() => setCooldown(cooldown - 1), 1000)
      return () => clearTimeout(t)
    }
  }, [cooldown])

  if (step === 1) {
    return (
      <div className="space-y-4">
        <RolePicker value={role} onChange={(v) => setRole(v)} />
        <Button className="w-full" disabled={!role} onClick={() => setStep(2)}>下一步</Button>
      </div>
    )
  }

  const sendCode = async () => {
    if (!/^1\d{10}$/.test(mobile)) { setError('请输入有效手机号'); return }
    setError(null)
    try {
      await sendSmsCode({ mobile, scene: 'register' })
      setCooldown(60)
    } catch (e: any) { setError(e?.message ?? '发送失败') }
  }

  const submit = async (ev: React.FormEvent) => {
    ev.preventDefault()
    if (!role || !mobile || !code) { setError('请填写完整'); return }
    setError(null); setSubmitting(true)
    try {
      await register({ mobile, sms_code: code, role })
      router.replace('/dashboard')
      router.refresh()
    } catch (e: any) {
      setError(e?.message ?? '注册失败')
    } finally { setSubmitting(false) }
  }

  return (
    <form onSubmit={submit} className="space-y-3">
      <div className="flex items-center gap-2 text-xs text-fg-muted font-mono mb-3">
        <span>身份：</span>
        <span className="text-fg">{role === 1 ? '项目方' : '团队方'}</span>
        <button type="button" onClick={() => setStep(1)} className="ml-auto underline text-fg-muted hover:text-fg">修改</button>
      </div>
      <Input value={mobile} onChange={(e) => setMobile(e.target.value)} placeholder="手机号" inputMode="numeric" maxLength={11} />
      <div className="flex gap-2">
        <Input value={code} onChange={(e) => setCode(e.target.value)} placeholder="验证码" inputMode="numeric" maxLength={6} />
        <Button type="button" variant="glass" disabled={cooldown > 0} onClick={sendCode}>
          {cooldown > 0 ? `${cooldown}s` : '发送'}
        </Button>
      </div>
      {error && <p className="text-xs text-rose-600">{error}</p>}
      <Button type="submit" className="w-full" disabled={submitting}>
        {submitting ? '注册中…' : '完成注册'}
      </Button>
    </form>
  )
}
