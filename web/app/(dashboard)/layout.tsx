import { redirect } from 'next/navigation'
import { getServerSession } from '@/lib/auth/session'

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const session = getServerSession()
  if (!session.isLoggedIn) redirect('/auth/login')
  return <>{children}</>
}
