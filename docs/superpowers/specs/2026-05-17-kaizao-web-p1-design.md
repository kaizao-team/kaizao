# KAIZAO Web 撮合平台 · P1 设计文档

| 项 | 值 |
|---|---|
| 文档日期 | 2026-05-17 |
| 文档版本 | v1.0 (P1 only) |
| 作者 | liangyutao + AI 助手 |
| 状态 | Draft → 待 review |
| 目标交付 | 2 周内本地 + GitHub PR 可见，用户确认后部署 |

---

## 1. 背景与目标

KAIZAO（开造 / VCC）撮合平台 App Store 审核长期不通过，推广导流断档。本项目目标是**快速构建一个 web 平台顶上推广位**，让通过广告/搜索进来的访客（特别是手机端被 App Store 卡住的用户）能完整浏览平台供给、注册成为用户。

**P1 不是替代 App，是先把"被看见"这件事做完。** 交易闭环（发需求、撮合、订单、协作 IM）在 P2、P3 分期推进。

---

## 2. 范围（Scope）

### 2.1 P1 包含的页面（14 页）

**公开层 · 7 页**（无需登录，目标 SEO 收录）

| 路径 | 页面 | 数据来源 |
|---|---|---|
| `/` | 落地首页 | 见 §6.1 |
| `/projects` | 需求广场 | `GET /api/v1/market/projects` |
| `/projects/[id]` | 项目详情（只读） | `GET /api/v1/projects/:id` + `/projects/:id/prd` + `/projects/:id/overview` |
| `/experts` | 团队广场 | `GET /api/v1/market/experts` |
| `/experts/[id]` | 团队主页（只读） | `GET /api/v1/users/:id` + `/skills` + `/portfolios` + `/reviews` |
| `/users/[id]` | 用户公开主页 | `GET /api/v1/users/:id` + `/credit` |
| `/about` | 关于 / 隐私政策 | 静态内容，复用现有 `privacy-policy.html` 文案 |

**认证层 · 3 页**

| 路径 | 页面 | 接口 |
|---|---|---|
| `/auth/login` | 登录（短信验证码 / 密码 / 微信） | `POST /auth/sms-code` `POST /auth/login` `POST /auth/login-password` `POST /auth/wechat` |
| `/auth/register` | 注册（第一步选角色 → 第二步填手机号 → 验证码 → 完成） | `POST /auth/sms-code` `POST /auth/register` |
| `/auth/forgot` | 找回密码 | `POST /auth/password-key` `POST /auth/captcha` |

**登录后 · 4 页**

| 路径 | 页面 | 接口 |
|---|---|---|
| `/dashboard` | 个人主页（按 `role` 字段路由到项目方或团队方视图） | `GET /api/v1/home/demander` 或 `GET /api/v1/home/expert` |
| `/me` | 个人中心（资料、修改） | `GET /api/v1/users/me` + `PATCH /api/v1/users/:id` |
| `/me/projects` | 我的项目（只读列表） | `GET /api/v1/projects?owner=me` |
| `/me/notifications` | 通知 | `GET /api/v1/notifications` |

### 2.2 拦截动作（公开页上的登录墙）

未登录用户点击以下任一动作 → 弹出注册引导浮层（同时引导扫码下载 App）：

- 项目详情页 `「投标 / 联系项目方」`
- 团队主页 `「邀约 / 联系团队」`
- 用户主页 `「私信」`
- 全局导航栏 `「发布需求」`
- 任意页面 `♡` 收藏按钮

### 2.3 显式不包含（Non-goals）

P1 **不实现**以下功能，全部留给 P2 / P3：

- 发布需求 AI 对话流（`/projects/ai-chat` `/agent-sessions` `/v2/requirement/*`）
- PRD 编辑、卡片编辑
- 投标 / 撮合 / 团队推荐
- 订单 / 支付 / 钱包 / 提现
- 消息 / IM / 会话
- 项目协作（任务 / 里程碑 / 交付 / 验收 / 文件）
- 团队管理 / 成员邀请 / 收益分成
- 评价 / 评论 / 举报 / 仲裁
- 收藏 / 关注 / 设置（高级偏好）
- App 内的 onboarding 流程

未登录用户在公开页**只能看，不能动**。登录用户在 `/me` 系列页面也只能看自己的项目列表，**任何编辑/操作动作都引导用户回 App 完成**。这是 P1 的硬边界，写代码时严格执行。

---

## 3. 技术栈

| 维度 | 选型 | 理由 |
|---|---|---|
| 框架 | **Next.js 14**（App Router） | SSR/SSG 原生支持，公开页 SEO 友好；BFF 能力支持同源 API；中文社区成熟 |
| 语言 | TypeScript 5+ | 与后端 OpenAPI 契约对齐，类型可靠 |
| 样式 | **Tailwind CSS** + CSS variables | 设计系统 token 化、响应式快速 |
| 组件库 | **shadcn/ui**（Radix + Tailwind） | 可深度定制，匹配 Glassmorphism Tech 风格 |
| 状态 | TanStack Query (React Query) + Zustand（按需） | 服务端状态用 React Query；轻量 UI 状态用 Zustand |
| 表单 | React Hook Form + Zod | 类型安全的表单校验 |
| 字体 | Geist Sans + Geist Mono（next/font） | 与设计语言一致 |
| 包管理 | pnpm | 与 admin-web 保持一致 |
| 部署 | Docker（Node 20 alpine，多阶段构建） | 独立容器，不影响其他服务 |

---

## 4. 设计语言

**Glassmorphism Tech** —— 白底 + 玻璃态 + 彩色光晕 + Geist 字体。

### 4.1 设计 Token

| Token | 值 | 用途 |
|---|---|---|
| `--bg` | `#ffffff` | 主背景 |
| `--bg-subtle` | `#fbfbfd` | 浅层背景（卡片底） |
| `--fg` | `#0a0a0a` | 主文 |
| `--fg-muted` | `#5a5a6a` | 副文 |
| `--fg-faint` | `#888` | 元数据 |
| `--border` | `rgba(10,10,40,0.08)` | 玻璃边 |
| `--accent-1` | `#ff91c8` | 粉光晕（hero 装饰）|
| `--accent-2` | `#8cb4ff` | 蓝光晕 |
| `--accent-3` | `#b5ffc8` | 绿光晕 |
| `--accent-4` | `#ffdc82` | 黄/橙光晕 |
| `--gradient-hero` | `linear-gradient(120deg, #6a5ae8, #ec5e9d 60%, #ff9472)` | 标题强调字 |
| `--shadow-glass` | `0 1px 0 rgba(255,255,255,.9) inset, 0 8px 24px rgba(60,60,100,.08)` | 玻璃质感 |
| `--blur` | `20px` | backdrop-filter |
| `--radius-sm` | `6px` |  |
| `--radius` | `8px` |  |
| `--radius-lg` | `12px` |  |
| `--radius-pill` | `99px` |  |

### 4.2 视觉元素规则

- **背景光晕**：每个公开页 hero 区放 2–3 个 200–320px 的 `radial-gradient` 模糊光斑（用 `--accent-*`，filter blur 20–28px）。光晕不可穿过主内容、不影响文本对比度。
- **玻璃元素**：badge / chip / 浮层用 `background: rgba(255,255,255,0.55); backdrop-filter: blur(20px) saturate(140%); border: 1px solid rgba(255,255,255,0.8); box-shadow: var(--shadow-glass)`。
- **CTA 主按钮**：深炭实色（`rgba(10,10,26,.92)`）+ 白字 + 8px 圆角 + 投影。
- **CTA 次按钮**：玻璃态（白底半透 + blur + 内白线高光）。
- **标题强调字**：单行内最多 1 段用 `--gradient-hero` 渐变文字。
- **禁止**：纯色 1px 横线分割（用留白）、彩色品牌渐变背景（背景永远白/米白）、阴影超过 24px 模糊（避免廉价感）。

### 4.3 字体

- Display / Body: **Geist** （400/500/600）
- Mono / Tag / 数字: **Geist Mono** （400/500）
- 标题 hero: 36–48px / 字重 500 / 字间距 `-0.025em` ~ `-0.03em` / 行高 1.02–1.05
- 正文: 14–16px / 字重 400 / 行高 1.5–1.6
- 元数据: 10–12px / Geist Mono / 大写 + 字间距 `0.04–0.08em`

### 4.4 响应式断点

| 断点 | min-width | 备注 |
|---|---|---|
| `sm` | 640px | 小屏手机 |
| `md` | 768px | 平板 |
| `lg` | 1024px | 桌面 |
| `xl` | 1280px | 主设计基准 |
| `2xl` | 1536px | 大屏增强 |

设计以 `xl`（1280px）为基准。手机适配规则：单列堆叠、字号缩到 80%、Hero 区光晕缩到 60% 大小、底部导航不做（保持顶部 hamburger）。**App Store 卡的用户用手机点广告进来必须能正常浏览**，这是 P1 不可妥协的底线。

---

## 5. 信息架构 & 路由

```
/                          公开 落地首页
/projects                  公开 需求广场（列表 + 筛选）
/projects/[id]             公开 项目详情
/experts                   公开 团队广场
/experts/[id]              公开 团队主页
/users/[id]                公开 用户公开主页
/about                     公开 关于/隐私

/auth/login                登录
/auth/register             注册（多步骤：选角色 → 手机号 → 验证码）
/auth/forgot               找回密码

/dashboard                 需登录 个人主页（角色感知）
/me                        需登录 个人中心
/me/projects               需登录 我的项目
/me/notifications          需登录 通知

/api/[...path]             BFF · 反代到 kaizao-server
```

### 5.1 路由守卫

- **公开页**：服务器渲染时不依赖 cookie，可以匿名访问。
- **`/auth/*`**：已登录用户访问 → 重定向到 `/dashboard`。
- **`/dashboard` `/me/*`**：未登录用户访问 → 重定向到 `/auth/login?from=<原路径>`。
- **拦截动作组件**：用客户端 hook（`useRequireAuth()`）判断，未登录则弹注册引导浮层而非跳转，保持当前页上下文。

---

## 6. 关键页面结构

### 6.1 落地首页 `/`

七个 section（按顺序）：

1. **Hero**：双 CTA（`我是项目方 · 发起项目` / `我是团队方 · 接需求`），背景光晕 + 玻璃态 badge `POWERED BY AI · v2`，主标题用渐变强调字。
2. **价值主张三宫格**：AI 拆解需求 / T1–T10 团队评级 / 全流程透明协作。
3. **如何工作（How it works · 4 步）**：发起需求 → AI 对话生成 PRD → 撮合靠谱团队 → 协同交付。每步带玻璃态卡片 + Mono 编号。
4. **精选需求 + 精选团队**：分别拉 `GET /api/v1/market/projects?limit=6` 和 `GET /api/v1/market/experts?limit=6`，展示真实数据做 social proof。
5. **平台数据墙**：进行中项目数 / 入驻团队数 / 累计完成 GMV / 任务数。**先用前端硬编码占位，等后端给口径再切换 API**。
6. **FAQ**：4–6 条手写问答。
7. **Footer**：导航分组（产品 / 公司 / 法务）、备案号、联系方式。

### 6.2 需求广场 `/projects`

- 顶部筛选区：领域 / 预算区间 / 期限 / 状态（招标中/已截止）—— 玻璃态 chip 横排。
- 列表：响应式 grid（xl=3 列 / md=2 列 / sm=1 列），每条卡片显示标题、一行描述、预算、期限、领域标签、发布时间、`「查看详情」`。
- 分页：游标分页（cursor）或 `page` + `pageSize`，看后端 `/market/projects` 实际支持。**实现时 verify** 接口分页协议。
- 空状态：玻璃态卡片 + 引导文案。

### 6.3 项目详情 `/projects/[id]`

- 顶部：项目名 + 状态 pill + 发布时间。
- 项目方信息卡（玻璃态）：头像、姓名、信用分（从 `/users/:id/credit` 拿）。
- 概览（overview）：核心字段，预算、期限、领域、技术栈、阶段。
- PRD 卡片列表：从 `/projects/:id/prd` 拿，**只读渲染**，不暴露编辑按钮。
- 附件列表：从 `/projects/:id/files`（如有公开权限）。
- 底部固定 CTA 区：`「我有团队，想投标」` `「联系项目方」` —— 未登录点击触发拦截浮层。

### 6.4 团队广场 / 团队主页 / 用户公开主页

类似项目广场和项目详情的结构，复用组件。详细字段在实现时按 v1 接口实际返回字段映射，spec 阶段不预先猜字段名（避免 spec drift）。

### 6.5 注册 `/auth/register`

3 步骤：

1. **选角色**：两张大卡，"我是项目方" / "我是团队方"，玻璃态 hover 高亮。
2. **手机号 + 短信验证码**：调 `POST /auth/sms-code` 发送，60s 倒计时按钮。
3. **完成**：调 `POST /auth/register`，BFF 把返回的 token 写入 HttpOnly Cookie（详见 §7.2），跳 `/dashboard`。

不做完整 onboarding（不让填昵称头像简介技能）。让用户先进来看，需要补资料时引导 `/me`。

---

## 7. API 集成策略

### 7.1 BFF 反代

Next.js App Router 的 `app/api/[...path]/route.ts` 做透明反代：

```
浏览器 → https://www.kaizao.cc/api/v1/market/projects
       → nginx (kaizao.cc) → kaizao-web:3000
       → Next.js BFF /api/[...path]
       → http://kaizao-server:8080/api/v1/market/projects
```

- 同源调用，无 CORS。
- 转发 `Authorization`、`Cookie` 头。
- SSR 阶段（公开页）直接 `fetch('http://kaizao-server:8080/...')` 走内网，跳过 BFF 一层。
- v2 接口（`/api/v2/*`）走同样代理（P1 实际不用 v2，但路由要预留）。

### 7.2 鉴权

- 登录成功后，token 存储为 **HttpOnly Cookie**（BFF 设置，前端拿不到）。
- 每次 API 请求 BFF 自动从 cookie 读 token 注入 `Authorization` 头。
- 登出：BFF 清 cookie + 调 `POST /auth/logout`。
- 不在 localStorage 存 token（XSS 风险）。

### 7.3 错误处理

| HTTP 状态 | 行为 |
|---|---|
| 401 | 清 cookie，路由守卫触发 → 跳 `/auth/login` |
| 403 | 顶部 toast `权限不足`，不跳页 |
| 404（业务） | 页面级 not-found 状态 |
| 5xx | toast `服务暂时不可用`，列表页保留旧数据 |
| 网络中断 | React Query 自动重试 3 次（指数退避） |

---

## 8. 项目结构

新增 `web/` 目录（与 `app/` `server/` `ai-agent/` `admin-web/` 平级）：

```
web/
  app/                    Next.js App Router
    (public)/             公开页路由组
      page.tsx                 /
      projects/
        page.tsx               /projects
        [id]/page.tsx          /projects/[id]
      experts/
        page.tsx               /experts
        [id]/page.tsx          /experts/[id]
      users/[id]/page.tsx      /users/[id]
      about/page.tsx           /about
    auth/
      login/page.tsx
      register/page.tsx
      forgot/page.tsx
    (dashboard)/          需登录路由组（带守卫）
      dashboard/page.tsx
      me/
        page.tsx
        projects/page.tsx
        notifications/page.tsx
    api/
      [...path]/route.ts  BFF 反代
    layout.tsx            根布局
    globals.css
  components/
    ui/                   shadcn/ui 组件
    layout/               Header / Footer / Container
    landing/              落地页 sections
    cards/                ProjectCard / ExpertCard
    auth/                 AuthIntercept 浮层
  lib/
    api/                  接口封装（按模块）
    auth/                 鉴权 hook
    utils/                
  styles/
    tokens.css            设计 token
  public/                 静态资源（logo、favicon）
  Dockerfile
  docker-compose.yml      （只声明 kaizao-web 服务，extends 主 stack）
  .env.example
  package.json
  next.config.js
  tailwind.config.ts
  tsconfig.json
```

---

## 9. 部署方案

### 9.1 容器化

- 多阶段 Dockerfile：`node:20-alpine` builder + `node:20-alpine` runner（`output: 'standalone'`）。
- 镜像内只跑 `node server.js`，端口 3000。
- 容器名 `kaizao-web`，暴露 `127.0.0.1:39532` 不对外暴露。

### 9.2 nginx 接入

`kaizao-static-web` 容器的 nginx 加 server block：

```nginx
server {
  listen 443 ssl;
  server_name www.kaizao.cc kaizao.cc;
  # ssl_certificate ...

  location / {
    proxy_pass http://kaizao-web:3000;
    # SSR + 静态资源 一并走 Next.js
  }
}
```

**严格独立**：不动 `newapi` `kaizao-server` `kaizao-mysql` `kaizao-redis` `epay-*` 任何容器和配置。`docker compose up -d kaizao-web` 只重建这一个服务。

### 9.3 发布流程

1. 本地 `pnpm dev`，在 `http://localhost:3000` 验收。
2. 推 GitHub PR，用户在本地拉分支 `pnpm dev` 二次验收。
3. 用户批准后：rsync `web/` 到 `47.236.165.75:/home/app/kaizao-web/`（用 `--exclude-from`，不覆盖 `.env`）。
4. `ssh app@47.236.165.75 'cd /home/app/kaizao-web && docker compose up -d --build'`
5. 更新 `kaizao-static-web` 的 nginx 配置（加 server block），`nginx -t` + `nginx -s reload`。

### 9.4 环境变量

`web/.env.example`：

```
NEXT_PUBLIC_SITE_URL=https://www.kaizao.cc
KAIZAO_SERVER_INTERNAL=http://kaizao-server:8080
AI_AGENT_INTERNAL=http://vibebuild-ai-agent:39528
NODE_ENV=production
```

线上 `.env` 不进 git，按 rsync 铁律不覆盖（参考 `ai-agent/.env.production.example` 的做法）。

---

## 10. 测试策略

- **类型 + lint**：CI 跑 `pnpm typecheck` + `pnpm lint`，任一失败 block 合并。
- **单元测试**：组件级用 Vitest + React Testing Library。覆盖 ProjectCard、ExpertCard、AuthIntercept、Header 等关键组件渲染逻辑。
- **e2e（最低门槛 4 条）**：用 Playwright 跑
  1. 访客打开 `/` → 看到 hero 和精选需求
  2. 访客打开 `/projects` → 列表加载 → 点详情进项目页
  3. 访客点 `「投标」` → 弹注册引导
  4. 完整注册 → 跳 `/dashboard` → 看到个人信息
- **手动验收**：实现完成后必须在 Chrome + Safari + 移动 Safari（iOS Simulator）三处实际打开页面，检查光晕渲染、玻璃态 backdrop-filter、字体加载。

---

## 11. 风险与缓解

| 风险 | 缓解 |
|---|---|
| 接口字段与 Flutter 端使用习惯不一致 | 实现每个页面前先 curl 一次该接口，把实际返回字段写进对应组件的 ts 类型注释 |
| Glassmorphism 在低端设备 / Firefox 渲染降级 | `@supports (backdrop-filter: blur(10px))` 兜底，不支持时退化为半透白底 |
| SEO 收录需要 sitemap | 实现 `app/sitemap.ts` + `app/robots.ts`，自动列举公开页 |
| 项目详情/团队主页可能含敏感字段（电话等） | 公开页 API 返回时**期待**已脱敏；实现时 verify，若发现明文敏感字段，先在前端 mask + 在 PR 描述里明确 flag 给用户，由用户决定是否走后端修复（P1 不擅自改后端） |
| 站点首次访问 SSR 慢 | Next.js standalone + cache header；落地页 ISR（revalidate 60s）|

---

## 12. 开放问题（TBD）

| ID | 问题 | 决策时机 |
|---|---|---|
| OQ-1 | 域名 —— 是否直接占用 `www.kaizao.cc`（替换现有 index.html），还是先用 `web.kaizao.cc` 子域名灰度 | 部署前一天 |
| OQ-2 | 平台数据墙的口径是用真实接口还是硬编码 | 实现 §6.1 step 5 时再问 |
| OQ-3 | App Store 引导浮层里是放下载链接还是 QR 码？或者两者都放？ | 实现拦截浮层时再问 |
| OQ-4 | 注册新用户给的默认 token 时效 / 是否需要邮箱校验 | 实现注册流程时与后端 contract 对齐 |

---

## 13. 验收标准

P1 视为完成的硬指标：

- [ ] 全部 14 个页面在 `pnpm dev` 本地能正常打开
- [ ] 全部 7 个公开页能在未登录状态加载完整内容（除拦截动作外）
- [ ] 完整注册 → 登录 → 退出闭环可走通
- [ ] 4 条 e2e 测试全绿
- [ ] Chrome / Safari / iOS Mobile Safari 三端目测无 layout 崩坏
- [ ] Lighthouse SEO 评分 ≥ 90（落地页 + 任意广场页）
- [ ] 部署到 47 后，`https://www.kaizao.cc` 访问正常
- [ ] `newapi` / `kaizao-server` / `kaizao-mysql` / `kaizao-redis` 容器健康状态在部署前后无变化

---

## 14. 后续（Out of P1）

P2 / P3 的初步划分（详情待 P1 完成后单独 brainstorm）：

- **P2 · 双边交易闭环**：发布需求（AI 对话）/ PRD 编辑 / 投标撮合 / 订单支付 / 钱包 / 评价
- **P3 · 协作沟通**：消息 IM / 通知详情 / 项目协作（任务、里程碑、交付）/ 团队管理
