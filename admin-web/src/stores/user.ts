import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export interface AdminUser {
  uuid: string
  phone: string
  nickname: string
  avatar_url?: string
  role: number
  status: number
}

export const useUserStore = defineStore('user', () => {
  const token = ref(localStorage.getItem('admin_token') || '')
  const userInfo = ref<AdminUser | null>(null)

  function setToken(t: string) {
    token.value = t
    localStorage.setItem('admin_token', t)
  }

  function setUser(info: AdminUser) {
    userInfo.value = info
  }

  function clearToken() {
    token.value = ''
    userInfo.value = null
    localStorage.removeItem('admin_token')
  }

  const isLoggedIn = computed(() => !!token.value)

  return { token, userInfo, isLoggedIn, setToken, setUser, clearToken }
})
