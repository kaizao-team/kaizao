# 开造 VCC — 前端 AI 协作规范

> 适用对象：Claude Code、Codex、Cursor 及其他 AI 编码助手。
> 只要在 `app/` 里写 Flutter 代码，就默认遵守本文件。

---

## 规范优先级

前端相关工作按这个顺序收口：

1. 本文件
2. [DESIGN_SPEC.md](/Users/dylanthomas/Desktop/projects/kaizao-repo/app/DESIGN_SPEC.md)
3. `.cursor/rules/*.mdc`
4. 当前目录或子目录下的 `CLAUDE.md`

如果几份规范冲突，遵循“更具体的目录规范覆盖更上层规范”。

---

## 总原则

当前前端不是品牌展示页视觉，也不是典型 SaaS 仪表盘。

运行与验证硬性规则：
- 开发阶段禁止拉起 Web 端做预览或验收
- 不使用 `flutter run -d chrome`、浏览器预览、或其他 Web 调试链路
- UI 开发、联调、验收默认走移动端模拟器
- iOS 优先使用 Simulator；Android 场景使用 Android Emulator
- 除非 Dylan 明确要求，否则不要用 `macos` 作为前端验证目标

统一设计语言：
- **Architectural Minimalism / The Digital Atheneum**
- 关键词：安静、克制、内容优先、编辑式、带建筑感的秩序

核心要求：
- 单色为主，靠层级、排版、留白做区分
- UI 是内容容器，不是视觉主角
- 默认用大留白、背景层级、节奏变化建立结构
- 默认不要彩色主层、普通渐变、重阴影、密集边框
- 布局允许非对称，不要把所有内容堆成中轴居中大卡片

联调与真实接口原则：
- 发现后端字段缺失、结构变化、文案异常、超时、状态不一致时，优先暴露给 Dylan
- 禁止为了“先跑通”而添加静默兼容、假数据兜底、自动猜测字段、协议降级
- 除非 Dylan 明确要求临时兼容方案，否则前端应按真实返回接入，并把问题点清楚记录出来

---

## 产品语言

前端界面、前端文档、PR 描述统一使用：

- `项目方`：有需求、发起项目的人（role=1）
- `团队方`：承接需求、提供交付的人（role=2）
- `引导`
- `首页`
- `广场`
- `项目`

避免继续在前端规范里混用这些旧词：

- `需求方`（旧称，统一用 `项目方`）
- `专家`（旧称，统一用 `团队方`）
- `发起人`
- `造物者`
- `甲方`
- `外包`
- `码农`

---

## 提交与 PR 规范

适用于 Claude Code、Codex、Cursor 及其他 AI 编码助手。

### Commit Message 风格

统一使用：

`type(scope): summary`

硬性规则：

- `type` 必须使用英文小写：`feat`、`fix`、`refactor`、`docs`、`chore`、`ci`、`test`
- `scope` 必须明确，优先写功能域或改动层：`home`、`market`、`auth`、`project`、`shared`、`ci`
- `summary` 默认使用英文短语，保持单行、简洁、可扫描，不写空话，不堆砌并列动作
- 同一仓库内默认保持同一风格：`英文 type + 英文 scope + 英文 summary`
- 不要混用 `update`、`modify`、`adjust` 这类信息量很低的词
- 不要在 commit message 里写大段背景、测试过程、情绪化描述

推荐示例：

- `feat(home): add team opportunities section`
- `fix(auth): handle expired token redirect`
- `refactor(shared): simplify empty state layout`
- `docs(app): define AI commit message convention`
- `ci(review): localize AI review comments`

不推荐示例：

- `update`
- `fix bug`
- `首页又改了一下`
- `feat: do many things`
- `chore(misc): tweak stuff`

### 提交粒度

- 一个 commit 只做一类事情，不要把功能、视觉、接口、CI、文档揉在一起
- 规范文档改动单独提交，避免和业务代码混在同一个 commit
- CI / bot / workflow 改动单独提交

### PR 规则

- PR 描述统一中文，commit message 按上面的统一格式
- 不要把个人分支名、临时协作流转写进通用 AI 规范

---

## 颜色与层级

### Foundation

| 角色 | 色值 | 说明 |
|------|------|------|
| `surface` | `#F9F9F9` | 主画布 |
| `on_surface` | `#1A1C1C` | 主文本 |
| `primary` | `#111111` | 主操作 |
| `outline_variant` | `#C6C6C6` 低透明度 | 极弱结构边界 |

### Surface Hierarchy

| 层级 | 色值 | 用途 |
|------|------|------|
| Level 0 | `#F9F9F9` | 页面底 |
| Level 1 | `#F3F3F3` | 子区块、hover、次级背景 |
| Level 2 | `#FFFFFF` | 卡片、输入、浮层主体 |
| Level 3 | `#E8E8E8` | 次级按钮、高显著度容器 |

### 规则

- 紫色、蓝色只允许做小面积强调，不做大面积主层级
- 默认不要靠边框分区，优先用背景层级切换
- 正文不要纯黑，统一靠近 `#1A1C1C`
- CTA 默认黑底
- 允许极轻 tonal shift，但只限黑到炭灰：
  - `#000000 -> #3C3B3B`

---

## No-Line Rule

硬性规则：

- 不允许用标准 1px 实线切 section
- 不允许把 `Divider()` 当主要层次手段
- 列表默认不要画线

可用例外：

- 输入框默认态的 ghost border
- 对比不足时 1px `outline_variant`
- focus 态 1.5px 深色边框

---

## 排版

目标气质：

- 标题像编辑刊名
- 元数据像建筑导视
- 正文稳定、克制、不喧宾夺主

### Typeface Strategy

- Headlines：**Plus Jakarta Sans**
- Body / Labels：**Inter**
- 中文默认跟随系统字体，但要保持层级和字重节奏一致

### Hierarchy

- 标题级差要拉开，不要平均字号梯度
- 允许 display 直接搭配小号说明文
- metadata 用小字号、全大写、适度字距

---

## 间距与布局

规则：

- 大区块之间敢用 48px 以上留白
- 页面不要“中间一坨”
- 列表项之间优先用白空间隔开，不插分割线
- 避免 bootstrap 式均匀卡片网格
- 首页、引导页优先内容流，不要机械 KPI 仪表盘

---

## 深度

默认不用传统阴影塑形，优先 **Tonal Layering**。

规则：

- Level 2 白卡放在 Level 1 灰底上，已经形成自然抬升
- 常规卡片不加重阴影
- 真正浮层允许极弱 ambient shadow

Ambient shadow：

- Blur：24px - 40px
- Opacity：4% - 6%
- Color：从 `#1A1C1C` 派生

---

## 组件规则

### Buttons

- `Primary`：黑底浅字
- `Secondary`：`#E8E8E8` 背景
- `Tertiary`：无底，hover/focus 时再给极弱边界

禁止：

- 紫色主按钮
- 品牌渐变按钮
- 发光按钮

### Cards & Lists

- 不要用 divider 切列表
- 通过垂直留白和背景变化区分
- 卡片不要靠边框硬框出来

### Input Fields

- 默认白底或浅灰底
- 默认 1px ghost border
- focus 用 1.5px 深色边界
- 不要 glow

### Geometry

- 默认 8px - 12px rounded square geometry
- 头像是唯一允许的圆形 UI 元素
- 图标容器不允许做圆形

---

## 共享组件策略

优先复用这些基础件：

- `VccButton`
- `VccInput`
- `VccCard`
- `VccTag`
- `VccAvatar`
- `VccToast`
- `VccEmptyState`
- `VccLoading`
- `VccBottomNav`

补充规则：

- 基础动作、输入、空态、加载态优先走共享组件
- 复杂业务块、页面结构件放 `features/*/widgets`
- 如果共享组件不符合规范，先修共享组件，再决定是否复用
- 不要为了复用把首页 Hero、引导骨架、复杂业务卡片强塞进 `shared/widgets`

---

## UI 健壮性检查

所有 UI 改动提交前必须满足：

- 禁止出现 `RenderFlex overflowed`
- 禁止文本裁切、按钮压坏、徽标被顶出
- 默认按小屏和主流手机宽度检查
- `Row` / `Column` / `Wrap` 默认考虑长文本和极端状态
- 能用自然高度布局就不要用固定高度
- analyze 通过不算完成，必须实际看页面

---

## 首页特别说明

首页不是一个中性容器，它按角色分叉：

- 项目方首页：灵感入口、分类、项目、推荐团队方
- 团队方首页：收入、推荐需求、技能热度、后续可扩展组队机会

要求：

- 两个首页可以共享基础骨架，但不要做成同一页面换几段文案
- 项目方更像内容入口和任务组织
- 团队方更像工作台，但仍然保持内容型节奏，不要做传统后台 dashboard

---

## 严禁事项

| 禁止 | 正确做法 |
|------|----------|
| ❌ 紫色/蓝色大面积铺底 | ✅ 黑白灰层级 + 小面积强调色 |
| ❌ 品牌渐变 Hero | ✅ 单色主视觉，必要时只用黑到炭灰 tonal shift |
| ❌ divider / 实线切区块 | ✅ 背景层级切换 + 留白 |
| ❌ 重阴影 / 发光 / 科技蓝 | ✅ Tonal Layering |
| ❌ 所有内容居中堆叠 | ✅ 非对称构图 + 留白 |
| ❌ 圆形图标容器 | ✅ rounded square |
| ❌ 平均字号梯度 | ✅ 拉大层级差 |
| ❌ 文案里混用旧角色称呼 | ✅ 统一用项目方/团队方 |

---

## 项目结构速查

```text
app/lib/
├── app/
│   ├── routes.dart
│   └── theme/
├── core/
│   ├── network/
│   ├── storage/
│   └── mock/
├── features/
│   ├── auth/
│   ├── home/
│   ├── market/
│   ├── onboarding/
│   ├── project/
│   └── ...
└── shared/
    ├── widgets/
    └── models/
```

## 状态管理

- 使用 **Riverpod**
- 路由使用 **GoRouter**
- 页面逻辑优先拆成 `page / provider / repository / widget`
