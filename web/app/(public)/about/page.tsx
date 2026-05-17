import { Container } from '@/components/layout/container'
import { ColorHalo } from '@/components/effects/color-halo'

export const metadata = { title: '关于 KAIZAO' }

export default function AboutPage() {
  return (
    <>
      <section className="relative py-20 overflow-hidden">
        <ColorHalo intensity="medium" />
        <Container className="relative">
          <h1 className="text-5xl font-medium tracking-tight mb-6">关于 KAIZAO</h1>
          <p className="text-lg text-fg-muted max-w-2xl leading-relaxed">
            KAIZAO(开造 / VCC)是一个 AI 驱动的软件需求撮合平台。
            我们用 AI Agent 帮项目方拆解需求、用 T 级评级帮团队建立信用，
            让&ldquo;靠谱的人&rdquo;和&ldquo;靠谱的活&rdquo;高效相遇。
          </p>
        </Container>
      </section>

      <Container className="pb-20 max-w-3xl space-y-12 text-fg leading-relaxed">
        <section id="privacy">
          <h2 className="text-2xl font-medium mb-4 tracking-tight">隐私政策</h2>
          <p className="text-fg-muted">
            我们尊重并保护所有使用本服务用户的个人隐私权。完整隐私政策正在迁移到 web 版，
            当前请参考 App 内隐私政策或联系 contact@kaizao.cc。
          </p>
        </section>

        <section id="terms">
          <h2 className="text-2xl font-medium mb-4 tracking-tight">用户协议</h2>
          <p className="text-fg-muted">
            使用本服务即视为同意我们的用户协议。详细条款请参考 App 内文档或联系我们。
          </p>
        </section>

        <section>
          <h2 className="text-2xl font-medium mb-4 tracking-tight">联系</h2>
          <p className="text-fg-muted">contact@kaizao.cc</p>
        </section>
      </Container>
    </>
  )
}
