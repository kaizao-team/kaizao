import React from 'react'
import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { ProjectCard } from '@/components/cards/project-card'

const sample = {
  id: 'p1',
  title: 'Demo project',
  description: 'A short description',
  status: 'open',
  budget_cents: 500000,
  created_at: new Date(Date.now() - 3600 * 1000).toISOString(),
  tags: ['react', 'go'],
  owner: { id: 'u1', name: 'Alice' },
}

describe('ProjectCard', () => {
  it('renders title, description, budget and status', () => {
    render(<ProjectCard p={sample as any} />)
    expect(screen.getByText('Demo project')).toBeInTheDocument()
    expect(screen.getByText('A short description')).toBeInTheDocument()
    expect(screen.getByText('open')).toBeInTheDocument()
    expect(screen.getByText('¥5,000')).toBeInTheDocument()
  })

  it('renders tags (first 3)', () => {
    render(<ProjectCard p={sample as any} />)
    expect(screen.getByText('react')).toBeInTheDocument()
    expect(screen.getByText('go')).toBeInTheDocument()
  })

  it('links to project detail', () => {
    render(<ProjectCard p={sample as any} />)
    expect(screen.getByRole('link')).toHaveAttribute('href', '/projects/p1')
  })
})
