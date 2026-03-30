# CLAUDE.md

本文件提供仓库级协作约束。默认面向 Claude Code、Codex、Cursor 等 AI 编码助手。

---

## 项目概览

**开造（Kaizao / VCC）** 是一个 AI 驱动的软件需求撮合平台。

- `app/`：Flutter 前端
- `server/`：Go 后端
- `ai-agent/`：Python AI 服务
- `deploy/`：部署相关文件
- `docs/` / `app/doc/`：产品、设计、技术文档

---

## 默认边界

- 如果任务明确落在前端，默认只改 `app/`
- 不要顺手修改 `server/` 或 `ai-agent/`，除非用户明确要求
- 生成文件、缓存文件、临时脚本不要提交进 PR

---

## Commit Message 规范

所有 AI 编码助手统一使用：

`type(scope): summary`

硬性规则：

- `type` 使用英文小写：`feat`、`fix`、`refactor`、`docs`、`chore`、`ci`、`test`
- `scope` 必须具体，优先写功能域或改动层，如 `home`、`market`、`auth`、`project`、`shared`、`ci`
- `summary` 默认使用英文短语，保持单行、简洁、可扫描
- 同一仓库内保持统一风格：`英文 type + 英文 scope + 英文 summary`
- 不要使用 `update`、`modify`、`adjust`、`misc`、`tweak stuff` 这类信息量低的写法
- 不要把多个不相关动作塞进同一个 commit message

---

## 前端规范优先级

前端相关工作按以下顺序收口，越靠前优先级越高：

1. [app/AGENTS.md](/Users/dylanthomas/Desktop/projects/kaizao-repo/app/AGENTS.md)
2. [app/DESIGN_SPEC.md](/Users/dylanthomas/Desktop/projects/kaizao-repo/app/DESIGN_SPEC.md)
3. [.cursor/rules/design-tokens.mdc](/Users/dylanthomas/Desktop/projects/kaizao-repo/.cursor/rules/design-tokens.mdc)
4. [.cursor/rules/forbidden.mdc](/Users/dylanthomas/Desktop/projects/kaizao-repo/.cursor/rules/forbidden.mdc)
5. [.cursor/rules/ui-safety.mdc](/Users/dylanthomas/Desktop/projects/kaizao-repo/.cursor/rules/ui-safety.mdc)
6. 各目录下局部 `CLAUDE.md`

如果几份规范冲突，遵循“更具体的目录规范覆盖更上层规范”。

---

## 前端设计语言

当前前端统一采用：

- **Architectural Minimalism / The Digital Atheneum**
- 关键词：单色层级、编辑式留白、克制、安静、内容优先
- 默认不要品牌渐变、重阴影、强彩色、线性分割
- 允许极轻的黑到炭灰 tonal shift，但只用于 Hero 或主 CTA

---

## 前端产品语言

前端界面、交互文案、说明文档统一使用以下说法：

- `需求方`：有需求、发起项目的人
- `专家`：承接需求、提供交付的人
- `引导`：首次 onboarding 流程
- `首页`：按角色切分为需求方首页 / 专家首页

避免继续在前端规范中使用这些旧说法：

- `发起人`
- `造物者`
- `甲方`
- `码农`
- `外包平台`

---

## 公共组件策略

- 基础按钮、输入、卡片、空状态、toast、loading 优先复用 `app/lib/shared/widgets`
- 复杂业务模块、页面级组合结构放在 `app/lib/features/*/widgets`
- 如果共享组件不符合规范，先修共享组件，再决定是否复用
- 不要为了“强行复用”把复杂业务块塞进 `shared/widgets`

---

## 常用命令

```bash
# Flutter app
cd app && flutter analyze
cd app && flutter run -d chrome
cd app && flutter run -d macos

# Git
git fetch origin
git status -sb
```

---

## 交付要求

- 文档、代码、PR 描述口径必须一致
- 提 PR 默认使用中文，写清楚“做了什么 / 怎么验证 / 不包含什么”
- analyze 通过不等于完成，涉及 UI 的改动要实际看页面
