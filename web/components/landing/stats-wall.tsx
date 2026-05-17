import { Container } from '@/components/layout/container'

const STATS = [
  { num: '2,184', label: '进行中项目' },
  { num: '680+', label: '入驻团队' },
  { num: 'T1–T10', label: '评级体系' },
  { num: '7', label: 'AI Agents' },
]

export function StatsWall() {
  return (
    <section className="py-20 bg-bg-subtle">
      <Container>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
          {STATS.map((s) => (
            <div key={s.label} className="glass rounded-lg p-6 text-center">
              <div className="text-3xl md:text-4xl font-medium text-gradient-hero">{s.num}</div>
              <div className="text-xs font-mono text-fg-muted mt-2 uppercase tracking-wider">{s.label}</div>
            </div>
          ))}
        </div>
      </Container>
    </section>
  )
}
