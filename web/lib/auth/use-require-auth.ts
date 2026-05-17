'use client'
import { useRouter, usePathname } from 'next/navigation'
import type { Route } from 'next'
import { useAuth } from './use-auth'

export function useRequireAuth() {
  const { isLoggedIn } = useAuth()
  const router = useRouter()
  const pathname = usePathname()

  return function requireOrPromptAuth(onAuthed: () => void, onAnonymous?: () => void) {
    if (isLoggedIn) {
      onAuthed()
    } else if (onAnonymous) {
      onAnonymous()
    } else {
      router.push(`/auth/login?from=${encodeURIComponent(pathname)}` as Route)
    }
  }
}
