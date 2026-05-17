'use client'
import * as React from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/lib/auth/use-auth'
import { Button } from '@/components/ui/button'

interface InterceptProps {
  action: string
  open: boolean
  onClose: () => void
}

export function AuthIntercept({ action, open, onClose }: InterceptProps) {
  if (!open) return null
  return (
    <div className="fixed inset-0 z-50 grid place-items-center bg-black/40 backdrop-blur-sm" onClick={onClose}>
      <div className="glass rounded-lg max-w-sm w-full mx-4 p-7 text-center" onClick={(e) => e.stopPropagation()}>
        <h3 className="text-lg font-medium mb-2">注册后即可{action}</h3>
        <p className="text-sm text-fg-muted mb-6">已有账号？登录后继续操作</p>
        <div className="flex gap-2 justify-center mb-4">
          <Button asChild><Link href="/auth/register">立即注册</Link></Button>
          <Button asChild variant="glass"><Link href="/auth/login">登录</Link></Button>
        </div>
        <p className="text-xs text-fg-faint">或下载 App 体验完整功能</p>
      </div>
    </div>
  )
}

export function useAuthIntercept() {
  const { isLoggedIn } = useAuth()
  const [intercept, setIntercept] = React.useState<{ action: string } | null>(null)
  const router = useRouter()

  function gate(action: string, onAuthed: () => void) {
    if (isLoggedIn) onAuthed()
    else setIntercept({ action })
  }

  const node = intercept ? (
    <AuthIntercept action={intercept.action} open onClose={() => setIntercept(null)} />
  ) : null

  return { gate, interceptNode: node }
}
