import { Container } from '@/components/layout/container'
import { Card, CardContent } from '@/components/ui/card'

const ITEMS = [
  { title: 'AI 拆解需求', desc: '一句话起步，AI 在 7 轮对话内沉淀完整 PRD', tag: '01' },
  { title: 'T1–T10 分级', desc: '严选评级体系，VibePower 评分确保团队靠谱', tag: '02' },
  { title: '全流程透明', desc: '从撮合到交付，每个里程碑可见可追溯', tag: '03' },
]

export function ValueProps() {
  return (
    <section className="py-20">
      <Container>
        <div className="grid md:grid-cols-3 gap-6">
          {ITEMS.map((it) => (
            <Card key={it.tag}>
              <CardContent className="pt-6">
                <div className="font-mono text-xs text-fg-faint mb-3">{it.tag}</div>
                <h3 className="text-lg font-medium mb-2">{it.title}</h3>
                <p className="text-fg-muted text-sm leading-relaxed">{it.desc}</p>
              </CardContent>
            </Card>
          ))}
        </div>
      </Container>
    </section>
  )
}
