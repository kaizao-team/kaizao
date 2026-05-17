'use client'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { logout } from '@/lib/api/auth'

export function LogoutButton() {
  const router = useRouter()
  return (
    <Button variant="glass" size="sm" onClick={async () => {
      await logout().catch(() => {})
      router.replace('/')
      router.refresh()
    }}>退出</Button>
  )
}
