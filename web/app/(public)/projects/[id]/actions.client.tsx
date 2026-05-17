'use client'
import { Button } from '@/components/ui/button'
import { useAuthIntercept } from '@/components/auth/auth-intercept'

export function ProjectActions({ projectId }: { projectId: string }) {
  const { gate, interceptNode } = useAuthIntercept()

  return (
    <>
      <div className="glass rounded-lg p-5 space-y-2 sticky top-20">
        <Button className="w-full" onClick={() => gate('投标', () => {
          window.location.href = `/dashboard?from=bid&project=${projectId}`
        })}>
          我有团队，想投标
        </Button>
        <Button variant="glass" className="w-full" onClick={() => gate('联系项目方', () => {
          alert('请在 App 中联系项目方')
        })}>
          联系项目方
        </Button>
        <p className="text-xs text-fg-faint text-center pt-2">深度操作请使用 App</p>
      </div>
      {interceptNode}
    </>
  )
}
