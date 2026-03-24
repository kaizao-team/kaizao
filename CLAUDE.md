# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

---

## Project Overview

**开造 (VCC — Vibe Coding Company)** — AI 驱动的 Vibe Coding 服务撮合平台。

Two-sided marketplace connecting:
- **发起人 (Demand side)**: People with software ideas
- **造物者 (Supply side)**: Vibe Coders (AI-assisted developers)

Three AI Agents drive the workflow: 需求分析 Agent, 项目管理 Agent, 质量检查 Agent.

---

## Repository Structure

```
kaizao/
├── app/                    # Flutter mobile app (iOS + Android + Web)
│   ├── lib/
│   │   ├── app/            # App shell, theme, routes
│   │   │   └── theme/      # Design tokens (MUST follow DESIGN_SPEC.md)
│   │   ├── core/           # Network, storage, constants
│   │   ├── features/       # Feature modules (auth, home, chat, project, profile, match)
│   │   └── shared/         # Shared widgets (VccButton, VccCard, etc.), models
│   ├── DESIGN_SPEC.md      # ⭐ Frontend design spec (source of truth for UI)
│   └── pubspec.yaml
├── server/                 # Go backend (Gin framework)
├── ai-agent/               # Python AI services (FastAPI + LangGraph)
├── deploy/                 # Docker Compose, Nginx, DB migrations
├── docs/                   # Product documentation (PRD, design, business)
│   ├── 01-产品/
│   ├── 02-设计/
│   ├── 04-运营/
│   └── 06-商业/
└── Makefile                # Project-wide commands
```

---

## Design System: "Quiet Craft"

**CRITICAL**: All UI work MUST follow `app/DESIGN_SPEC.md`. Key rules:

- **NO GRADIENTS** on any UI element. Only exceptions: Splash Screen bg + Logo.
- **NO circular containers** for icons/categories. Use squircle (14px radius). Avatars are the only circular exception.
- Primary CTA buttons: **solid dark `#1A1A1A`**, NOT purple gradient.
- Purple `#7C3AED` used sparingly: selected states, text links, small accents.
- Background: warm white `#F6F6F6`, never cold gray.
- No 1px divider lines. Use tonal layering + spacing instead.
- Shadows: subtle (`0 2px 8px rgba(0,0,0,0.04)`), never heavy.

---

## Tech Stack

| Layer | Tech |
|-------|------|
| Mobile | Flutter 3.41+ / Dart, Riverpod, go_router |
| Backend | Go (Gin), gRPC between services |
| AI Agent | Python, FastAPI, LangGraph, LlamaIndex |
| LLM | Claude API (complex) / DeepSeek (cost-sensitive) |
| DB | PostgreSQL + Redis + Elasticsearch |
| Infra | Docker + Nginx, planned: Aliyun K8s |

---

## Brand & Terminology

| Term | Meaning |
|------|---------|
| 开造 | Product name (Chinese) |
| VCC | Company symbol (Vibe Coding Company) |
| 造物者 | Supply-side users (never "程序员" or "码农") |
| 发起人 | Demand-side users |
| 接造 | Supplier accepting a project (not "接单") |
| EARS卡片 | AI-generated structured requirement cards |

**Slogan**: 点亮每一个想法
**Forbidden terms**: 外包, 程序员, 码农, 最好的/第一/唯一

---

## Development Commands

```bash
# Flutter app
cd app && flutter run -d chrome        # Web dev
cd app && flutter run -d macos         # Desktop dev
cd app && flutter analyze              # Lint check

# Full stack (Docker)
make dev                               # Start all services
make stop                              # Stop all
```
