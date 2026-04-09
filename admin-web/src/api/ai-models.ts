import request from './request'

export interface AIProvider {
  id: string
  name: string
  description: string
  available: boolean
}

export interface AIModelConfig {
  active_provider: string
  providers: AIProvider[]
}

export function getAIModelConfig() {
  return request.get('/admin/ai-models')
}

export function updateAIModelConfig(provider: string) {
  return request.put('/admin/ai-models', { provider })
}
