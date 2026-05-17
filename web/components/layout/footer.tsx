import Link from 'next/link'
import { Container } from './container'

export function Footer() {
  return (
    <footer className="border-t border-fg/5 mt-20 py-12 text-sm text-fg-muted">
      <Container className="grid grid-cols-2 md:grid-cols-4 gap-8">
        <div>
          <div className="font-mono text-fg mb-3 text-xs uppercase tracking-wider">产品</div>
          <ul className="space-y-2">
            <li><Link href="/projects" className="hover:text-fg">需求广场</Link></li>
            <li><Link href="/experts" className="hover:text-fg">团队广场</Link></li>
          </ul>
        </div>
        <div>
          <div className="font-mono text-fg mb-3 text-xs uppercase tracking-wider">公司</div>
          <ul className="space-y-2">
            <li><Link href="/about" className="hover:text-fg">关于 KAIZAO</Link></li>
          </ul>
        </div>
        <div>
          <div className="font-mono text-fg mb-3 text-xs uppercase tracking-wider">法务</div>
          <ul className="space-y-2">
            <li><Link href="/about#privacy" className="hover:text-fg">隐私政策</Link></li>
            <li><Link href="/about#terms" className="hover:text-fg">用户协议</Link></li>
          </ul>
        </div>
        <div>
          <div className="font-mono text-fg mb-3 text-xs uppercase tracking-wider">联系</div>
          <p>contact@kaizao.cc</p>
        </div>
      </Container>
      <Container className="mt-10 pt-6 border-t border-fg/5 text-xs text-fg-faint flex justify-between flex-wrap gap-2">
        <span>© 2026 KAIZAO. 开造（VCC）撮合平台</span>
        <span>沪 ICP 备 xxxxxxxx 号</span>
      </Container>
    </footer>
  )
}
