import request from './request'

export function getAdminProjects(params: Record<string, any>) {
  return request.get('/admin/projects', { params })
}

export function reviewProject(uuid: string, data: { action: string; reason?: string }) {
  return request.put(`/admin/projects/${uuid}/review`, data)
}

export function getProjectDetail(id: string) {
  return request.get(`/projects/${id}`)
}

export function getProjectFiles(id: string) {
  return request.get(`/projects/${id}/files`)
}

export function uploadProjectFile(id: string, formData: FormData) {
  return request.post(`/projects/${id}/files`, formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
  })
}

export function getProjectBids(id: string) {
  return request.get(`/projects/${id}/bids`)
}

export function getProjectMilestones(id: string) {
  return request.get(`/projects/${id}/milestones`)
}

export function getProjectTasks(id: string) {
  return request.get(`/projects/${id}/tasks`)
}

export function getProjectReviews(id: string) {
  return request.get(`/projects/${id}/reviews`)
}

export function getProjectPRD(id: string) {
  return request.get(`/projects/${id}/prd`)
}

export function getAIDocuments(uuid: string) {
  return request.get(`/admin/projects/${uuid}/ai-documents`)
}

export function getAIDocumentDownloadUrl(uuid: string, docId: number) {
  return request.get(`/admin/projects/${uuid}/ai-documents/${docId}/download`)
}

export function uploadProjectPrdDocument(uuid: string, formData: FormData) {
  return request.put(`/admin/projects/${uuid}/prd/document`, formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
  })
}
