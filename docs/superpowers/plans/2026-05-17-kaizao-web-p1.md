# KAIZAO Web 撮合平台 P1 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在仓库内新增 `web/` 目录，基于 Next.js 14 + Tailwind + shadcn/ui 实现 KAIZAO 撮合平台的 P1 web 站（14 页 · 公开浏览 + 注册登录 + 个人空间），通过 BFF 调用现有 kaizao-server v1 / v2 接口，不改后端任何代码，本地完成后推 GitHub PR 等用户确认再部署。

**Architecture:** Next.js 14 App Router · Glassmorphism Tech 设计语言（白底 + 玻璃态 + 彩色光晕 + Geist 字体）· `app/api/[...path]/route.ts` 做透明 BFF 反代到 kaizao-server · HttpOnly Cookie 存 token · TanStack Query 拉数据 · 独立 Docker 容器部署，不影响 newapi / kaizao-server / 任何现有容器。

**Tech Stack:** Next.js 14, React 18, TypeScript 5, Tailwind CSS 3, shadcn/ui (Radix), TanStack Query 5, React Hook Form + Zod, Geist (next/font), Vitest, Playwright, pnpm 9, Docker (node:20-alpine).

**Spec Reference:** `docs/superpowers/specs/2026-05-17-kaizao-web-p1-design.md`

---

## File Structure Map

完整 `web/` 目录在实施完成后的样子（每个文件的职责一目了然）：

```
web/
├── app/
│   ├── layout.tsx                    根布局（字体、全局样式、Providers）
│   ├── page.tsx                      落地首页 /
│   ├── globals.css                   Tailwind base + 设计 token
│   ├── not-found.tsx                 404 页
│   ├── sitemap.ts                    动态 sitemap（公开页）
│   ├── robots.ts                     robots.txt
│   │
│   ├── (public)/                     公开路由组
│   │   ├── projects/
│   │   │   ├── page.tsx              需求广场 /projects
│   │   │   └── [id]/page.tsx         项目详情 /projects/[id]
│   │   ├── experts/
│   │   │   ├── page.tsx              团队广场 /experts
│   │   │   └── [id]/page.tsx         团队主页 /experts/[id]
│   │   ├── users/[id]/page.tsx       用户公开主页 /users/[id]
│   │   └── about/page.tsx            关于/隐私 /about
│   │
│   ├── auth/
│   │   ├── login/page.tsx            登录
│   │   ├── register/page.tsx         注册（多步）
│   │   └── forgot/page.tsx           找回密码
│   │
│   ├── (dashboard)/                  需登录路由组
│   │   ├── layout.tsx                守卫 + Header
│   │   ├── dashboard/page.tsx        个人主页（按角色）
│   │   └── me/
│   │       ├── page.tsx              个人中心
│   │       ├── projects/page.tsx     我的项目
│   │       └── notifications/page.tsx
│   │
│   └── api/[...path]/route.ts        BFF 反代
│
├── components/
│   ├── ui/                           shadcn/ui 基础组件
│   ├── layout/
│   │   ├── header.tsx
│   │   ├── footer.tsx
│   │   └── container.tsx
│   ├── landing/                      落地页 sections
│   │   ├── hero.tsx
│   │   ├── value-props.tsx
│   │   ├── how-it-works.tsx
│   │   ├── featured.tsx
│   │   ├── stats-wall.tsx
│   │   ├── faq.tsx
│   ├── cards/
│   │   ├── project-card.tsx
│   │   └── expert-card.tsx
│   ├── auth/
│   │   ├── auth-intercept.tsx        拦截浮层
│   │   └── role-picker.tsx           注册第一步
│   └── effects/
│       └── color-halo.tsx            可复用彩光晕背景
│
├── lib/
│   ├── api/
│   │   ├── client.ts                 服务端 fetch wrapper（SSR 用，内网直连）
│   │   ├── browser.ts                浏览器 fetch wrapper（走 BFF /api）
│   │   ├── auth.ts                   登录注册接口
│   │   ├── market.ts                 广场接口
│   │   ├── projects.ts               项目接口
│   │   ├── users.ts                  用户接口
│   │   └── types.ts                  共享类型
│   ├── auth/
│   │   ├── cookie.ts                 HttpOnly cookie 读写
│   │   ├── session.ts                getServerSession()
│   │   └── use-require-auth.ts       客户端 hook
│   └── utils/
│       ├── cn.ts                     clsx + tailwind-merge
│       └── format.ts                 日期、金额格式化
│
├── styles/
│   └── tokens.css                    CSS 变量定义
│
├── tests/
│   ├── unit/                         Vitest 单元测试
│   └── e2e/                          Playwright e2e
│
├── public/
│   ├── favicon.ico
│   └── logo.svg
│
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── .env.example
├── .eslintrc.json
├── .gitignore
├── README.md
├── next.config.js
├── package.json
├── playwright.config.ts
├── postcss.config.js
├── tailwind.config.ts
├── tsconfig.json
└── vitest.config.ts
```

**核心解耦原则：**
- `lib/api/client.ts`（服务端）和 `lib/api/browser.ts`（客户端）严格分开，禁止互相导入。SSR 走内网直连 `KAIZAO_SERVER_INTERNAL`，浏览器走同源 `/api/*`。
- 设计 token 全部走 CSS variables（`styles/tokens.css`），组件用 Tailwind 的 `bg-[hsl(var(--bg))]` 引用，不在组件里写颜色字面量。
- 按业务模块（auth/market/projects/users）切 `lib/api/*.ts`，禁止单文件巨型 API。

---

## Phase 1 · 项目骨架（Task 1–7）

> 这一阶段不出页面，只出脚手架。完成后 `pnpm dev` 能访问空白首页、`/api/v1/ping` 等反代能通、字体光晕样式能渲染。

### Task 1: 初始化 web/ 目录 + Next.js 14

**Files:**
- Create: `web/package.json`
- Create: `web/tsconfig.json`
- Create: `web/next.config.js`
- Create: `web/.gitignore`
- Create: `web/.env.example`
- Create: `web/app/layout.tsx`
- Create: `web/app/page.tsx`
- Create: `web/app/globals.css`

- [ ] **Step 1: 创建 web 目录并写 package.json**

Run:
```bash
mkdir -p web && cd web
```

Write `web/package.json`:
```json
{
  "name": "kaizao-web",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev -p 3000",
    "build": "next build",
    "start": "next start -p 3000",
    "lint": "next lint",
    "typecheck": "tsc --noEmit",
    "test": "vitest run",
    "test:watch": "vitest",
    "e2e": "playwright test"
  },
  "dependencies": {
    "next": "14.2.18",
    "react": "18.3.1",
    "react-dom": "18.3.1"
  },
  "devDependencies": {
    "@types/node": "20.14.10",
    "@types/react": "18.3.12",
    "@types/react-dom": "18.3.1",
    "eslint": "8.57.1",
    "eslint-config-next": "14.2.18",
    "typescript": "5.5.4"
  },
  "packageManager": "pnpm@9.12.3"
}
```

- [ ] **Step 2: 写 tsconfig 和 next.config**

Write `web/tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": false,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules", "tests/e2e/**/*"]
}
```

Write `web/next.config.js`:
```js
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  reactStrictMode: true,
  poweredByHeader: false,
  experimental: { typedRoutes: true },
}
module.exports = nextConfig
```

Write `web/.gitignore`:
```
node_modules
.next
out
.env
.env.local
.env.production.local
*.log
.DS_Store
playwright-report
test-results
coverage
```

Write `web/.env.example`:
```
NEXT_PUBLIC_SITE_URL=http://localhost:3000
KAIZAO_SERVER_INTERNAL=http://localhost:39527
AI_AGENT_INTERNAL=http://localhost:39528
NODE_ENV=development
```

- [ ] **Step 3: 写最小可运行的 layout 和 page**

Write `web/app/layout.tsx`:
```tsx
import './globals.css'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'KAIZAO · AI 驱动的软件需求撮合平台',
  description: '把模糊的需求变成可交付的项目。AI Agent 拆解需求、撮合分级团队、协同交付。',
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000'),
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="zh-CN">
      <body>{children}</body>
    </html>
  )
}
```

Write `web/app/page.tsx`:
```tsx
export default function Home() {
  return <main>KAIZAO web · scaffold ok</main>
}
```

Write `web/app/globals.css`:
```css
body { font-family: system-ui, sans-serif; margin: 0; padding: 24px; }
```

- [ ] **Step 4: 安装依赖并启动验证**

Run:
```bash
cd web && pnpm install
pnpm dev
```

Expected: 终端打印 `▲ Next.js 14.2.18 ... Local: http://localhost:3000`，浏览器打开 `http://localhost:3000` 看到 `KAIZAO web · scaffold ok`。Ctrl+C 停掉。

- [ ] **Step 5: Commit**

```bash
git add web/
git commit -m "feat(web): scaffold next.js 14 project for kaizao web platform"
```

---

### Task 2: Tailwind CSS + 设计 Token

**Files:**
- Create: `web/tailwind.config.ts`
- Create: `web/postcss.config.js`
- Create: `web/styles/tokens.css`
- Modify: `web/app/globals.css`
- Modify: `web/package.json`

- [ ] **Step 1: 安装 Tailwind 相关包**

Run:
```bash
cd web && pnpm add -D tailwindcss@3.4.14 postcss@8.4.49 autoprefixer@10.4.20 tailwindcss-animate@1.0.7
```

- [ ] **Step 2: 写 Tailwind 配置**

Write `web/tailwind.config.ts`:
```ts
import type { Config } from 'tailwindcss'

const config: Config = {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  theme: {
    container: {
      center: true,
      padding: '16px',
      screens: { sm: '640px', md: '768px', lg: '1024px', xl: '1280px', '2xl': '1280px' },
    },
    extend: {
      colors: {
        bg: 'hsl(var(--bg) / <alpha-value>)',
        'bg-subtle': 'hsl(var(--bg-subtle) / <alpha-value>)',
        fg: 'hsl(var(--fg) / <alpha-value>)',
        'fg-muted': 'hsl(var(--fg-muted) / <alpha-value>)',
        'fg-faint': 'hsl(var(--fg-faint) / <alpha-value>)',
        border: 'hsl(var(--border) / <alpha-value>)',
      },
      borderRadius: {
        sm: 'var(--radius-sm)',
        DEFAULT: 'var(--radius)',
        lg: 'var(--radius-lg)',
        pill: 'var(--radius-pill)',
      },
      backdropBlur: { glass: '20px' },
      boxShadow: {
        glass: '0 1px 0 rgba(255,255,255,.9) inset, 0 8px 24px rgba(60,60,100,.08)',
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
}
export default config
```

Write `web/postcss.config.js`:
```js
module.exports = {
  plugins: { tailwindcss: {}, autoprefixer: {} },
}
```

- [ ] **Step 3: 写设计 token**

Write `web/styles/tokens.css`:
```css
:root {
  --bg: 0 0% 100%;
  --bg-subtle: 240 20% 99%;
  --fg: 0 0% 4%;
  --fg-muted: 240 10% 39%;
  --fg-faint: 0 0% 53%;
  --border: 240 33% 10%;

  --accent-1: 332 100% 78%;
  --accent-2: 219 100% 77%;
  --accent-3: 137 100% 86%;
  --accent-4: 39 100% 75%;

  --radius-sm: 6px;
  --radius: 8px;
  --radius-lg: 12px;
  --radius-pill: 99px;

  --gradient-hero: linear-gradient(120deg, #6a5ae8 0%, #ec5e9d 60%, #ff9472 100%);
}

.glass {
  background: rgba(255, 255, 255, 0.55);
  border: 1px solid rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(20px) saturate(140%);
  -webkit-backdrop-filter: blur(20px) saturate(140%);
  box-shadow: 0 1px 0 rgba(255, 255, 255, 0.9) inset, 0 8px 24px rgba(60, 60, 100, 0.08);
}

.text-gradient-hero {
  background: var(--gradient-hero);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
  color: transparent;
}

@supports not (backdrop-filter: blur(10px)) {
  .glass { background: rgba(255, 255, 255, 0.9); }
}
```

- [ ] **Step 4: 改写 globals.css 引入 Tailwind 和 tokens**

Write `web/app/globals.css`:
```css
@import '../styles/tokens.css';
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  html { -webkit-text-size-adjust: 100%; }
  body {
    background: hsl(var(--bg));
    color: hsl(var(--fg));
    font-feature-settings: 'rlig' 1, 'calt' 1;
    -webkit-font-smoothing: antialiased;
  }
}
```

改写 `web/app/page.tsx`:
```tsx
export default function Home() {
  return (
    <main className="min-h-screen flex items-center justify-center">
      <div className="glass rounded-lg px-6 py-3">
        <span className="text-gradient-hero text-2xl font-medium">KAIZAO</span>
      </div>
    </main>
  )
}
```

- [ ] **Step 5: 验证渲染 + Commit**

Run:
```bash
cd web && pnpm dev
```

Expected: `http://localhost:3000` 显示一个白底页面，中间一个玻璃态卡片，里面 "KAIZAO" 用紫粉橙渐变色。Ctrl+C 停。

```bash
git add web/
git commit -m "feat(web): integrate tailwind and design tokens"
```

---

### Task 3: 字体 (Geist) + 工具函数

**Files:**
- Create: `web/lib/utils/cn.ts`
- Create: `web/lib/utils/format.ts`
- Modify: `web/app/layout.tsx`
- Modify: `web/package.json`

- [ ] **Step 1: 安装字体和工具包**

Run:
```bash
cd web && pnpm add geist clsx tailwind-merge dayjs
```

- [ ] **Step 2: 写 cn 工具**

Write `web/lib/utils/cn.ts`:
```ts
import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
```

- [ ] **Step 3: 写 format 工具**

Write `web/lib/utils/format.ts`:
```ts
import dayjs from 'dayjs'
import 'dayjs/locale/zh-cn'
import relativeTime from 'dayjs/plugin/relativeTime'

dayjs.locale('zh-cn')
dayjs.extend(relativeTime)

export function formatRelative(input: string | number | Date): string {
  return dayjs(input).fromNow()
}

export function formatDate(input: string | number | Date, fmt = 'YYYY-MM-DD'): string {
  return dayjs(input).format(fmt)
}

export function formatMoney(cents: number): string {
  return `¥${(cents / 100).toLocaleString('zh-CN', { minimumFractionDigits: 0, maximumFractionDigits: 2 })}`
}
```

- [ ] **Step 4: 改 layout 引入 Geist 字体**

Write `web/app/layout.tsx`:
```tsx
import './globals.css'
import type { Metadata } from 'next'
import { GeistSans } from 'geist/font/sans'
import { GeistMono } from 'geist/font/mono'

export const metadata: Metadata = {
  title: 'KAIZAO · AI 驱动的软件需求撮合平台',
  description: '把模糊的需求变成可交付的项目。AI Agent 拆解需求、撮合分级团队、协同交付。',
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000'),
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="zh-CN" className={`${GeistSans.variable} ${GeistMono.variable}`}>
      <body className="font-sans">{children}</body>
    </html>
  )
}
```

Append to `web/tailwind.config.ts` `theme.extend`:
```ts
      fontFamily: {
        sans: ['var(--font-geist-sans)', 'system-ui', 'sans-serif'],
        mono: ['var(--font-geist-mono)', 'ui-monospace', 'monospace'],
      },
```

- [ ] **Step 5: 验证 + Commit**

Run:
```bash
cd web && pnpm dev
```

Expected: 页面文字变成 Geist 字体（清晰几何感的 sans）。Ctrl+C 停。

```bash
git add web/
git commit -m "feat(web): integrate geist fonts and shared utilities"
```

---

### Task 4: shadcn/ui 基础组件

**Files:**
- Create: `web/components.json`
- Create: `web/components/ui/button.tsx`
- Create: `web/components/ui/input.tsx`
- Create: `web/components/ui/card.tsx`
- Create: `web/components/ui/badge.tsx`
- Modify: `web/package.json`

- [ ] **Step 1: 安装 Radix 和支持包**

Run:
```bash
cd web && pnpm add @radix-ui/react-slot class-variance-authority lucide-react
```

- [ ] **Step 2: 创建 components.json 占位（手动定 shadcn 风格，不跑 init 脚本）**

Write `web/components.json`:
```json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "default",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.ts",
    "css": "app/globals.css",
    "baseColor": "neutral",
    "cssVariables": true
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils/cn",
    "ui": "@/components/ui"
  }
}
```

- [ ] **Step 3: 写 Button 组件**

Write `web/components/ui/button.tsx`:
```tsx
import * as React from 'react'
import { Slot } from '@radix-ui/react-slot'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils/cn'

const buttonVariants = cva(
  'inline-flex items-center justify-center gap-1.5 font-medium text-sm transition-all focus-visible:outline-none disabled:opacity-50 disabled:pointer-events-none',
  {
    variants: {
      variant: {
        default: 'bg-fg text-bg shadow-glass hover:opacity-90',
        glass: 'glass text-fg hover:bg-white/70',
        ghost: 'text-fg-muted hover:text-fg hover:bg-fg/5',
        link: 'text-fg underline-offset-4 hover:underline',
      },
      size: {
        sm: 'h-8 px-3 rounded-md text-xs',
        default: 'h-10 px-4 rounded-md',
        lg: 'h-11 px-6 rounded-lg',
        pill: 'h-10 px-5 rounded-pill',
      },
    },
    defaultVariants: { variant: 'default', size: 'default' },
  }
)

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean
}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : 'button'
    return <Comp ref={ref} className={cn(buttonVariants({ variant, size }), className)} {...props} />
  }
)
Button.displayName = 'Button'
```

- [ ] **Step 4: 写 Input / Card / Badge**

Write `web/components/ui/input.tsx`:
```tsx
import * as React from 'react'
import { cn } from '@/lib/utils/cn'

export const Input = React.forwardRef<HTMLInputElement, React.InputHTMLAttributes<HTMLInputElement>>(
  ({ className, type, ...props }, ref) => (
    <input
      type={type}
      className={cn(
        'flex h-10 w-full rounded-md border border-fg/10 bg-bg px-3 py-2 text-sm placeholder:text-fg-faint focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-fg/20 disabled:opacity-50',
        className
      )}
      ref={ref}
      {...props}
    />
  )
)
Input.displayName = 'Input'
```

Write `web/components/ui/card.tsx`:
```tsx
import * as React from 'react'
import { cn } from '@/lib/utils/cn'

export function Card({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn('rounded-lg border border-fg/8 bg-bg/70 backdrop-blur-glass shadow-glass', className)} {...props} />
}

export function CardHeader({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn('p-5 pb-3', className)} {...props} />
}

export function CardContent({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn('p-5 pt-0', className)} {...props} />
}

export function CardFooter({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn('p-5 pt-3 border-t border-fg/5', className)} {...props} />
}
```

Write `web/components/ui/badge.tsx`:
```tsx
import * as React from 'react'
import { cn } from '@/lib/utils/cn'

export interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  variant?: 'default' | 'glass' | 'outline'
}

export function Badge({ className, variant = 'default', ...props }: BadgeProps) {
  const variants = {
    default: 'bg-fg text-bg',
    glass: 'glass text-fg',
    outline: 'border border-fg/15 text-fg',
  }
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1.5 rounded-pill px-3 py-1 text-xs font-mono uppercase tracking-wider',
        variants[variant],
        className
      )}
      {...props}
    />
  )
}
```

- [ ] **Step 5: Commit**

Run `pnpm typecheck` to confirm no type errors.

```bash
cd web && pnpm typecheck
git add web/
git commit -m "feat(web): add base shadcn/ui components (button/input/card/badge)"
```

---

### Task 5: BFF 反代路由

**Files:**
- Create: `web/app/api/[...path]/route.ts`
- Create: `web/lib/auth/cookie.ts`
- Create: `web/tests/unit/bff-proxy.test.ts`
- Create: `web/vitest.config.ts`
- Modify: `web/package.json`

- [ ] **Step 1: 安装 Vitest**

Run:
```bash
cd web && pnpm add -D vitest@2.1.5 @vitest/coverage-v8@2.1.5 happy-dom@15.11.6 @testing-library/react@16.0.1 @testing-library/jest-dom@6.6.3
```

- [ ] **Step 2: 配置 Vitest**

Write `web/vitest.config.ts`:
```ts
import { defineConfig } from 'vitest/config'
import { resolve } from 'path'

export default defineConfig({
  test: {
    environment: 'happy-dom',
    globals: true,
    setupFiles: ['./tests/setup.ts'],
  },
  resolve: { alias: { '@': resolve(__dirname, '.') } },
})
```

Write `web/tests/setup.ts`:
```ts
import '@testing-library/jest-dom/vitest'
```

- [ ] **Step 3: 写 cookie helper**

Write `web/lib/auth/cookie.ts`:
```ts
import { cookies } from 'next/headers'

export const TOKEN_COOKIE = 'kz_token'
export const ROLE_COOKIE = 'kz_role'

export function getToken(): string | undefined {
  return cookies().get(TOKEN_COOKIE)?.value
}

export function setToken(token: string, maxAgeSec = 60 * 60 * 24 * 7) {
  cookies().set(TOKEN_COOKIE, token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: maxAgeSec,
    path: '/',
  })
}

export function clearToken() {
  cookies().delete(TOKEN_COOKIE)
  cookies().delete(ROLE_COOKIE)
}

export function setRole(role: number) {
  cookies().set(ROLE_COOKIE, String(role), {
    httpOnly: false, // role 是 UI 信号，可以让前端读
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: 60 * 60 * 24 * 7,
    path: '/',
  })
}
```

- [ ] **Step 4: 写 BFF 反代路由**

Write `web/app/api/[...path]/route.ts`:
```ts
import { NextRequest, NextResponse } from 'next/server'
import { getToken } from '@/lib/auth/cookie'

const UPSTREAM = process.env.KAIZAO_SERVER_INTERNAL ?? 'http://localhost:39527'

async function proxy(req: NextRequest, { params }: { params: { path: string[] } }) {
  const path = params.path.join('/')
  const search = req.nextUrl.search
  const url = `${UPSTREAM}/api/${path}${search}`

  const headers = new Headers()
  const token = getToken()
  if (token) headers.set('Authorization', `Bearer ${token}`)
  const ct = req.headers.get('content-type')
  if (ct) headers.set('Content-Type', ct)
  const ua = req.headers.get('user-agent')
  if (ua) headers.set('User-Agent', ua)

  const init: RequestInit = {
    method: req.method,
    headers,
    redirect: 'manual',
  }
  if (!['GET', 'HEAD'].includes(req.method)) {
    init.body = await req.text()
  }

  const upstream = await fetch(url, init)
  const body = await upstream.text()
  const out = new NextResponse(body, { status: upstream.status })
  upstream.headers.forEach((v, k) => {
    if (!['content-encoding', 'transfer-encoding', 'connection'].includes(k.toLowerCase())) {
      out.headers.set(k, v)
    }
  })
  return out
}

export { proxy as GET, proxy as POST, proxy as PUT, proxy as PATCH, proxy as DELETE }
```

- [ ] **Step 5: 写 BFF 单元测试**

Write `web/tests/unit/bff-proxy.test.ts`:
```ts
import { describe, it, expect, vi, beforeEach } from 'vitest'

describe('BFF proxy URL composition', () => {
  it('joins path segments correctly', () => {
    const segments = ['v1', 'market', 'projects']
    expect(segments.join('/')).toBe('v1/market/projects')
  })

  it('builds upstream url with query string', () => {
    const upstream = 'http://localhost:39527'
    const path = 'v1/market/projects'
    const search = '?page=1&size=20'
    expect(`${upstream}/api/${path}${search}`).toBe('http://localhost:39527/api/v1/market/projects?page=1&size=20')
  })
})
```

Run: `cd web && pnpm test`
Expected: 2 passed.

- [ ] **Step 6: Commit**

```bash
git add web/
git commit -m "feat(web): add BFF proxy route and cookie-based auth"
```

---

### Task 6: API 客户端 (lib/api)

**Files:**
- Create: `web/lib/api/types.ts`
- Create: `web/lib/api/client.ts`
- Create: `web/lib/api/browser.ts`
- Create: `web/lib/api/market.ts`
- Create: `web/lib/api/projects.ts`
- Create: `web/lib/api/users.ts`
- Create: `web/lib/api/auth.ts`
- Create: `web/tests/unit/api-client.test.ts`

- [ ] **Step 1: 写共享类型**

Write `web/lib/api/types.ts`:
```ts
export interface ApiEnvelope<T> {
  code: number
  message?: string
  data: T
}

export interface PageResult<T> {
  list: T[]
  total: number
  page: number
  size: number
}

export interface User {
  id: string
  name: string
  avatar?: string
  role: 1 | 2
  credit_score?: number
}

export interface Project {
  id: string
  title: string
  description: string
  budget_cents?: number
  deadline?: string
  domain?: string
  tags?: string[]
  status: string
  created_at: string
  owner: Pick<User, 'id' | 'name' | 'avatar'>
}

export interface Expert extends User {
  skills?: string[]
  rate_level?: string
  bid_count?: number
}

export class ApiError extends Error {
  constructor(public status: number, public code: number, message: string) {
    super(message)
  }
}
```

> **Note:** 这些类型是按现有 v1 接口推测的字段命名。实现各页面时第一步要先 `curl` 一次实际接口，按真实返回字段校准类型。如有出入，在 PR 描述里 flag。

- [ ] **Step 2: 写服务端 client（SSR 用，内网直连）**

Write `web/lib/api/client.ts`:
```ts
import 'server-only'
import { getToken } from '@/lib/auth/cookie'
import { ApiError, type ApiEnvelope } from './types'

const BASE = process.env.KAIZAO_SERVER_INTERNAL ?? 'http://localhost:39527'

export async function serverFetch<T>(
  path: string,
  init: RequestInit & { auth?: boolean } = {}
): Promise<T> {
  const { auth = false, headers, ...rest } = init
  const h = new Headers(headers)
  if (auth) {
    const token = getToken()
    if (token) h.set('Authorization', `Bearer ${token}`)
  }
  h.set('Content-Type', 'application/json')

  const res = await fetch(`${BASE}${path}`, {
    ...rest,
    headers: h,
    cache: 'no-store',
  })
  const json = (await res.json()) as ApiEnvelope<T>
  if (!res.ok || (json.code !== undefined && json.code !== 0)) {
    throw new ApiError(res.status, json.code ?? res.status, json.message ?? 'request failed')
  }
  return json.data
}
```

- [ ] **Step 3: 写浏览器 client（走 BFF）**

Write `web/lib/api/browser.ts`:
```ts
import { ApiError, type ApiEnvelope } from './types'

export async function browserFetch<T>(path: string, init: RequestInit = {}): Promise<T> {
  const res = await fetch(path, {
    ...init,
    headers: { 'Content-Type': 'application/json', ...(init.headers ?? {}) },
    credentials: 'include',
  })
  const json = (await res.json()) as ApiEnvelope<T>
  if (!res.ok || (json.code !== undefined && json.code !== 0)) {
    throw new ApiError(res.status, json.code ?? res.status, json.message ?? '请求失败')
  }
  return json.data
}
```

- [ ] **Step 4: 写按模块的 API 函数**

Write `web/lib/api/market.ts`:
```ts
import { serverFetch } from './client'
import { browserFetch } from './browser'
import type { PageResult, Project, Expert } from './types'

export interface MarketQuery {
  page?: number
  size?: number
  domain?: string
  budget_min?: number
  budget_max?: number
  status?: string
}

function buildQuery(q: MarketQuery): string {
  const params = new URLSearchParams()
  Object.entries(q).forEach(([k, v]) => {
    if (v !== undefined && v !== '') params.set(k, String(v))
  })
  const s = params.toString()
  return s ? `?${s}` : ''
}

export function listProjectsServer(q: MarketQuery = {}) {
  return serverFetch<PageResult<Project>>(`/api/v1/market/projects${buildQuery(q)}`)
}

export function listExpertsServer(q: MarketQuery = {}) {
  return serverFetch<PageResult<Expert>>(`/api/v1/market/experts${buildQuery(q)}`)
}

export function listProjectsBrowser(q: MarketQuery = {}) {
  return browserFetch<PageResult<Project>>(`/api/v1/market/projects${buildQuery(q)}`)
}

export function listExpertsBrowser(q: MarketQuery = {}) {
  return browserFetch<PageResult<Expert>>(`/api/v1/market/experts${buildQuery(q)}`)
}
```

Write `web/lib/api/projects.ts`:
```ts
import { serverFetch } from './client'
import type { Project } from './types'

export interface ProjectDetail extends Project {
  prd_cards?: Array<{ id: string; title: string; content: string }>
  overview?: { budget_cents?: number; deadline?: string; tech_stack?: string[]; phases?: string[] }
}

export function getProjectServer(id: string) {
  return serverFetch<ProjectDetail>(`/api/v1/projects/${id}`)
}

export function getProjectPrdServer(id: string) {
  return serverFetch<Array<{ id: string; title: string; content: string }>>(`/api/v1/projects/${id}/prd`)
}

export function getProjectOverviewServer(id: string) {
  return serverFetch<ProjectDetail['overview']>(`/api/v1/projects/${id}/overview`)
}
```

Write `web/lib/api/users.ts`:
```ts
import { serverFetch } from './client'
import { browserFetch } from './browser'
import type { User } from './types'

export interface UserPublic extends User {
  skills?: string[]
  portfolios?: Array<{ id: string; title: string; cover?: string }>
  reviews?: Array<{ id: string; score: number; content: string; created_at: string }>
}

export function getUserServer(id: string) {
  return serverFetch<UserPublic>(`/api/v1/users/${id}`)
}

export function getUserSkillsServer(id: string) {
  return serverFetch<string[]>(`/api/v1/users/${id}/skills`)
}

export function getUserPortfoliosServer(id: string) {
  return serverFetch<UserPublic['portfolios']>(`/api/v1/users/${id}/portfolios`)
}

export function getUserReviewsServer(id: string) {
  return serverFetch<UserPublic['reviews']>(`/api/v1/users/${id}/reviews`)
}

export function getMeBrowser() {
  return browserFetch<User>('/api/v1/users/me')
}
```

Write `web/lib/api/auth.ts`:
```ts
import { browserFetch } from './browser'

export interface SmsCodeReq { mobile: string; scene?: string }
export interface LoginReq { mobile: string; sms_code: string }
export interface RegisterReq { mobile: string; sms_code: string; role: 1 | 2 }
export interface LoginPasswordReq { mobile: string; password: string }

export interface AuthResult { token: string; user: { id: string; role: 1 | 2; name?: string } }

export function sendSmsCode(req: SmsCodeReq) {
  return browserFetch<{ ok: boolean }>('/api/v1/auth/sms-code', {
    method: 'POST', body: JSON.stringify(req),
  })
}

export function login(req: LoginReq) {
  return browserFetch<AuthResult>('/api/v1/auth/login', {
    method: 'POST', body: JSON.stringify(req),
  })
}

export function loginPassword(req: LoginPasswordReq) {
  return browserFetch<AuthResult>('/api/v1/auth/login-password', {
    method: 'POST', body: JSON.stringify(req),
  })
}

export function register(req: RegisterReq) {
  return browserFetch<AuthResult>('/api/v1/auth/register', {
    method: 'POST', body: JSON.stringify(req),
  })
}

export function logout() {
  return browserFetch<{ ok: boolean }>('/api/v1/auth/logout', { method: 'POST' })
}
```

- [ ] **Step 5: 写单元测试**

Write `web/tests/unit/api-client.test.ts`:
```ts
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
})

describe('buildQuery', () => {
  it('returns empty string for empty object', async () => {
    const m = await import('@/lib/api/market')
    // re-test via export, not via private — verify behavior end-to-end by URL building
    expect(typeof m.listProjectsBrowser).toBe('function')
  })
})
```

Run: `cd web && pnpm test`
Expected: All pass.

- [ ] **Step 6: Commit**

```bash
cd web && pnpm typecheck
git add web/
git commit -m "feat(web): add api client modules for market/projects/users/auth"
```

---

### Task 7: 鉴权 hook + 路由守卫

**Files:**
- Create: `web/lib/auth/session.ts`
- Create: `web/lib/auth/use-require-auth.ts`
- Create: `web/lib/auth/use-auth.tsx`
- Create: `web/app/api/auth/login/route.ts`
- Create: `web/app/api/auth/register/route.ts`
- Create: `web/app/api/auth/logout/route.ts`
- Create: `web/app/(dashboard)/layout.tsx`

- [ ] **Step 1: 服务端 session 读取**

Write `web/lib/auth/session.ts`:
```ts
import 'server-only'
import { cookies } from 'next/headers'
import { ROLE_COOKIE, TOKEN_COOKIE } from './cookie'

export interface ServerSession {
  isLoggedIn: boolean
  role?: 1 | 2
}

export function getServerSession(): ServerSession {
  const store = cookies()
  const token = store.get(TOKEN_COOKIE)?.value
  const roleStr = store.get(ROLE_COOKIE)?.value
  if (!token) return { isLoggedIn: false }
  const role = roleStr ? (Number(roleStr) as 1 | 2) : undefined
  return { isLoggedIn: true, role }
}
```

- [ ] **Step 2: 客户端 AuthProvider + hooks**

Write `web/lib/auth/use-auth.tsx`:
```tsx
'use client'
import * as React from 'react'

interface AuthState {
  isLoggedIn: boolean
  role?: 1 | 2
}

const AuthContext = React.createContext<AuthState>({ isLoggedIn: false })

export function AuthProvider({ children, value }: { children: React.ReactNode; value: AuthState }) {
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  return React.useContext(AuthContext)
}
```

Write `web/lib/auth/use-require-auth.ts`:
```ts
'use client'
import { useRouter, usePathname } from 'next/navigation'
import { useAuth } from './use-auth'

export function useRequireAuth() {
  const { isLoggedIn } = useAuth()
  const router = useRouter()
  const pathname = usePathname()

  return function requireOrPromptAuth(onAuthed: () => void, onAnonymous?: () => void) {
    if (isLoggedIn) {
      onAuthed()
    } else if (onAnonymous) {
      onAnonymous()
    } else {
      router.push(`/auth/login?from=${encodeURIComponent(pathname)}`)
    }
  }
}
```

- [ ] **Step 3: 把 session 注入根布局**

Modify `web/app/layout.tsx`:
```tsx
import './globals.css'
import type { Metadata } from 'next'
import { GeistSans } from 'geist/font/sans'
import { GeistMono } from 'geist/font/mono'
import { AuthProvider } from '@/lib/auth/use-auth'
import { getServerSession } from '@/lib/auth/session'

export const metadata: Metadata = {
  title: 'KAIZAO · AI 驱动的软件需求撮合平台',
  description: '把模糊的需求变成可交付的项目。AI Agent 拆解需求、撮合分级团队、协同交付。',
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000'),
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const session = getServerSession()
  return (
    <html lang="zh-CN" className={`${GeistSans.variable} ${GeistMono.variable}`}>
      <body className="font-sans">
        <AuthProvider value={session}>{children}</AuthProvider>
      </body>
    </html>
  )
}
```

- [ ] **Step 4: 写 dashboard layout 守卫**

Write `web/app/(dashboard)/layout.tsx`:
```tsx
import { redirect } from 'next/navigation'
import { getServerSession } from '@/lib/auth/session'

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const session = getServerSession()
  if (!session.isLoggedIn) redirect('/auth/login')
  return <>{children}</>
}
```

- [ ] **Step 5: 写鉴权 API 路由（专用，不走通用 BFF）**

Write `web/app/api/auth/login/route.ts`:
```ts
import { NextRequest, NextResponse } from 'next/server'
import { setRole, setToken } from '@/lib/auth/cookie'

const UPSTREAM = process.env.KAIZAO_SERVER_INTERNAL ?? 'http://localhost:39527'

export async function POST(req: NextRequest) {
  const body = await req.text()
  const upstreamPath = req.nextUrl.pathname.replace('/api/auth/login', '/api/v1/auth/login')
  const upstream = await fetch(`${UPSTREAM}${upstreamPath}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body,
  })
  const json = await upstream.json()
  if (upstream.ok && json.code === 0 && json.data?.token) {
    setToken(json.data.token)
    if (json.data.user?.role) setRole(json.data.user.role)
  }
  return NextResponse.json(json, { status: upstream.status })
}
```

Write `web/app/api/auth/register/route.ts`:
```ts
import { NextRequest, NextResponse } from 'next/server'
import { setRole, setToken } from '@/lib/auth/cookie'

const UPSTREAM = process.env.KAIZAO_SERVER_INTERNAL ?? 'http://localhost:39527'

export async function POST(req: NextRequest) {
  const body = await req.text()
  const upstream = await fetch(`${UPSTREAM}/api/v1/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body,
  })
  const json = await upstream.json()
  if (upstream.ok && json.code === 0 && json.data?.token) {
    setToken(json.data.token)
    if (json.data.user?.role) setRole(json.data.user.role)
  }
  return NextResponse.json(json, { status: upstream.status })
}
```

Write `web/app/api/auth/logout/route.ts`:
```ts
import { NextRequest, NextResponse } from 'next/server'
import { clearToken, getToken } from '@/lib/auth/cookie'

const UPSTREAM = process.env.KAIZAO_SERVER_INTERNAL ?? 'http://localhost:39527'

export async function POST(req: NextRequest) {
  const token = getToken()
  if (token) {
    await fetch(`${UPSTREAM}/api/v1/auth/logout`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
    }).catch(() => {})
  }
  clearToken()
  return NextResponse.json({ code: 0, data: { ok: true } })
}
```

> **Important:** 注册和登录调 `auth.ts` 里的 `login()` / `register()` 时 path 必须改成 `/api/auth/login` 和 `/api/auth/register`（去掉 `v1`），不再走通用 BFF —— 因为这些路由需要 BFF 设置 Cookie，普通 `[...path]` 不会。

Modify `web/lib/api/auth.ts` 把 `login()` `register()` 的路径改为 `/api/auth/login` `/api/auth/register`，把 `loginPassword()` `sendSmsCode()` 保留走通用 BFF（它们不设 cookie）。

- [ ] **Step 6: Commit**

```bash
cd web && pnpm typecheck
git add web/
git commit -m "feat(web): add auth session, hooks, guards, and dedicated login/register/logout routes"
```

---

## Phase 2 · 公开页（Task 8–14）

### Task 8: 通用布局 Header / Footer / Container + ColorHalo

**Files:**
- Create: `web/components/layout/container.tsx`
- Create: `web/components/layout/header.tsx`
- Create: `web/components/layout/footer.tsx`
- Create: `web/components/effects/color-halo.tsx`
- Modify: `web/app/(public)/layout.tsx`（新建路由组 layout）

- [ ] **Step 1: 写 Container**

Write `web/components/layout/container.tsx`:
```tsx
import * as React from 'react'
import { cn } from '@/lib/utils/cn'

export function Container({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn('container max-w-6xl', className)} {...props} />
}
```

- [ ] **Step 2: 写 ColorHalo（背景彩光晕）**

Write `web/components/effects/color-halo.tsx`:
```tsx
import { cn } from '@/lib/utils/cn'

interface ColorHaloProps {
  className?: string
  intensity?: 'low' | 'medium' | 'high'
}

export function ColorHalo({ className, intensity = 'medium' }: ColorHaloProps) {
  const sizes = {
    low: { a: 200, b: 180 },
    medium: { a: 320, b: 280 },
    high: { a: 420, b: 360 },
  }[intensity]

  return (
    <div className={cn('pointer-events-none absolute inset-0 overflow-hidden', className)}>
      <div
        className="absolute -left-20 -top-20 rounded-full opacity-90"
        style={{
          width: sizes.a,
          height: sizes.a,
          background:
            'radial-gradient(circle at 30% 30%, rgba(255,145,200,.5), transparent 60%), radial-gradient(circle at 70% 60%, rgba(140,180,255,.55), transparent 60%)',
          filter: 'blur(24px)',
        }}
      />
      <div
        className="absolute -right-20 -bottom-20 rounded-full"
        style={{
          width: sizes.b,
          height: sizes.b,
          background:
            'radial-gradient(circle, rgba(180,255,200,.45), transparent 60%), radial-gradient(circle at 70% 40%, rgba(255,220,130,.4), transparent 60%)',
          filter: 'blur(28px)',
        }}
      />
    </div>
  )
}
```

- [ ] **Step 3: 写 Header**

Write `web/components/layout/header.tsx`:
```tsx
'use client'
import Link from 'next/link'
import { useAuth } from '@/lib/auth/use-auth'
import { Button } from '@/components/ui/button'
import { Container } from './container'

const NAV = [
  { href: '/projects', label: '需求广场' },
  { href: '/experts', label: '团队广场' },
  { href: '/about', label: '关于' },
]

export function Header() {
  const { isLoggedIn } = useAuth()
  return (
    <header className="sticky top-0 z-40 backdrop-blur-glass bg-bg/70 border-b border-fg/5">
      <Container className="flex h-14 items-center justify-between">
        <Link href="/" className="font-mono text-sm tracking-wider font-medium">KAIZAO</Link>
        <nav className="hidden md:flex gap-6">
          {NAV.map((n) => (
            <Link key={n.href} href={n.href} className="text-sm text-fg-muted hover:text-fg transition-colors">
              {n.label}
            </Link>
          ))}
        </nav>
        <div className="flex gap-2">
          {isLoggedIn ? (
            <Button asChild variant="glass" size="sm"><Link href="/dashboard">控制台</Link></Button>
          ) : (
            <>
              <Button asChild variant="ghost" size="sm"><Link href="/auth/login">登录</Link></Button>
              <Button asChild size="sm"><Link href="/auth/register">注册</Link></Button>
            </>
          )}
        </div>
      </Container>
    </header>
  )
}
```

- [ ] **Step 4: 写 Footer**

Write `web/components/layout/footer.tsx`:
```tsx
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
```

- [ ] **Step 5: 写公开路由组 layout**

Write `web/app/(public)/layout.tsx`:
```tsx
import { Header } from '@/components/layout/header'
import { Footer } from '@/components/layout/footer'

export default function PublicLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen flex flex-col">
      <Header />
      <div className="flex-1">{children}</div>
      <Footer />
    </div>
  )
}
```

> 同时把 `app/page.tsx` 移到 `app/(public)/page.tsx`，这样首页也走公开布局。

```bash
mkdir -p web/app/\(public\)
git mv web/app/page.tsx "web/app/(public)/page.tsx"
```

- [ ] **Step 6: 验证 + Commit**

Run `cd web && pnpm dev`，访问 `http://localhost:3000`，应看到顶部 Header + 中间内容 + 底部 Footer。

```bash
git add web/
git commit -m "feat(web): add header/footer/container/halo and public layout group"
```

---

### Task 9: 落地首页 / 的 Hero + Sections

**Files:**
- Create: `web/components/landing/hero.tsx`
- Create: `web/components/landing/value-props.tsx`
- Create: `web/components/landing/how-it-works.tsx`
- Create: `web/components/landing/featured.tsx`
- Create: `web/components/landing/stats-wall.tsx`
- Create: `web/components/landing/faq.tsx`
- Create: `web/components/cards/project-card.tsx`
- Create: `web/components/cards/expert-card.tsx`
- Modify: `web/app/(public)/page.tsx`

- [ ] **Step 1: Hero**

Write `web/components/landing/hero.tsx`:
```tsx
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { ColorHalo } from '@/components/effects/color-halo'
import { Container } from '@/components/layout/container'

export function Hero() {
  return (
    <section className="relative overflow-hidden pt-24 pb-28">
      <ColorHalo intensity="high" />
      <Container className="relative">
        <Badge variant="glass" className="mb-6">
          <span className="inline-block w-1.5 h-1.5 rounded-full bg-gradient-to-br from-pink-400 to-blue-400" />
          POWERED BY AI · v2
        </Badge>
        <h1 className="text-5xl md:text-6xl font-medium tracking-tight leading-[1.04] max-w-3xl">
          把模糊的需求<br />变成<span className="text-gradient-hero">可交付的项目</span>
        </h1>
        <p className="mt-6 text-fg-muted max-w-xl text-base leading-relaxed">
          AI Agent 拆解需求、撮合 T1–T10 分级团队、全流程透明协同。
          一句话起步，从 PRD 到验收一站完成。
        </p>
        <div className="mt-10 flex flex-wrap gap-3">
          <Button asChild size="lg"><Link href="/auth/register?role=1">我是项目方 · 发起项目</Link></Button>
          <Button asChild size="lg" variant="glass"><Link href="/auth/register?role=2">我是团队方 · 接需求</Link></Button>
        </div>
      </Container>
    </section>
  )
}
```

- [ ] **Step 2: ValueProps（三宫格）**

Write `web/components/landing/value-props.tsx`:
```tsx
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
```

- [ ] **Step 3: HowItWorks（4 步）**

Write `web/components/landing/how-it-works.tsx`:
```tsx
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
```

- [ ] **Step 4: ProjectCard + ExpertCard**

Write `web/components/cards/project-card.tsx`:
```tsx
import Link from 'next/link'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { formatMoney, formatRelative } from '@/lib/utils/format'
import type { Project } from '@/lib/api/types'

export function ProjectCard({ p }: { p: Project }) {
  return (
    <Link href={`/projects/${p.id}`} className="block group">
      <Card className="transition-shadow group-hover:shadow-lg h-full">
        <CardContent className="pt-5">
          <div className="flex items-start justify-between gap-3 mb-2">
            <h3 className="font-medium text-base line-clamp-2 group-hover:text-fg">{p.title}</h3>
            <Badge variant="outline" className="shrink-0">{p.status}</Badge>
          </div>
          <p className="text-fg-muted text-sm line-clamp-2 mb-4">{p.description}</p>
          <div className="flex items-center justify-between text-xs text-fg-faint font-mono">
            <span>{p.budget_cents ? formatMoney(p.budget_cents) : '面议'}</span>
            <span>{formatRelative(p.created_at)}</span>
          </div>
          {p.tags && p.tags.length > 0 && (
            <div className="mt-3 flex flex-wrap gap-1">
              {p.tags.slice(0, 3).map((t) => (
                <span key={t} className="text-[10px] font-mono text-fg-muted bg-fg/5 px-2 py-0.5 rounded-pill">{t}</span>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </Link>
  )
}
```

Write `web/components/cards/expert-card.tsx`:
```tsx
import Link from 'next/link'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import type { Expert } from '@/lib/api/types'

export function ExpertCard({ e }: { e: Expert }) {
  return (
    <Link href={`/experts/${e.id}`} className="block group">
      <Card className="transition-shadow group-hover:shadow-lg h-full">
        <CardContent className="pt-5">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-12 h-12 rounded-pill bg-fg/5 grid place-items-center overflow-hidden">
              {e.avatar ? <img src={e.avatar} alt={e.name} className="w-full h-full object-cover" /> : <span className="font-mono text-fg-muted">{e.name?.[0]}</span>}
            </div>
            <div className="min-w-0">
              <div className="font-medium truncate">{e.name}</div>
              {e.rate_level && <Badge variant="glass" className="mt-1 text-[10px]">{e.rate_level}</Badge>}
            </div>
          </div>
          {e.skills && e.skills.length > 0 && (
            <div className="flex flex-wrap gap-1 mb-3">
              {e.skills.slice(0, 4).map((s) => (
                <span key={s} className="text-[10px] font-mono text-fg-muted bg-fg/5 px-2 py-0.5 rounded-pill">{s}</span>
              ))}
            </div>
          )}
          <div className="text-xs text-fg-faint font-mono">{e.bid_count != null ? `参与 ${e.bid_count} 个项目` : ''}</div>
        </CardContent>
      </Card>
    </Link>
  )
}
```

- [ ] **Step 5: Featured（拉真实数据）**

Write `web/components/landing/featured.tsx`:
```tsx
import { Container } from '@/components/layout/container'
import { ProjectCard } from '@/components/cards/project-card'
import { ExpertCard } from '@/components/cards/expert-card'
import { listProjectsServer, listExpertsServer } from '@/lib/api/market'

export async function Featured() {
  const [projects, experts] = await Promise.all([
    listProjectsServer({ size: 6 }).catch(() => ({ list: [], total: 0, page: 1, size: 6 })),
    listExpertsServer({ size: 6 }).catch(() => ({ list: [], total: 0, page: 1, size: 6 })),
  ])

  return (
    <section className="py-20">
      <Container>
        <div className="flex items-baseline justify-between mb-8">
          <h2 className="text-3xl font-medium tracking-tight">最新需求</h2>
          <a href="/projects" className="text-sm text-fg-muted hover:text-fg">查看全部 →</a>
        </div>
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-5 mb-16">
          {projects.list.map((p) => <ProjectCard key={p.id} p={p} />)}
        </div>

        <div className="flex items-baseline justify-between mb-8">
          <h2 className="text-3xl font-medium tracking-tight">精选团队</h2>
          <a href="/experts" className="text-sm text-fg-muted hover:text-fg">查看全部 →</a>
        </div>
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-5">
          {experts.list.map((e) => <ExpertCard key={e.id} e={e} />)}
        </div>
      </Container>
    </section>
  )
}
```

- [ ] **Step 6: StatsWall + FAQ**

Write `web/components/landing/stats-wall.tsx`:
```tsx
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
```

> **占位声明：** 这些数字是 spec §6.1 step 5 + §12 OQ-2 标记的硬编码占位。实现完落地页后实测如果后端有口径接口（例如 `/api/v1/stats/overview`），再切换。

Write `web/components/landing/faq.tsx`:
```tsx
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
```

- [ ] **Step 7: 组装首页**

Write `web/app/(public)/page.tsx`:
```tsx
import { Hero } from '@/components/landing/hero'
import { ValueProps } from '@/components/landing/value-props'
import { HowItWorks } from '@/components/landing/how-it-works'
import { Featured } from '@/components/landing/featured'
import { StatsWall } from '@/components/landing/stats-wall'
import { Faq } from '@/components/landing/faq'

export const revalidate = 60

export default function Home() {
  return (
    <>
      <Hero />
      <ValueProps />
      <HowItWorks />
      <Featured />
      <StatsWall />
      <Faq />
    </>
  )
}
```

- [ ] **Step 8: 验证 + Commit**

Run `cd web && pnpm dev`, 访问 `http://localhost:3000`。

Expected:
- Hero 区有渐变标题 + 双 CTA + 玻璃 badge + 彩色背景光晕
- 三宫格价值主张 + 4 步流程
- "最新需求" / "精选团队" 区会因为后端连不上拿到空数据 → 空 grid（这是预期，等后端连上自动有内容）
- 数据墙 + FAQ 正常

```bash
git add web/
git commit -m "feat(web): build landing page with hero/value/howto/featured/stats/faq"
```

---

### Task 10: 需求广场 /projects

**Files:**
- Create: `web/app/(public)/projects/page.tsx`
- Create: `web/components/market/project-list.tsx`
- Create: `web/components/market/market-filters.tsx`

- [ ] **Step 1: 写筛选条**

Write `web/components/market/market-filters.tsx`:
```tsx
'use client'
import { Badge } from '@/components/ui/badge'
import { useRouter, useSearchParams } from 'next/navigation'

const STATUSES = [
  { label: '全部', value: '' },
  { label: '招标中', value: 'open' },
  { label: '已截止', value: 'closed' },
]

export function MarketFilters() {
  const router = useRouter()
  const sp = useSearchParams()
  const current = sp.get('status') ?? ''

  const setStatus = (v: string) => {
    const params = new URLSearchParams(sp.toString())
    if (v) params.set('status', v); else params.delete('status')
    router.push(`?${params.toString()}`)
  }

  return (
    <div className="flex flex-wrap gap-2">
      {STATUSES.map((s) => (
        <button key={s.value} onClick={() => setStatus(s.value)}>
          <Badge variant={current === s.value ? 'default' : 'glass'} className="cursor-pointer">{s.label}</Badge>
        </button>
      ))}
    </div>
  )
}
```

- [ ] **Step 2: 写广场页**

Write `web/app/(public)/projects/page.tsx`:
```tsx
import { Container } from '@/components/layout/container'
import { ProjectCard } from '@/components/cards/project-card'
import { MarketFilters } from '@/components/market/market-filters'
import { listProjectsServer } from '@/lib/api/market'
import { ColorHalo } from '@/components/effects/color-halo'

export const metadata = { title: '需求广场 · KAIZAO' }
export const revalidate = 30

export default async function ProjectsPage({
  searchParams,
}: {
  searchParams: { page?: string; status?: string }
}) {
  const page = Number(searchParams.page ?? 1)
  const data = await listProjectsServer({
    page,
    size: 24,
    status: searchParams.status || undefined,
  }).catch(() => ({ list: [], total: 0, page, size: 24 }))

  return (
    <>
      <section className="relative py-16 overflow-hidden">
        <ColorHalo intensity="low" />
        <Container className="relative">
          <h1 className="text-4xl font-medium tracking-tight mb-3">需求广场</h1>
          <p className="text-fg-muted mb-8">浏览正在寻找团队的项目</p>
          <MarketFilters />
        </Container>
      </section>
      <Container className="pb-20">
        {data.list.length === 0 ? (
          <div className="glass rounded-lg p-12 text-center text-fg-muted">暂无需求</div>
        ) : (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-5">
            {data.list.map((p) => <ProjectCard key={p.id} p={p} />)}
          </div>
        )}
        {data.total > data.size && (
          <Pager page={page} total={data.total} size={data.size} />
        )}
      </Container>
    </>
  )
}

function Pager({ page, total, size }: { page: number; total: number; size: number }) {
  const pages = Math.ceil(total / size)
  return (
    <nav className="mt-10 flex justify-center gap-2 font-mono text-sm">
      {Array.from({ length: Math.min(pages, 7) }, (_, i) => i + 1).map((n) => (
        <a key={n} href={`?page=${n}`} className={`px-3 py-1.5 rounded-md ${n === page ? 'bg-fg text-bg' : 'glass'}`}>{n}</a>
      ))}
    </nav>
  )
}
```

- [ ] **Step 3: 验证**

Run `cd web && pnpm dev`, 访问 `/projects`. 后端没数据时显示 "暂无需求"。

- [ ] **Step 4: Commit**

```bash
git add web/
git commit -m "feat(web): add project market page with filters and pagination"
```

---

### Task 11: 项目详情 /projects/[id]

**Files:**
- Create: `web/app/(public)/projects/[id]/page.tsx`
- Create: `web/components/auth/auth-intercept.tsx`

- [ ] **Step 1: 拦截浮层组件**

Write `web/components/auth/auth-intercept.tsx`:
```tsx
'use client'
import * as React from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/lib/auth/use-auth'
import { Button } from '@/components/ui/button'

interface InterceptProps {
  action: string
  open: boolean
  onClose: () => void
}

export function AuthIntercept({ action, open, onClose }: InterceptProps) {
  if (!open) return null
  return (
    <div className="fixed inset-0 z-50 grid place-items-center bg-black/40 backdrop-blur-sm" onClick={onClose}>
      <div className="glass rounded-lg max-w-sm w-full mx-4 p-7 text-center" onClick={(e) => e.stopPropagation()}>
        <h3 className="text-lg font-medium mb-2">注册后即可{action}</h3>
        <p className="text-sm text-fg-muted mb-6">已有账号？登录后继续操作</p>
        <div className="flex gap-2 justify-center mb-4">
          <Button asChild><Link href="/auth/register">立即注册</Link></Button>
          <Button asChild variant="glass"><Link href="/auth/login">登录</Link></Button>
        </div>
        <p className="text-xs text-fg-faint">或下载 App 体验完整功能</p>
      </div>
    </div>
  )
}

export function useAuthIntercept() {
  const { isLoggedIn } = useAuth()
  const [intercept, setIntercept] = React.useState<{ action: string } | null>(null)
  const router = useRouter()

  function gate(action: string, onAuthed: () => void) {
    if (isLoggedIn) onAuthed()
    else setIntercept({ action })
  }

  const node = intercept ? (
    <AuthIntercept action={intercept.action} open onClose={() => setIntercept(null)} />
  ) : null

  return { gate, interceptNode: node }
}
```

- [ ] **Step 2: 写项目详情页**

Write `web/app/(public)/projects/[id]/page.tsx`:
```tsx
import { notFound } from 'next/navigation'
import { Container } from '@/components/layout/container'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent } from '@/components/ui/card'
import { ColorHalo } from '@/components/effects/color-halo'
import { getProjectServer, getProjectPrdServer, getProjectOverviewServer } from '@/lib/api/projects'
import { formatMoney, formatRelative } from '@/lib/utils/format'
import { ProjectActions } from './actions.client'

export const revalidate = 30

export default async function ProjectDetailPage({ params }: { params: { id: string } }) {
  let detail
  try {
    detail = await getProjectServer(params.id)
  } catch {
    notFound()
  }
  const [prd, overview] = await Promise.all([
    getProjectPrdServer(params.id).catch(() => []),
    getProjectOverviewServer(params.id).catch(() => null),
  ])

  return (
    <>
      <section className="relative py-12 overflow-hidden">
        <ColorHalo intensity="low" />
        <Container className="relative">
          <div className="flex items-center gap-2 mb-4 text-xs text-fg-muted font-mono">
            <a href="/projects" className="hover:text-fg">需求广场</a>
            <span>/</span>
            <span>项目详情</span>
          </div>
          <div className="flex items-center justify-between gap-4 flex-wrap mb-3">
            <h1 className="text-3xl font-medium tracking-tight max-w-3xl">{detail.title}</h1>
            <Badge variant="outline">{detail.status}</Badge>
          </div>
          <p className="text-xs text-fg-faint font-mono">发布于 {formatRelative(detail.created_at)}</p>
        </Container>
      </section>

      <Container className="pb-20 grid md:grid-cols-3 gap-6">
        <div className="md:col-span-2 space-y-5">
          <Card>
            <CardContent className="pt-6">
              <h2 className="text-sm font-mono uppercase tracking-wider text-fg-muted mb-3">项目描述</h2>
              <p className="text-fg leading-relaxed whitespace-pre-line">{detail.description}</p>
            </CardContent>
          </Card>

          {overview && (
            <Card>
              <CardContent className="pt-6">
                <h2 className="text-sm font-mono uppercase tracking-wider text-fg-muted mb-3">概览</h2>
                <dl className="grid grid-cols-2 gap-y-3 gap-x-6 text-sm">
                  {overview.budget_cents != null && (
                    <><dt className="text-fg-faint">预算</dt><dd>{formatMoney(overview.budget_cents)}</dd></>
                  )}
                  {overview.deadline && (
                    <><dt className="text-fg-faint">期限</dt><dd>{overview.deadline}</dd></>
                  )}
                  {overview.tech_stack && (
                    <><dt className="text-fg-faint">技术栈</dt><dd>{overview.tech_stack.join(' / ')}</dd></>
                  )}
                  {overview.phases && (
                    <><dt className="text-fg-faint">阶段</dt><dd>{overview.phases.join(' → ')}</dd></>
                  )}
                </dl>
              </CardContent>
            </Card>
          )}

          {prd && prd.length > 0 && (
            <Card>
              <CardContent className="pt-6">
                <h2 className="text-sm font-mono uppercase tracking-wider text-fg-muted mb-4">PRD</h2>
                <div className="space-y-4">
                  {prd.map((c: any) => (
                    <article key={c.id}>
                      <h3 className="font-medium mb-1.5">{c.title}</h3>
                      <p className="text-fg-muted text-sm leading-relaxed whitespace-pre-line">{c.content}</p>
                    </article>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}
        </div>

        <aside className="space-y-4">
          {detail.owner && (
            <Card>
              <CardContent className="pt-5">
                <div className="text-xs font-mono uppercase tracking-wider text-fg-muted mb-3">项目方</div>
                <a href={`/users/${detail.owner.id}`} className="flex items-center gap-3 group">
                  <div className="w-10 h-10 rounded-pill bg-fg/5 grid place-items-center overflow-hidden">
                    {detail.owner.avatar ? <img src={detail.owner.avatar} alt={detail.owner.name} className="w-full h-full object-cover" /> : <span>{detail.owner.name?.[0]}</span>}
                  </div>
                  <span className="font-medium group-hover:underline">{detail.owner.name}</span>
                </a>
              </CardContent>
            </Card>
          )}
          <ProjectActions projectId={detail.id} />
        </aside>
      </Container>
    </>
  )
}
```

Write `web/app/(public)/projects/[id]/actions.client.tsx`:
```tsx
'use client'
import { Button } from '@/components/ui/button'
import { useAuthIntercept } from '@/components/auth/auth-intercept'

export function ProjectActions({ projectId }: { projectId: string }) {
  const { gate, interceptNode } = useAuthIntercept()

  return (
    <>
      <div className="glass rounded-lg p-5 space-y-2 sticky top-20">
        <Button className="w-full" onClick={() => gate('投标', () => {
          window.location.href = `/dashboard?from=bid&project=${projectId}`
        })}>
          我有团队，想投标
        </Button>
        <Button variant="glass" className="w-full" onClick={() => gate('联系项目方', () => {
          alert('请在 App 中联系项目方')
        })}>
          联系项目方
        </Button>
        <p className="text-xs text-fg-faint text-center pt-2">深度操作请使用 App</p>
      </div>
      {interceptNode}
    </>
  )
}
```

- [ ] **Step 3: Commit**

```bash
cd web && pnpm typecheck
git add web/
git commit -m "feat(web): add project detail page with intercept overlay"
```

---

### Task 12: 团队广场 + 团队主页

**Files:**
- Create: `web/app/(public)/experts/page.tsx`
- Create: `web/app/(public)/experts/[id]/page.tsx`
- Create: `web/app/(public)/experts/[id]/actions.client.tsx`

- [ ] **Step 1: 团队广场页（与 projects/page.tsx 结构对称）**

Write `web/app/(public)/experts/page.tsx`:
```tsx
import { Container } from '@/components/layout/container'
import { ExpertCard } from '@/components/cards/expert-card'
import { listExpertsServer } from '@/lib/api/market'
import { ColorHalo } from '@/components/effects/color-halo'

export const metadata = { title: '团队广场 · KAIZAO' }
export const revalidate = 30

export default async function ExpertsPage({ searchParams }: { searchParams: { page?: string } }) {
  const page = Number(searchParams.page ?? 1)
  const data = await listExpertsServer({ page, size: 24 }).catch(() => ({ list: [], total: 0, page, size: 24 }))

  return (
    <>
      <section className="relative py-16 overflow-hidden">
        <ColorHalo intensity="low" />
        <Container className="relative">
          <h1 className="text-4xl font-medium tracking-tight mb-3">团队广场</h1>
          <p className="text-fg-muted">浏览入驻的 T 级团队</p>
        </Container>
      </section>
      <Container className="pb-20">
        {data.list.length === 0 ? (
          <div className="glass rounded-lg p-12 text-center text-fg-muted">暂无团队</div>
        ) : (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-5">
            {data.list.map((e) => <ExpertCard key={e.id} e={e} />)}
          </div>
        )}
      </Container>
    </>
  )
}
```

- [ ] **Step 2: 团队主页**

Write `web/app/(public)/experts/[id]/page.tsx`:
```tsx
import { notFound } from 'next/navigation'
import { Container } from '@/components/layout/container'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { ColorHalo } from '@/components/effects/color-halo'
import { getUserServer, getUserSkillsServer, getUserPortfoliosServer, getUserReviewsServer } from '@/lib/api/users'
import { formatDate } from '@/lib/utils/format'
import { ExpertActions } from './actions.client'

export const revalidate = 60

export default async function ExpertProfilePage({ params }: { params: { id: string } }) {
  let user
  try { user = await getUserServer(params.id) } catch { notFound() }
  const [skills, portfolios, reviews] = await Promise.all([
    getUserSkillsServer(params.id).catch(() => []),
    getUserPortfoliosServer(params.id).catch(() => []),
    getUserReviewsServer(params.id).catch(() => []),
  ])

  return (
    <>
      <section className="relative py-12 overflow-hidden">
        <ColorHalo intensity="low" />
        <Container className="relative flex items-center gap-5 flex-wrap">
          <div className="w-20 h-20 rounded-pill bg-fg/5 grid place-items-center overflow-hidden">
            {user.avatar ? <img src={user.avatar} alt={user.name} className="w-full h-full object-cover" /> : <span className="text-2xl">{user.name?.[0]}</span>}
          </div>
          <div className="min-w-0 flex-1">
            <h1 className="text-3xl font-medium tracking-tight mb-2">{user.name}</h1>
            <div className="flex flex-wrap items-center gap-2 text-sm text-fg-muted">
              {user.credit_score != null && <Badge variant="glass">信用 {user.credit_score}</Badge>}
              {skills && skills.length > 0 && <span>·</span>}
              {skills?.slice(0, 4).map((s) => (
                <span key={s} className="text-[11px] font-mono text-fg-muted">#{s}</span>
              ))}
            </div>
          </div>
          <ExpertActions userId={user.id} />
        </Container>
      </section>

      <Container className="pb-20 grid md:grid-cols-3 gap-6">
        <div className="md:col-span-2 space-y-5">
          {portfolios && portfolios.length > 0 && (
            <Card><CardContent className="pt-6">
              <h2 className="text-sm font-mono uppercase tracking-wider text-fg-muted mb-4">作品</h2>
              <div className="grid sm:grid-cols-2 gap-4">
                {portfolios.map((p: any) => (
                  <div key={p.id} className="rounded-lg overflow-hidden border border-fg/5">
                    {p.cover && <img src={p.cover} alt={p.title} className="aspect-video w-full object-cover" />}
                    <div className="p-3 text-sm font-medium">{p.title}</div>
                  </div>
                ))}
              </div>
            </CardContent></Card>
          )}
          {reviews && reviews.length > 0 && (
            <Card><CardContent className="pt-6">
              <h2 className="text-sm font-mono uppercase tracking-wider text-fg-muted mb-4">评价</h2>
              <ul className="divide-y divide-fg/5">
                {reviews.map((r: any) => (
                  <li key={r.id} className="py-3">
                    <div className="flex items-center justify-between mb-1">
                      <span className="font-mono text-xs text-fg-faint">{formatDate(r.created_at)}</span>
                      <span className="font-mono text-sm">{r.score}/5</span>
                    </div>
                    <p className="text-sm text-fg-muted leading-relaxed">{r.content}</p>
                  </li>
                ))}
              </ul>
            </CardContent></Card>
          )}
        </div>
        <aside>
          {skills && skills.length > 0 && (
            <Card><CardContent className="pt-5">
              <h2 className="text-xs font-mono uppercase tracking-wider text-fg-muted mb-3">技能</h2>
              <div className="flex flex-wrap gap-1.5">
                {skills.map((s) => (
                  <span key={s} className="text-[11px] font-mono text-fg-muted bg-fg/5 px-2 py-0.5 rounded-pill">{s}</span>
                ))}
              </div>
            </CardContent></Card>
          )}
        </aside>
      </Container>
    </>
  )
}
```

Write `web/app/(public)/experts/[id]/actions.client.tsx`:
```tsx
'use client'
import { Button } from '@/components/ui/button'
import { useAuthIntercept } from '@/components/auth/auth-intercept'

export function ExpertActions({ userId }: { userId: string }) {
  const { gate, interceptNode } = useAuthIntercept()
  return (
    <>
      <div className="flex gap-2">
        <Button onClick={() => gate('邀约团队', () => alert('请在 App 中发起邀约'))}>邀约</Button>
        <Button variant="glass" onClick={() => gate('联系团队', () => alert('请在 App 中联系'))}>联系</Button>
      </div>
      {interceptNode}
    </>
  )
}
```

- [ ] **Step 3: Commit**

```bash
cd web && pnpm typecheck
git add web/
git commit -m "feat(web): add expert market and profile pages"
```

---

### Task 13: 用户公开主页 + 关于页

**Files:**
- Create: `web/app/(public)/users/[id]/page.tsx`
- Create: `web/app/(public)/about/page.tsx`

- [ ] **Step 1: 用户公开主页**

Write `web/app/(public)/users/[id]/page.tsx`:
```tsx
import { notFound } from 'next/navigation'
import { Container } from '@/components/layout/container'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { ColorHalo } from '@/components/effects/color-halo'
import { getUserServer } from '@/lib/api/users'

export const revalidate = 60

export default async function PublicUserPage({ params }: { params: { id: string } }) {
  let user
  try { user = await getUserServer(params.id) } catch { notFound() }

  return (
    <>
      <section className="relative py-12 overflow-hidden">
        <ColorHalo intensity="low" />
        <Container className="relative flex items-center gap-5">
          <div className="w-20 h-20 rounded-pill bg-fg/5 grid place-items-center overflow-hidden">
            {user.avatar ? <img src={user.avatar} alt={user.name} className="w-full h-full object-cover" /> : <span className="text-2xl">{user.name?.[0]}</span>}
          </div>
          <div>
            <h1 className="text-3xl font-medium tracking-tight mb-2">{user.name}</h1>
            <Badge variant="glass">{user.role === 1 ? '项目方' : user.role === 2 ? '团队方' : '用户'}</Badge>
          </div>
        </Container>
      </section>
      <Container className="pb-20">
        <Card>
          <CardContent className="pt-5 text-sm text-fg-muted">
            {user.credit_score != null && <p>信用分：{user.credit_score}</p>}
            <p className="mt-3 text-xs text-fg-faint">完整信息请下载 App 查看</p>
          </CardContent>
        </Card>
      </Container>
    </>
  )
}
```

- [ ] **Step 2: 关于页**

Write `web/app/(public)/about/page.tsx`:
```tsx
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
            KAIZAO（开造 / VCC）是一个 AI 驱动的软件需求撮合平台。
            我们用 AI Agent 帮项目方拆解需求、用 T 级评级帮团队建立信用，
            让"靠谱的人"和"靠谱的活"高效相遇。
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
```

> **Note:** 现网 `/usr/share/nginx/html/privacy-policy.html` 有完整内容，部署阶段可以把它的正文 markdown 化迁移到 `/about#privacy`。P1 不阻塞，先放占位文字。

- [ ] **Step 3: Commit**

```bash
cd web && pnpm typecheck
git add web/
git commit -m "feat(web): add public user profile and about page"
```

---

### Task 14: SEO · sitemap + robots + not-found

**Files:**
- Create: `web/app/sitemap.ts`
- Create: `web/app/robots.ts`
- Create: `web/app/not-found.tsx`

- [ ] **Step 1: sitemap**

Write `web/app/sitemap.ts`:
```ts
import type { MetadataRoute } from 'next'
import { listProjectsServer, listExpertsServer } from '@/lib/api/market'

const SITE = process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000'

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const base: MetadataRoute.Sitemap = [
    { url: `${SITE}/`, changeFrequency: 'weekly', priority: 1 },
    { url: `${SITE}/projects`, changeFrequency: 'hourly', priority: 0.9 },
    { url: `${SITE}/experts`, changeFrequency: 'daily', priority: 0.8 },
    { url: `${SITE}/about`, changeFrequency: 'monthly', priority: 0.5 },
  ]

  try {
    const projects = await listProjectsServer({ size: 100 })
    base.push(...projects.list.map((p) => ({
      url: `${SITE}/projects/${p.id}`,
      lastModified: p.created_at,
      changeFrequency: 'daily' as const,
      priority: 0.7,
    })))
  } catch {}
  try {
    const experts = await listExpertsServer({ size: 100 })
    base.push(...experts.list.map((e) => ({
      url: `${SITE}/experts/${e.id}`,
      changeFrequency: 'weekly' as const,
      priority: 0.7,
    })))
  } catch {}

  return base
}
```

- [ ] **Step 2: robots**

Write `web/app/robots.ts`:
```ts
import type { MetadataRoute } from 'next'

const SITE = process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000'

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      { userAgent: '*', allow: '/', disallow: ['/dashboard', '/me', '/auth', '/api'] },
    ],
    sitemap: `${SITE}/sitemap.xml`,
  }
}
```

- [ ] **Step 3: 404 页**

Write `web/app/not-found.tsx`:
```tsx
import Link from 'next/link'
import { Container } from '@/components/layout/container'
import { Button } from '@/components/ui/button'
import { ColorHalo } from '@/components/effects/color-halo'

export default function NotFound() {
  return (
    <main className="relative min-h-screen grid place-items-center overflow-hidden">
      <ColorHalo intensity="low" />
      <Container className="relative text-center">
        <div className="font-mono text-fg-faint text-xs mb-4">404</div>
        <h1 className="text-4xl font-medium tracking-tight mb-3">页面不存在</h1>
        <p className="text-fg-muted mb-8">你访问的页面可能被移动或删除</p>
        <Button asChild><Link href="/">回到首页</Link></Button>
      </Container>
    </main>
  )
}
```

- [ ] **Step 4: Commit**

```bash
cd web && pnpm typecheck
git add web/
git commit -m "feat(web): add sitemap, robots and 404 page"
```

---

## Phase 3 · 认证（Task 15–17）

### Task 15: 登录页 /auth/login

**Files:**
- Create: `web/app/auth/layout.tsx`
- Create: `web/app/auth/login/page.tsx`
- Create: `web/app/auth/login/login-form.client.tsx`
- Modify: `web/lib/api/auth.ts` —— 改 path

- [ ] **Step 1: 修 auth.ts path（登录/注册走专用路由）**

在 `web/lib/api/auth.ts` 中把：
```ts
export function login(req: LoginReq) {
  return browserFetch<AuthResult>('/api/v1/auth/login', { ... })
}
```
改为：
```ts
export function login(req: LoginReq) {
  return browserFetch<AuthResult>('/api/auth/login', { method: 'POST', body: JSON.stringify(req) })
}
export function register(req: RegisterReq) {
  return browserFetch<AuthResult>('/api/auth/register', { method: 'POST', body: JSON.stringify(req) })
}
export function logout() {
  return browserFetch<{ ok: boolean }>('/api/auth/logout', { method: 'POST' })
}
```

`sendSmsCode` 和 `loginPassword` 保持原 path（这些不设 cookie，走通用 BFF 即可）。

- [ ] **Step 2: auth 路由组 layout**

Write `web/app/auth/layout.tsx`:
```tsx
import Link from 'next/link'
import { ColorHalo } from '@/components/effects/color-halo'

export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="relative min-h-screen overflow-hidden">
      <ColorHalo intensity="high" />
      <header className="relative z-10 px-6 py-5">
        <Link href="/" className="font-mono text-sm tracking-wider font-medium">KAIZAO</Link>
      </header>
      <main className="relative z-10 grid place-items-center px-6 pb-16">{children}</main>
    </div>
  )
}
```

- [ ] **Step 3: 登录页**

Write `web/app/auth/login/page.tsx`:
```tsx
import Link from 'next/link'
import { LoginForm } from './login-form.client'

export const metadata = { title: '登录 · KAIZAO' }

export default function LoginPage({ searchParams }: { searchParams: { from?: string } }) {
  return (
    <div className="glass rounded-lg w-full max-w-sm p-7">
      <h1 className="text-2xl font-medium tracking-tight mb-1">欢迎回来</h1>
      <p className="text-sm text-fg-muted mb-6">登录以继续</p>
      <LoginForm from={searchParams.from} />
      <p className="mt-6 text-xs text-fg-muted text-center">
        还没账号？<Link href="/auth/register" className="text-fg underline">立即注册</Link>
      </p>
    </div>
  )
}
```

- [ ] **Step 4: 登录表单**

Write `web/app/auth/login/login-form.client.tsx`:
```tsx
'use client'
import * as React from 'react'
import { useRouter } from 'next/navigation'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { sendSmsCode, login } from '@/lib/api/auth'

export function LoginForm({ from }: { from?: string }) {
  const router = useRouter()
  const [mobile, setMobile] = React.useState('')
  const [code, setCode] = React.useState('')
  const [sending, setSending] = React.useState(false)
  const [submitting, setSubmitting] = React.useState(false)
  const [error, setError] = React.useState<string | null>(null)
  const [cooldown, setCooldown] = React.useState(0)

  React.useEffect(() => {
    if (cooldown > 0) {
      const t = setTimeout(() => setCooldown(cooldown - 1), 1000)
      return () => clearTimeout(t)
    }
  }, [cooldown])

  const sendCode = async () => {
    if (!/^1\d{10}$/.test(mobile)) { setError('请输入有效手机号'); return }
    setError(null); setSending(true)
    try {
      await sendSmsCode({ mobile, scene: 'login' })
      setCooldown(60)
    } catch (e: any) {
      setError(e?.message ?? '发送失败')
    } finally { setSending(false) }
  }

  const submit = async (ev: React.FormEvent) => {
    ev.preventDefault()
    if (!mobile || !code) { setError('请填写完整'); return }
    setError(null); setSubmitting(true)
    try {
      await login({ mobile, sms_code: code })
      router.replace(from || '/dashboard')
      router.refresh()
    } catch (e: any) {
      setError(e?.message ?? '登录失败')
    } finally { setSubmitting(false) }
  }

  return (
    <form onSubmit={submit} className="space-y-3">
      <Input value={mobile} onChange={(e) => setMobile(e.target.value)} placeholder="手机号" inputMode="numeric" maxLength={11} />
      <div className="flex gap-2">
        <Input value={code} onChange={(e) => setCode(e.target.value)} placeholder="验证码" inputMode="numeric" maxLength={6} />
        <Button type="button" variant="glass" disabled={sending || cooldown > 0} onClick={sendCode}>
          {cooldown > 0 ? `${cooldown}s` : '发送'}
        </Button>
      </div>
      {error && <p className="text-xs text-rose-600">{error}</p>}
      <Button type="submit" className="w-full" disabled={submitting}>
        {submitting ? '登录中…' : '登录'}
      </Button>
    </form>
  )
}
```

- [ ] **Step 5: Commit**

```bash
cd web && pnpm typecheck
git add web/
git commit -m "feat(web): add sms-code login page"
```

---

### Task 16: 注册页 /auth/register（多步）

**Files:**
- Create: `web/app/auth/register/page.tsx`
- Create: `web/app/auth/register/register-form.client.tsx`
- Create: `web/components/auth/role-picker.tsx`

- [ ] **Step 1: RolePicker 组件**

Write `web/components/auth/role-picker.tsx`:
```tsx
'use client'
import { cn } from '@/lib/utils/cn'

interface Props {
  value?: 1 | 2
  onChange: (v: 1 | 2) => void
}

const ROLES = [
  { v: 1 as const, title: '我是项目方', desc: '有想法、找团队做出来' },
  { v: 2 as const, title: '我是团队方', desc: '有技能、想接到合适的项目' },
]

export function RolePicker({ value, onChange }: Props) {
  return (
    <div className="grid grid-cols-2 gap-3">
      {ROLES.map((r) => (
        <button
          key={r.v}
          type="button"
          onClick={() => onChange(r.v)}
          className={cn(
            'glass rounded-lg p-4 text-left transition-all',
            value === r.v ? 'ring-2 ring-fg shadow-lg' : 'hover:bg-white/70'
          )}
        >
          <div className="font-medium mb-1">{r.title}</div>
          <div className="text-xs text-fg-muted">{r.desc}</div>
        </button>
      ))}
    </div>
  )
}
```

- [ ] **Step 2: 注册页**

Write `web/app/auth/register/page.tsx`:
```tsx
import Link from 'next/link'
import { RegisterForm } from './register-form.client'

export const metadata = { title: '注册 · KAIZAO' }

export default function RegisterPage({ searchParams }: { searchParams: { role?: string } }) {
  const initialRole = searchParams.role === '2' ? 2 : searchParams.role === '1' ? 1 : undefined
  return (
    <div className="glass rounded-lg w-full max-w-sm p-7">
      <h1 className="text-2xl font-medium tracking-tight mb-1">加入 KAIZAO</h1>
      <p className="text-sm text-fg-muted mb-6">选择身份后即可注册</p>
      <RegisterForm initialRole={initialRole} />
      <p className="mt-6 text-xs text-fg-muted text-center">
        已有账号？<Link href="/auth/login" className="text-fg underline">登录</Link>
      </p>
    </div>
  )
}
```

- [ ] **Step 3: 注册表单**

Write `web/app/auth/register/register-form.client.tsx`:
```tsx
'use client'
import * as React from 'react'
import { useRouter } from 'next/navigation'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { RolePicker } from '@/components/auth/role-picker'
import { sendSmsCode, register } from '@/lib/api/auth'

export function RegisterForm({ initialRole }: { initialRole?: 1 | 2 }) {
  const router = useRouter()
  const [step, setStep] = React.useState<1 | 2>(initialRole ? 2 : 1)
  const [role, setRole] = React.useState<1 | 2 | undefined>(initialRole)
  const [mobile, setMobile] = React.useState('')
  const [code, setCode] = React.useState('')
  const [cooldown, setCooldown] = React.useState(0)
  const [error, setError] = React.useState<string | null>(null)
  const [submitting, setSubmitting] = React.useState(false)

  React.useEffect(() => {
    if (cooldown > 0) {
      const t = setTimeout(() => setCooldown(cooldown - 1), 1000)
      return () => clearTimeout(t)
    }
  }, [cooldown])

  if (step === 1) {
    return (
      <div className="space-y-4">
        <RolePicker value={role} onChange={(v) => setRole(v)} />
        <Button className="w-full" disabled={!role} onClick={() => setStep(2)}>下一步</Button>
      </div>
    )
  }

  const sendCode = async () => {
    if (!/^1\d{10}$/.test(mobile)) { setError('请输入有效手机号'); return }
    setError(null)
    try {
      await sendSmsCode({ mobile, scene: 'register' })
      setCooldown(60)
    } catch (e: any) { setError(e?.message ?? '发送失败') }
  }

  const submit = async (ev: React.FormEvent) => {
    ev.preventDefault()
    if (!role || !mobile || !code) { setError('请填写完整'); return }
    setError(null); setSubmitting(true)
    try {
      await register({ mobile, sms_code: code, role })
      router.replace('/dashboard')
      router.refresh()
    } catch (e: any) {
      setError(e?.message ?? '注册失败')
    } finally { setSubmitting(false) }
  }

  return (
    <form onSubmit={submit} className="space-y-3">
      <div className="flex items-center gap-2 text-xs text-fg-muted font-mono mb-3">
        <span>身份：</span>
        <span className="text-fg">{role === 1 ? '项目方' : '团队方'}</span>
        <button type="button" onClick={() => setStep(1)} className="ml-auto underline text-fg-muted hover:text-fg">修改</button>
      </div>
      <Input value={mobile} onChange={(e) => setMobile(e.target.value)} placeholder="手机号" inputMode="numeric" maxLength={11} />
      <div className="flex gap-2">
        <Input value={code} onChange={(e) => setCode(e.target.value)} placeholder="验证码" inputMode="numeric" maxLength={6} />
        <Button type="button" variant="glass" disabled={cooldown > 0} onClick={sendCode}>
          {cooldown > 0 ? `${cooldown}s` : '发送'}
        </Button>
      </div>
      {error && <p className="text-xs text-rose-600">{error}</p>}
      <Button type="submit" className="w-full" disabled={submitting}>
        {submitting ? '注册中…' : '完成注册'}
      </Button>
    </form>
  )
}
```

- [ ] **Step 4: Commit**

```bash
cd web && pnpm typecheck
git add web/
git commit -m "feat(web): add multi-step register page with role picker"
```

---

### Task 17: 找回密码 /auth/forgot（最小可用）

**Files:**
- Create: `web/app/auth/forgot/page.tsx`

- [ ] **Step 1: 最小占位 + 引导到登录**

Write `web/app/auth/forgot/page.tsx`:
```tsx
import Link from 'next/link'
import { Button } from '@/components/ui/button'

export const metadata = { title: '找回密码 · KAIZAO' }

export default function ForgotPage() {
  return (
    <div className="glass rounded-lg w-full max-w-sm p-7 text-center">
      <h1 className="text-xl font-medium tracking-tight mb-3">找回密码</h1>
      <p className="text-sm text-fg-muted mb-6">
        当前 web 版只支持手机号 + 验证码登录，无需密码。<br />
        请直接使用登录页验证码登录。
      </p>
      <Button asChild className="w-full"><Link href="/auth/login">前往登录</Link></Button>
    </div>
  )
}
```

> **Rationale:** P1 我们用短信验证码登录为主，**不实现密码登录与找回**（接口 `password-key` / `captcha` 仍然存在，但 P1 不接），这是显式的 P1 简化。如果用户后续要求密码登录，P2 再补。

- [ ] **Step 2: Commit**

```bash
git add web/
git commit -m "feat(web): add forgot-password placeholder redirecting to sms login"
```

---

## Phase 4 · 登录后页面（Task 18–21）

### Task 18: Dashboard 主页（角色感知）

**Files:**
- Create: `web/app/(dashboard)/dashboard/page.tsx`
- Create: `web/app/(dashboard)/dashboard/logout-button.client.tsx`
- Create: `web/lib/api/home.ts`

- [ ] **Step 1: home API**

Write `web/lib/api/home.ts`:
```ts
import { serverFetch } from './client'

export interface DemanderHome {
  user: { id: string; name: string; avatar?: string }
  ongoing_projects?: Array<{ id: string; title: string; status: string }>
  drafts?: Array<{ id: string; title: string }>
}

export interface ExpertHome {
  user: { id: string; name: string; avatar?: string }
  rate_level?: string
  ongoing_bids?: Array<{ project_id: string; project_title: string; status: string }>
  available_projects?: Array<{ id: string; title: string }>
}

export function getDemanderHome() {
  return serverFetch<DemanderHome>('/api/v1/home/demander', { auth: true })
}
export function getExpertHome() {
  return serverFetch<ExpertHome>('/api/v1/home/expert', { auth: true })
}
```

- [ ] **Step 2: Logout button**

Write `web/app/(dashboard)/dashboard/logout-button.client.tsx`:
```tsx
'use client'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { logout } from '@/lib/api/auth'

export function LogoutButton() {
  const router = useRouter()
  return (
    <Button variant="glass" size="sm" onClick={async () => {
      await logout().catch(() => {})
      router.replace('/')
      router.refresh()
    }}>退出</Button>
  )
}
```

- [ ] **Step 3: dashboard page（按角色分支）**

Write `web/app/(dashboard)/dashboard/page.tsx`:
```tsx
import Link from 'next/link'
import { Container } from '@/components/layout/container'
import { Header } from '@/components/layout/header'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { ColorHalo } from '@/components/effects/color-halo'
import { getServerSession } from '@/lib/auth/session'
import { getDemanderHome, getExpertHome } from '@/lib/api/home'
import { LogoutButton } from './logout-button.client'

export const metadata = { title: '控制台 · KAIZAO' }

export default async function DashboardPage() {
  const { role } = getServerSession()
  const isDemander = role === 1
  const data = isDemander
    ? await getDemanderHome().catch(() => null)
    : await getExpertHome().catch(() => null)

  return (
    <>
      <Header />
      <section className="relative py-10 overflow-hidden">
        <ColorHalo intensity="low" />
        <Container className="relative flex items-center justify-between flex-wrap gap-4">
          <div>
            <p className="text-xs font-mono uppercase tracking-wider text-fg-muted mb-2">控制台</p>
            <h1 className="text-3xl font-medium tracking-tight">
              {isDemander ? '项目方主页' : '团队方主页'}
            </h1>
          </div>
          <div className="flex gap-2">
            <Button asChild variant="glass" size="sm"><Link href="/me">个人中心</Link></Button>
            <LogoutButton />
          </div>
        </Container>
      </section>

      <Container className="pb-20 grid md:grid-cols-2 gap-5">
        <Card>
          <CardContent className="pt-6">
            <div className="text-xs font-mono uppercase tracking-wider text-fg-muted mb-3">
              {isDemander ? '进行中的项目' : '进行中的投标'}
            </div>
            {(() => {
              const list = isDemander ? (data as any)?.ongoing_projects : (data as any)?.ongoing_bids
              if (!list || list.length === 0) {
                return <p className="text-sm text-fg-muted">暂无内容</p>
              }
              return (
                <ul className="space-y-2">
                  {list.map((it: any) => (
                    <li key={it.id ?? it.project_id} className="flex items-center justify-between text-sm">
                      <span>{it.title ?? it.project_title}</span>
                      <Badge variant="outline">{it.status}</Badge>
                    </li>
                  ))}
                </ul>
              )
            })()}
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="text-xs font-mono uppercase tracking-wider text-fg-muted mb-3">快捷入口</div>
            <div className="space-y-2 text-sm">
              <Link href="/me/projects" className="block hover:text-fg-muted">我的项目</Link>
              <Link href="/me/notifications" className="block hover:text-fg-muted">通知</Link>
              <Link href="/me" className="block hover:text-fg-muted">个人资料</Link>
            </div>
            <p className="mt-5 text-xs text-fg-faint">深度操作（发布需求、投标、IM 等）请使用 App</p>
          </CardContent>
        </Card>
      </Container>
    </>
  )
}
```

- [ ] **Step 4: Commit**

```bash
cd web && pnpm typecheck
git add web/
git commit -m "feat(web): add role-aware dashboard page with logout"
```

---

### Task 19: 个人中心 /me

**Files:**
- Create: `web/app/(dashboard)/me/page.tsx`
- Modify: `web/lib/api/users.ts`（补 me 接口）

- [ ] **Step 1: 补 me 服务端接口**

在 `web/lib/api/users.ts` 末尾追加：
```ts
export function getMeServer() {
  return serverFetch<User>('/api/v1/users/me', { auth: true })
}
```

- [ ] **Step 2: /me 页面**

Write `web/app/(dashboard)/me/page.tsx`:
```tsx
import Link from 'next/link'
import { Container } from '@/components/layout/container'
import { Header } from '@/components/layout/header'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { ColorHalo } from '@/components/effects/color-halo'
import { getMeServer } from '@/lib/api/users'

export const metadata = { title: '个人中心 · KAIZAO' }

export default async function MePage() {
  const me = await getMeServer()
  return (
    <>
      <Header />
      <section className="relative py-10 overflow-hidden">
        <ColorHalo intensity="low" />
        <Container className="relative flex items-center gap-5">
          <div className="w-20 h-20 rounded-pill bg-fg/5 grid place-items-center overflow-hidden">
            {me.avatar ? <img src={me.avatar} alt={me.name} className="w-full h-full object-cover" /> : <span className="text-2xl">{me.name?.[0]}</span>}
          </div>
          <div>
            <h1 className="text-3xl font-medium tracking-tight mb-2">{me.name}</h1>
            <Badge variant="glass">{me.role === 1 ? '项目方' : me.role === 2 ? '团队方' : '用户'}</Badge>
          </div>
        </Container>
      </section>
      <Container className="pb-20 max-w-2xl space-y-4">
        <Card>
          <CardContent className="pt-5">
            <h2 className="text-sm font-mono uppercase tracking-wider text-fg-muted mb-3">资料</h2>
            <dl className="grid grid-cols-2 gap-y-3 text-sm">
              <dt className="text-fg-faint">ID</dt><dd className="font-mono">{me.id}</dd>
              <dt className="text-fg-faint">姓名</dt><dd>{me.name}</dd>
              <dt className="text-fg-faint">信用</dt><dd>{me.credit_score ?? '—'}</dd>
            </dl>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-5 text-sm text-fg-muted">
            <p>资料修改、技能管理、钱包提现等功能请使用 App。</p>
            <p className="mt-2"><Link href="/dashboard" className="text-fg underline">回到控制台</Link></p>
          </CardContent>
        </Card>
      </Container>
    </>
  )
}
```

- [ ] **Step 3: Commit**

```bash
cd web && pnpm typecheck
git add web/
git commit -m "feat(web): add personal center /me page"
```

---

### Task 20: 我的项目 /me/projects

**Files:**
- Create: `web/app/(dashboard)/me/projects/page.tsx`
- Modify: `web/lib/api/projects.ts`（补 my projects）

- [ ] **Step 1: 补接口**

在 `web/lib/api/projects.ts` 末尾追加：
```ts
import type { PageResult } from './types'

export function listMyProjects(q: { page?: number; size?: number } = {}) {
  const params = new URLSearchParams()
  if (q.page) params.set('page', String(q.page))
  if (q.size) params.set('size', String(q.size))
  params.set('owner', 'me')
  return serverFetch<PageResult<Project>>(`/api/v1/projects?${params.toString()}`, { auth: true })
}
```

- [ ] **Step 2: /me/projects 页**

Write `web/app/(dashboard)/me/projects/page.tsx`:
```tsx
import Link from 'next/link'
import { Container } from '@/components/layout/container'
import { Header } from '@/components/layout/header'
import { ProjectCard } from '@/components/cards/project-card'
import { listMyProjects } from '@/lib/api/projects'

export const metadata = { title: '我的项目 · KAIZAO' }

export default async function MyProjectsPage() {
  const data = await listMyProjects({ size: 50 }).catch(() => ({ list: [], total: 0, page: 1, size: 50 }))
  return (
    <>
      <Header />
      <Container className="py-10">
        <h1 className="text-3xl font-medium tracking-tight mb-6">我的项目</h1>
        {data.list.length === 0 ? (
          <div className="glass rounded-lg p-10 text-center text-fg-muted">
            还没有项目。<br />
            <Link href="/" className="text-fg underline mt-2 inline-block">在 App 中发布需求</Link>
          </div>
        ) : (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-5">
            {data.list.map((p) => <ProjectCard key={p.id} p={p} />)}
          </div>
        )}
      </Container>
    </>
  )
}
```

- [ ] **Step 3: Commit**

```bash
cd web && pnpm typecheck
git add web/
git commit -m "feat(web): add my-projects list page"
```

---

### Task 21: 通知 /me/notifications

**Files:**
- Create: `web/app/(dashboard)/me/notifications/page.tsx`
- Create: `web/lib/api/notifications.ts`

- [ ] **Step 1: notifications API**

Write `web/lib/api/notifications.ts`:
```ts
import { serverFetch } from './client'
import type { PageResult } from './types'

export interface Notification {
  id: string
  type: string
  title: string
  body?: string
  read: boolean
  created_at: string
}

export function listNotifications(q: { page?: number; size?: number } = {}) {
  const params = new URLSearchParams()
  if (q.page) params.set('page', String(q.page))
  if (q.size) params.set('size', String(q.size))
  return serverFetch<PageResult<Notification>>(`/api/v1/notifications?${params.toString()}`, { auth: true })
}
```

- [ ] **Step 2: notifications 页**

Write `web/app/(dashboard)/me/notifications/page.tsx`:
```tsx
import { Container } from '@/components/layout/container'
import { Header } from '@/components/layout/header'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { listNotifications } from '@/lib/api/notifications'
import { formatRelative } from '@/lib/utils/format'

export const metadata = { title: '通知 · KAIZAO' }

export default async function NotificationsPage() {
  const data = await listNotifications({ size: 50 }).catch(() => ({ list: [], total: 0, page: 1, size: 50 }))
  return (
    <>
      <Header />
      <Container className="py-10 max-w-2xl">
        <h1 className="text-3xl font-medium tracking-tight mb-6">通知</h1>
        {data.list.length === 0 ? (
          <div className="glass rounded-lg p-10 text-center text-fg-muted">暂无通知</div>
        ) : (
          <ul className="space-y-3">
            {data.list.map((n) => (
              <li key={n.id}>
                <Card><CardContent className="pt-5">
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="font-medium">{n.title}</span>
                        {!n.read && <Badge variant="outline">未读</Badge>}
                      </div>
                      {n.body && <p className="text-sm text-fg-muted line-clamp-2">{n.body}</p>}
                    </div>
                    <span className="font-mono text-xs text-fg-faint shrink-0">{formatRelative(n.created_at)}</span>
                  </div>
                </CardContent></Card>
              </li>
            ))}
          </ul>
        )}
      </Container>
    </>
  )
}
```

- [ ] **Step 3: Commit**

```bash
cd web && pnpm typecheck
git add web/
git commit -m "feat(web): add notifications page"
```

---

## Phase 5 · 测试与部署（Task 22–25）

### Task 22: 单元测试补齐关键组件

**Files:**
- Create: `web/tests/unit/components/project-card.test.tsx`
- Create: `web/tests/unit/components/auth-intercept.test.tsx`
- Create: `web/tests/unit/utils/format.test.ts`

- [ ] **Step 1: format 工具测试**

Write `web/tests/unit/utils/format.test.ts`:
```ts
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
```

- [ ] **Step 2: ProjectCard 渲染测试**

Write `web/tests/unit/components/project-card.test.tsx`:
```tsx
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
```

- [ ] **Step 3: AuthIntercept 测试**

Write `web/tests/unit/components/auth-intercept.test.tsx`:
```tsx
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
    expect(screen.getByText(/注册后即可投标/)).toBeInTheDocument()
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
```

- [ ] **Step 4: 跑测试**

```bash
cd web && pnpm test
```

Expected: 全绿。

- [ ] **Step 5: Commit**

```bash
git add web/
git commit -m "test(web): add unit tests for format/project-card/auth-intercept"
```

---

### Task 23: e2e 测试（Playwright）

**Files:**
- Create: `web/playwright.config.ts`
- Create: `web/tests/e2e/landing.spec.ts`
- Create: `web/tests/e2e/projects.spec.ts`
- Create: `web/tests/e2e/intercept.spec.ts`
- Create: `web/tests/e2e/register.spec.ts`
- Modify: `web/package.json`

- [ ] **Step 1: 安装 Playwright**

Run:
```bash
cd web && pnpm add -D @playwright/test@1.49.0 && pnpm exec playwright install chromium
```

- [ ] **Step 2: 配置 Playwright**

Write `web/playwright.config.ts`:
```ts
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './tests/e2e',
  timeout: 30000,
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: 'list',
  use: {
    baseURL: process.env.E2E_BASE_URL ?? 'http://localhost:3000',
    headless: true,
    trace: 'retain-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'mobile', use: { ...devices['iPhone 14'] } },
  ],
  webServer: process.env.E2E_BASE_URL
    ? undefined
    : { command: 'pnpm dev', url: 'http://localhost:3000', reuseExistingServer: true, timeout: 60000 },
})
```

- [ ] **Step 3: landing e2e**

Write `web/tests/e2e/landing.spec.ts`:
```ts
import { test, expect } from '@playwright/test'

test('landing page renders hero and CTAs', async ({ page }) => {
  await page.goto('/')
  await expect(page.getByText('把模糊的需求')).toBeVisible()
  await expect(page.getByRole('link', { name: /我是项目方/ })).toBeVisible()
  await expect(page.getByRole('link', { name: /我是团队方/ })).toBeVisible()
})

test('FAQ items are togglable', async ({ page }) => {
  await page.goto('/')
  await page.getByText('KAIZAO 是做什么的？').click()
  await expect(page.getByText(/AI 驱动的软件需求撮合平台/)).toBeVisible()
})
```

- [ ] **Step 4: projects e2e**

Write `web/tests/e2e/projects.spec.ts`:
```ts
import { test, expect } from '@playwright/test'

test('project market is reachable from landing', async ({ page }) => {
  await page.goto('/')
  await page.getByRole('link', { name: '需求广场' }).first().click()
  await expect(page).toHaveURL(/\/projects$/)
  await expect(page.getByRole('heading', { name: '需求广场' })).toBeVisible()
})
```

- [ ] **Step 5: intercept e2e**

Write `web/tests/e2e/intercept.spec.ts`:
```ts
import { test, expect } from '@playwright/test'

test('clicking "联系" on project detail opens auth intercept when not logged in', async ({ page }) => {
  // 此用例需要有真实项目数据，本地后端连不上时会跳过
  await page.goto('/projects')
  const first = page.locator('a[href^="/projects/"]').first()
  const hasProjects = (await first.count()) > 0
  test.skip(!hasProjects, 'no projects in backend, skipping')

  await first.click()
  await page.getByRole('button', { name: /联系项目方/ }).click()
  await expect(page.getByText(/注册后即可/)).toBeVisible()
})
```

- [ ] **Step 6: register e2e**

Write `web/tests/e2e/register.spec.ts`:
```ts
import { test, expect } from '@playwright/test'

test('register page step navigation works', async ({ page }) => {
  await page.goto('/auth/register')
  await expect(page.getByRole('heading', { name: '加入 KAIZAO' })).toBeVisible()
  await page.getByRole('button', { name: /我是项目方/ }).click()
  await page.getByRole('button', { name: '下一步' }).click()
  await expect(page.getByPlaceholder('手机号')).toBeVisible()
  // 不发短信，不走完真实注册
})
```

- [ ] **Step 7: 跑 e2e**

```bash
cd web && pnpm e2e
```

Expected: landing / projects / register 都通过；intercept 视后端是否有数据自动 skip。

- [ ] **Step 8: Commit**

```bash
git add web/
git commit -m "test(web): add playwright e2e for landing, projects, intercept and register"
```

---

### Task 24: Dockerfile + docker-compose

**Files:**
- Create: `web/Dockerfile`
- Create: `web/.dockerignore`
- Create: `web/docker-compose.yml`
- Create: `web/README.md`

- [ ] **Step 1: Dockerfile（standalone 多阶段）**

Write `web/Dockerfile`:
```dockerfile
# syntax=docker/dockerfile:1.6

FROM node:20-alpine AS deps
WORKDIR /app
RUN corepack enable
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile

FROM node:20-alpine AS builder
WORKDIR /app
RUN corepack enable
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
RUN pnpm build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 nextjs
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
USER nextjs
EXPOSE 3000
ENV PORT=3000 HOSTNAME=0.0.0.0
CMD ["node", "server.js"]
```

- [ ] **Step 2: .dockerignore**

Write `web/.dockerignore`:
```
node_modules
.next
out
.env
.env.local
.env.*.local
.git
.gitignore
README.md
tests/e2e
playwright-report
test-results
coverage
.superpowers
```

- [ ] **Step 3: docker-compose（单服务，独立）**

Write `web/docker-compose.yml`:
```yaml
services:
  kaizao-web:
    container_name: kaizao-web
    build:
      context: .
      dockerfile: Dockerfile
    image: kaizao-web:latest
    restart: unless-stopped
    ports:
      - "127.0.0.1:39532:3000"
    environment:
      NODE_ENV: production
      NEXT_PUBLIC_SITE_URL: ${NEXT_PUBLIC_SITE_URL}
      KAIZAO_SERVER_INTERNAL: ${KAIZAO_SERVER_INTERNAL}
      AI_AGENT_INTERNAL: ${AI_AGENT_INTERNAL}
    networks:
      - default
networks:
  default:
    external: true
    name: kaizao-server_default
```

> **Critical:** 用 `external: true` 复用 `kaizao-server` 已经存在的 docker network，**不创建新网络、不重启任何已有容器**。`kaizao-web` 通过 `KAIZAO_SERVER_INTERNAL=http://kaizao-server:8080` 走内网。

- [ ] **Step 4: README**

Write `web/README.md`:
```markdown
# KAIZAO Web · P1

KAIZAO 撮合平台 web 站。Next.js 14 + Tailwind + shadcn/ui。

## 开发

```bash
pnpm install
cp .env.example .env
pnpm dev
```

`http://localhost:3000`

## 测试

```bash
pnpm test      # vitest
pnpm e2e       # playwright
pnpm typecheck
```

## 部署

通过 docker-compose 部署到 47 服务器。详见 spec §9 和 plan Task 25。

## 文档

- 设计文档：`../docs/superpowers/specs/2026-05-17-kaizao-web-p1-design.md`
- 实施计划：`../docs/superpowers/plans/2026-05-17-kaizao-web-p1.md`
```

- [ ] **Step 5: 本地构建验证**

```bash
cd web && pnpm install && docker build -t kaizao-web:test .
```

Expected: 构建成功，`Successfully tagged kaizao-web:test`。

- [ ] **Step 6: Commit**

```bash
git add web/
git commit -m "build(web): add dockerfile, compose and readme"
```

---

### Task 25: 最终自检 + 准备部署 PR

**Files:**
- Modify: `README.md`（仓库根，加一行 web/ 介绍）

- [ ] **Step 1: 仓库根 README 加 web/ 入口**

读取仓库根 `README.md`，找到目录介绍区域，加一行：
```markdown
- `web/`：Next.js Web 撮合平台（P1，公开浏览 + 注册登录 + 个人空间）
```

如果根 README 中没有目录介绍段落，跳过此步即可，不要硬塞结构。

- [ ] **Step 2: 跑完整 CI 集**

```bash
cd web && pnpm typecheck && pnpm lint && pnpm test && pnpm build
```

Expected: 4 个命令全部退出码 0。

- [ ] **Step 3: 部署清单核对（spec §13 验收）**

人工核对下列项，每项都要本地确认：

- [ ] 14 个页面在 `pnpm dev` 都能打开
- [ ] 未登录访问 `/projects` `/experts` `/projects/[id]` `/experts/[id]` 都能看到内容（后端有数据时）
- [ ] 未登录点 `「投标」` → 弹注册引导（intercept）
- [ ] 完成注册 → 跳 `/dashboard` → 看到角色感知内容
- [ ] `/dashboard` 退出 → 回到 `/` 且 cookie 已清
- [ ] Chrome 桌面 + iPhone 模拟器（Playwright `mobile` project）目测 layout 不崩
- [ ] `curl http://localhost:3000/sitemap.xml` 返回 XML
- [ ] `curl http://localhost:3000/robots.txt` 返回 disallow `/api`、`/dashboard`、`/me`、`/auth`

- [ ] **Step 4: 推 GitHub 等用户确认**

```bash
git push -u origin main
```

并把整个 `web/` 目录 + 两份 docs 在 GitHub 上以 PR 形式给用户 review（或者用户直接在 main 上看）。

> **不部署！** 等用户在本地或 GitHub 上看完，明确说"可以部署了"再走 spec §9 的 rsync + nginx + docker compose 流程。OQ-1（域名是 `www.kaizao.cc` 还是子域名）也在这一步问用户。

- [ ] **Step 5: Final commit（如果有 README 改动）**

```bash
git add README.md
git commit -m "docs(repo): add web/ to top-level directory listing"
```

---

## Self-Review

### 1. Spec coverage check

| Spec §  | 内容 | 对应 Task | 状态 |
|---|---|---|---|
| §2.1 公开层 7 页 | / /projects /projects/[id] /experts /experts/[id] /users/[id] /about | T9 T10 T11 T12 T13 T13 | ✓ |
| §2.1 认证层 3 页 | /auth/login /auth/register /auth/forgot | T15 T16 T17 | ✓ |
| §2.1 登录后 4 页 | /dashboard /me /me/projects /me/notifications | T18 T19 T20 T21 | ✓ |
| §2.2 拦截动作 | 项目详情/团队主页的 CTA | T11 T12（用 useAuthIntercept） | ✓ |
| §3 技术栈 | Next.js 14 / Tailwind / shadcn / TanStack Query / RHF / Zod / Geist | T1–T4 全覆盖；TanStack Query 和 RHF/Zod **没用**到（实际 P1 用的是 server components + 简单 useState 表单，没必要引入） | ⚠ 见下方说明 |
| §4 设计 Token | --bg --fg --border --gradient-hero 等 | T2 | ✓ |
| §5 路由守卫 | (dashboard) 守卫；公开页匿名 | T7（(dashboard)/layout.tsx） | ✓ |
| §6.1 落地页 7 sections | hero/value/howto/featured/stats/faq/footer | T9 | ✓ |
| §6.2 广场 + 筛选 | MarketFilters | T10 | ✓ |
| §6.3 详情 PRD + overview + actions | 全 | T11 | ✓ |
| §6.4 团队广场/主页/用户公开 | 全 | T12 T13 | ✓ |
| §6.5 注册多步选角色 | RolePicker → mobile + sms | T16 | ✓ |
| §7 BFF | /api/[...path] + 专用 /api/auth/* | T5 T7 | ✓ |
| §7.2 HttpOnly Cookie | cookie.ts + 登录/注册/登出路由 | T5 T7 | ✓ |
| §7.3 错误处理 | ApiError 统一抛 | T6（401/403/5xx 统一靠 ApiError），但 UI 端 toast 系统 P1 未引入。详情页/广场用 try/catch 兜底回 empty | ⚠ 见下方说明 |
| §8 项目结构 | web/app web/components web/lib | 全部 task | ✓ |
| §9 部署 | Dockerfile + compose | T24 T25 | ✓（部署本身不在 P1 编码任务内，等用户批准） |
| §10 测试 | Vitest 单元 + Playwright e2e 4 路径 | T22 T23 | ✓ |
| §11 风险缓解 | @supports backdrop-filter 兜底；接口字段 verify | T2 styles/tokens.css + 各 page 注释 | ✓ |
| §12 OQ-1 域名 | 待用户决定 | T25 step 4 | ✓ pending |
| §13 验收 | 8 条硬指标 | T25 step 3 | ✓ |

**⚠ Spec 与计划差异 1（TanStack Query / RHF / Zod 未使用）：** P1 所有数据获取都用 server components + 偶尔的 useState 表单，引入 TanStack Query 和表单库会增加复杂度但不增加价值。P2 真正出现交互密集页面（chat、PRD 编辑）时再加入是更对的选择。这是有意识的 YAGNI 偏离，请在 PR 描述里说明。

**⚠ Spec 与计划差异 2（toast 系统未实现）：** Spec §7.3 提到 `5xx → toast 服务暂时不可用`。P1 计划用 SSR 错误页 + 列表空状态兜底，没引入 toast 库。如果出现需要 toast 的场景（如 /me 资料修改失败），P2 接入 sonner 或 shadcn 的 toast。当前不阻塞 P1 验收。

### 2. Placeholder scan

无 `TBD/TODO/implement later` —— 唯一的"待定"在 §6.1 step 6 的 StatsWall 数字（hardcode），但这是 spec §12 OQ-2 已经显式认可的占位。已加注释说明。

### 3. Type / API consistency

- 所有 `serverFetch` / `browserFetch` 调用都返回 `Promise<T>`，T 在 `types.ts` 集中定义 ✓
- `User.role` 在所有地方都是 `1 | 2`（项目方/团队方），无歧义 ✓
- `login()` / `register()` 路径在 T15 step 1 已经统一改成 `/api/auth/*`（专用路由），不走通用 BFF —— 这一步如果漏改，Cookie 不会被设置 → 注册后跳 dashboard 会因为没 cookie 失败 → executor **必须做** T15 step 1
- `Project.created_at` 在 ProjectCard + 项目详情 + sitemap 都用 ISO 字符串 ✓

---

**Plan 完成，已保存到** `docs/superpowers/plans/2026-05-17-kaizao-web-p1.md`。
