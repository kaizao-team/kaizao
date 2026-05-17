'use client'
import { Button } from '@/components/ui/button'
import { useAuthIntercept } from '@/components/auth/auth-intercept'

export function ExpertActions() {
  const { gate, interceptNode } = useAuthIntercept()
  return (
    <>
      <div className="flex gap-2">
        <Button onClick={() => gate('邀约团队', () => alert('请在 App 中发起邀约'))}>邀约</Button>
        <Button variant="glass" onClick={() => gate('联系团队', () => alert('请在 App 中联系'))}>联系</Button>
      </div>
      {interceptNode}
    </>
  )
}
