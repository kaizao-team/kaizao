import { describe, it, expect } from 'vitest'
import { ApiError } from '@/lib/api/types'

describe('ApiError', () => {
  it('exposes status, code, message', () => {
    const e = new ApiError(404, 4001, 'not found')
    expect(e.status).toBe(404)
    expect(e.code).toBe(4001)
    expect(e.message).toBe('not found')
    expect(e).toBeInstanceOf(Error)
  })

  it('extends Error class', () => {
    const e = new ApiError(500, 5001, 'internal error')
    expect(e).toBeInstanceOf(Error)
    expect(e instanceof ApiError).toBe(true)
  })
})
