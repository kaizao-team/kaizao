import { Container } from '@/components/layout/container'

const QA = [
  { q: 'KAIZAO 是做什么的？', a: 'KAIZAO 是一个 AI 驱动的软件需求撮合平台。项目方一句话起步，AI 帮你拆解需求并撮合靠谱的团队。' },
  { q: '我能在 web 上完成所有事吗？', a: '当前 web 版支持浏览需求/团队、查看项目详情、注册登录。发布需求、投标、协同交付等深度功能请使用 App。' },
  { q: '团队评级是什么？', a: 'VibePower 评级体系将团队分为 T1–T10 十级，新团队首次定级最高 T5，满分 750。评级综合考虑完成度、好评、复购等。' },
  { q: '需求/团队信息是否会被滥用？', a: '公开的需求和团队信息已脱敏，联系方式仅在双向确认后开放。所有数据流转受隐私政策约束。' },
]

export function Faq() {
  return (
    <section className="py-20">
      <Container>
        <h2 className="text-3xl font-medium mb-10 tracking-tight">常见问题</h2>
        <div className="divide-y divide-fg/5">
          {QA.map((item) => (
            <details key={item.q} className="py-4 group">
              <summary className="cursor-pointer flex items-center justify-between font-medium">
                {item.q}
                <span className="font-mono text-fg-faint text-xs group-open:rotate-45 transition-transform">+</span>
              </summary>
              <p className="mt-3 text-fg-muted text-sm leading-relaxed">{item.a}</p>
            </details>
          ))}
        </div>
      </Container>
    </section>
  )
}
