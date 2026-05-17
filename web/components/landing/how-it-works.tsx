import { Container } from '@/components/layout/container'

const STEPS = [
  { num: '01', title: '发起需求', desc: '描述你想做的产品，一句话或一段话都行' },
  { num: '02', title: 'AI 对话生成 PRD', desc: '7 个 AI Agent 协作澄清并产出可用 PRD' },
  { num: '03', title: '撮合靠谱团队', desc: 'SmartMatcher 推荐 T 级团队，双向确认' },
  { num: '04', title: '协同交付', desc: '里程碑、文件、评价闭环，全程透明' },
]

export function HowItWorks() {
  return (
    <section className="py-20 bg-bg-subtle">
      <Container>
        <h2 className="text-3xl font-medium mb-2 tracking-tight">如何工作</h2>
        <p className="text-fg-muted mb-12">从需求到交付，全流程在 KAIZAO 上完成</p>
        <div className="grid md:grid-cols-4 gap-5">
          {STEPS.map((s) => (
            <div key={s.num} className="glass rounded-lg p-5">
              <div className="font-mono text-xs text-fg-faint mb-3">{s.num}</div>
              <h4 className="font-medium mb-1.5">{s.title}</h4>
              <p className="text-fg-muted text-xs leading-relaxed">{s.desc}</p>
            </div>
          ))}
        </div>
      </Container>
    </section>
  )
}
