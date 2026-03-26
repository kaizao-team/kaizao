# 开造 Flutter 前端设计规范

> 风格定位：**Architectural Minimalism / The Digital Atheneum**
> 关键词：安静、克制、编辑式、建筑感、内容优先。
> 本文件是 `app/` 前端设计语言的详细说明，和 `app/AGENTS.md`、`.cursor/rules/*.mdc` 保持同一口径。

---

## 1. 适用范围

适用于：

- `app/lib/` 下所有 Flutter 页面与组件
- 新增页面、改版页面、共享组件、模块内 widget
- PR 描述里的前端设计说明

不适用于：

- `server/`
- `ai-agent/`
- 部署脚本

---

## 2. 产品语言

前端界面和前端规范统一使用：

- `需求方`
- `专家`
- `引导`
- `首页`
- `广场`
- `项目`

弃用以下旧词：

- `发起人`
- `造物者`
- `甲方`
- `外包`
- `码农`

---

## 3. 视觉总原则

开造前端不是炫技型 AI 工具界面，也不是冷冰冰的后台面板。

核心原则：

- UI 服务内容，不抢内容
- 单色层级优先，彩色强调从属
- 结构靠留白、排版、背景层级建立
- 允许编辑式非对称构图
- 页面不追求“铺满”，要保留呼吸感

---

## 4. 色彩系统

### 4.1 Foundation

| Token | Hex | 说明 |
|-------|-----|------|
| `surface` | `#F9F9F9` | 主画布 |
| `surfaceAlt` | `#F3F3F3` | 次级背景、区块底 |
| `surfaceRaised` | `#FFFFFF` | 卡片、输入、浮层主体 |
| `surfaceStrong` | `#E8E8E8` | 次级按钮、高显著度容器 |
| `onSurface` | `#1A1C1C` | 主文本 |
| `primary` | `#111111` | 主操作 |
| `outlineVariant` | `#C6C6C6` 低透明度 | 极弱边界 |

### 4.2 Accent

保留紫色作为点缀，但只做小面积使用：

| Token | Hex | 说明 |
|-------|-----|------|
| `accent` | `#7C3AED` | 选中态、链接、小面积强调 |
| `accentSoft` | `#F3EEFF` | 极轻底色、标签底 |

规则：

- 禁止紫色、蓝色做大面积主层级
- 禁止彩色主按钮
- 禁止彩色 Hero 大背景

### 4.3 唯一允许的纹理

只允许黑到炭灰的极轻 tonal shift：

- `#000000 -> #3C3B3B`

使用范围：

- Hero
- Main CTA

它不是品牌渐变，只是黑色层次。

---

## 5. No-Line Rule

默认不要通过线来切区块。

硬性规则：

- 不使用标准 1px 实线切 section
- 不使用 `Divider()` 作为主要层次
- 列表项之间默认不画线

允许例外：

- 输入框默认 ghost border
- 对比不足时的 1px `outlineVariant`
- focus 态 1.5px 深色边框

---

## 6. 排版系统

### 6.1 字体

- Headlines：**Plus Jakarta Sans**
- Body / Labels：**Inter**
- 中文默认跟随系统字体，但保持相同层级逻辑

### 6.2 排版原则

- 标题级差要拉开，不做平均字号梯度
- metadata 使用小字号、全大写、适度字距
- 正文追求稳定可读，不追求过度设计
- 标题和说明文之间要有明确节奏，不要粘连

### 6.3 建议层级

| 层级 | 尺寸建议 | 用途 |
|------|----------|------|
| Display | 28-36 | Hero / 页面主标题 |
| H1/H2 | 20-28 | 区块标题 |
| Title | 16-18 | 卡片标题、列表标题 |
| Body | 14-16 | 正文 |
| Meta | 10-12 | 标签、辅助说明、状态 |

---

## 7. 间距与布局

### 7.1 间距原则

- 大区块之间优先 32px - 48px
- 重要转场区块可以更大
- 卡片内部常用 16px - 20px
- 列表项之间优先用垂直白空间隔，不用线

### 7.2 布局原则

- 页面不要“中间一坨”
- 不要默认均匀网格
- 首页和引导优先内容流，不要做 KPI 仪表盘
- 允许非对称、错位、长留白的 editorial 构图

---

## 8. 深度与阴影

默认优先 **Tonal Layering**：

- 白卡放在浅灰底上，已经足够形成抬升
- 常规卡片不要重阴影
- 真正浮层才用 ambient shadow

Ambient shadow 建议：

- Blur：24px - 40px
- Opacity：4% - 6%
- Color：从 `#1A1C1C` 派生

---

## 9. 组件规范

### 9.1 Buttons

- `Primary`：黑底浅字
- `Secondary`：浅灰底
- `Tertiary`：无底或极弱边界

禁止：

- 紫色主按钮
- 品牌渐变按钮
- 发光按钮

### 9.2 Cards

- 背景：`surfaceRaised`
- 默认无边框
- 通过背景层级和留白建立结构
- 复杂业务卡片可以做独立 widget，但要延续同一层级逻辑

### 9.3 Inputs

- 白底或浅灰底
- 默认 1px ghost border
- focus 态 1.5px 深色边界
- 不使用 glow

### 9.4 Tags / Badges

- 小面积使用强调色或语义色
- 不要做成彩色主视觉块

### 9.5 Geometry

- 默认使用 8px - 12px rounded square geometry
- 头像是唯一允许的圆形 UI 元素
- 图标容器不允许圆形

---

## 10. 首页设计要求

首页明确按角色分叉：

### 需求方首页

- 更像“灵感与任务入口”
- 核心模块：AI 入口、分类、项目、推荐专家
- 语气偏引导与组织，不要做满屏 KPI

### 专家首页

- 更像“工作台”
- 核心模块：收入、推荐需求、技能热度、后续可扩展组队机会
- 可以比需求方更结构化，但仍然保持内容流和留白节奏

统一要求：

- 两个首页不要只是同模板换文案
- 允许共享骨架，但内容节奏和优先级必须不同

---

## 11. 共享组件策略

### 11.1 优先共享的基础件

- `VccButton`
- `VccInput`
- `VccCard`
- `VccTag`
- `VccAvatar`
- `VccToast`
- `VccEmptyState`
- `VccLoading`

### 11.2 不要硬共享的内容

- 首页 Hero
- 引导页骨架
- 模块特有业务卡
- 复杂组合结构

这些更适合放在 `features/*/widgets`

### 11.3 决策规则

- 基础交互件优先复用共享组件
- 复合结构优先模块内封装
- 如果共享组件不符合规范，先修共享组件，再决定是否复用

---

## 12. UI 健壮性

提交前必须满足：

- 无 `RenderFlex overflowed`
- 无白屏、约束冲突、黄黑条
- 长文本、短文本、加载态、错误态都稳定
- 小屏和主流手机宽度可用
- analyze 通过不等于完成，必须实际运行页面

---

## 13. 当前代码 Token 对应

当前代码里常见的对应关系：

- `AppColors.black` / `AppColors.onboardingPrimary`：主操作黑
- `AppColors.onboardingBackground` / `AppColors.gray50`：主画布
- `AppColors.onboardingSurface` / `AppColors.white`：抬升面
- `AppColors.onboardingSurfaceMuted` / `AppColors.gray100`：次级面
- `AppColors.accent`：小面积强调色

设计稿和代码如果暂时不完全一致，以本规范的方向收口，逐步消化旧 token。

---

## 14. 严禁事项

- ❌ 大面积紫色 / 蓝色铺底
- ❌ 品牌渐变 Hero / 渐变按钮 / 渐变卡片
- ❌ divider 切区块
- ❌ 重阴影、glow、毛玻璃
- ❌ 所有内容均匀堆叠
- ❌ 圆形图标容器
- ❌ 文案里混用发起人 / 造物者

对应正确做法：

- ✅ 黑白灰层级 + 小面积强调色
- ✅ tonal layering + 大留白
- ✅ 结构型排版
- ✅ 需求方 / 专家统一术语
