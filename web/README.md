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
