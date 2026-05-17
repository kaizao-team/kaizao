import { describe, it, expect } from 'vitest'
import { formatMoney, formatDate } from '@/lib/utils/format'

describe('formatMoney', () => {
  it('formats cents to yuan with currency symbol', () => {
    expect(formatMoney(123400)).toBe('¥1,234')
    expect(formatMoney(50)).toBe('¥0.5')
    expect(formatMoney(0)).toBe('¥0')
  })
})

describe('formatDate', () => {
  it('formats ISO timestamp', () => {
    expect(formatDate('2026-01-15T10:30:00Z', 'YYYY-MM-DD')).toBe('2026-01-15')
  })
})
