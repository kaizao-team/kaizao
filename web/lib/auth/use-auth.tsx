'use client'
import * as React from 'react'

interface AuthState {
  isLoggedIn: boolean
  role?: 1 | 2
}

const AuthContext = React.createContext<AuthState>({ isLoggedIn: false })

export function AuthProvider({ children, value }: { children: React.ReactNode; value: AuthState }) {
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  return React.useContext(AuthContext)
}
