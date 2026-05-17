import { describe, it, expect } from 'vitest'

describe('BFF proxy URL composition', () => {
  it('joins path segments correctly', () => {
    const segments = ['v1', 'market', 'projects']
    expect(segments.join('/')).toBe('v1/market/projects')
  })

  it('builds upstream url with query string', () => {
    const upstream = 'http://localhost:39527'
    const path = 'v1/market/projects'
    const search = '?page=1&size=20'
    expect(`${upstream}/api/${path}${search}`).toBe('http://localhost:39527/api/v1/market/projects?page=1&size=20')
  })
})
