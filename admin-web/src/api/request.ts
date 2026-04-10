import axios from 'axios'
import type { AxiosInstance, InternalAxiosRequestConfig, AxiosResponse } from 'axios'
import { ElMessage } from 'element-plus'
import router from '@/router'

const service: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  timeout: 120000,
})

let isRedirecting = false

function handleUnauthorized() {
  localStorage.removeItem('admin_token')
  if (!isRedirecting) {
    isRedirecting = true
    router.replace({ name: 'Login', query: { redirect: router.currentRoute.value.fullPath } }).finally(() => {
      isRedirecting = false
    })
  }
}

service.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = localStorage.getItem('admin_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => Promise.reject(error),
)

service.interceptors.response.use(
  (response: AxiosResponse) => {
    const { code, message } = response.data
    if (code !== 0) {
      ElMessage.error(message || '请求失败')
      if (code === 401 || code === 10008) {
        handleUnauthorized()
      }
      return Promise.reject(new Error(message))
    }
    return response.data
  },
  (error) => {
    if (error.response?.status === 401) {
      handleUnauthorized()
    } else {
      ElMessage.error(error.message || '网络异常')
    }
    return Promise.reject(error)
  },
)

export default service
