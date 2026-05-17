import React from 'react'
import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { AuthIntercept } from '@/components/auth/auth-intercept'

describe('AuthIntercept', () => {
  it('does not render when open=false', () => {
    const { container } = render(<AuthIntercept action="投标" open={false} onClose={() => {}} />)
    expect(container).toBeEmptyDOMElement()
  })

  it('renders action text and CTAs when open', () => {
    render(<AuthIntercept action="投标" open={true} onClose={() => {}} />)
    expect(screen.getByText(/注册后即可/)).toBeInTheDocument()
    expect(screen.getByRole('link', { name: '立即注册' })).toHaveAttribute('href', '/auth/register')
    expect(screen.getByRole('link', { name: '登录' })).toHaveAttribute('href', '/auth/login')
  })

  it('calls onClose when backdrop clicked', () => {
    const onClose = vi.fn()
    const { container } = render(<AuthIntercept action="投标" open={true} onClose={onClose} />)
    fireEvent.click(container.firstChild as Element)
    expect(onClose).toHaveBeenCalled()
  })
})
