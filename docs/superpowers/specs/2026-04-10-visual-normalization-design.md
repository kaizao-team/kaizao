# 视觉规范化设计 — 5 个 Tab 页面统一

## Context

开造 app 经过 vibe coding 阶段，各页面独立开发导致视觉细节不一致。设计 token 体系（AppColors / AppSpacing / AppRadius / AppTextStyles）已完整定义，但执行层面存在大量 drift：164 处硬编码颜色、~150 处非标圆角、~500+ 处硬编码间距。

本次目标：统一 5 个底部 Tab 页面（首页、广场、通知、项目列表、Profile）的视觉规范，建立可复用的 header 组件，补充页面切换动画。

---

## Design Decisions

### Header 风格
| 页面 | 风格 | 展开态 | 收缩态 |
|------|------|--------|--------|
| 首页 | Hero Dissolve | 深色 tonal 渐变卡片 (#111→#3C3B3B) + 用户名 + 关键指标 | 紧凑深色导航栏 + 指标摘要 |
| 广场 / 通知 / 项目 / Profile | Editorial Compact | 大标题 + 副信息行 | Overline 小标题 + 信息 pill |

### 页面转场
| 场景 | 动画 | 时长 |
|------|------|------|
| Tab 切换 | Crossfade | 200ms (AppDurations.normal) |
| 详情 push | Cupertino slide（保持现有） | 350ms |
| 模态 sheet | Slide up from bottom | 300ms |

### 统一设计规则（Design Rules）

参考: Codex target spec board (`spec-board-05.html`)

#### 背景色
- **统一 `#F9F9F9` (`AppColors.surface`)**，所有 Tab 页面
- 首页 onboardingBackground (#F7F7F5) → surface
- 广场 white → surface
- 项目列表 gray50 (#F5F5F5) → surface
- `#FFFFFF` 仅用于卡片提升层 (surfaceRaised) 和模态上下文

#### 圆角三级体系
| 级别 | 值 | 用途 |
|------|-----|------|
| 大卡 | `AppRadius.xxl` (24) | SurfaceCard、首页 hero 卡、Profile 信息块 |
| 标准 | `AppRadius.md` (12) | BaseCard、按钮、输入框、列表卡片 |
| 小元素 | `AppRadius.sm` (8) | Tag、badge、pill、小按钮 |

非标值 snap 规则：6→8, 10→12, 14→12, 17→16, 18→20, 22→24, 26→24, 30→24（Market 特色卡除外保留 30）
新增 `AppRadius.xxxl = 30`（Market featured card 专用）

#### 页面水平边距
- **统一 20px (`AppSpacing.lg`)**
- 项目列表从 16 改为 20

#### Section 间距（页面节奏）
| 级别 | 值 | 用途 |
|------|-----|------|
| Hero break | 48 (`AppSpacing.xxxl`) | Hero 区域与内容之间 |
| Major section | 32 (`AppSpacing.xxl`) | 主要区域分隔 |
| Default section | 28 | Section 之间的默认节奏（需新增 token 或用 xxl） |
| Inner rhythm | 12 (`AppSpacing.md`) | 组内元素间距 |
| List item gap | 12 (`AppSpacing.md`) | 列表项之间 |

#### 卡片内边距
| 类型 | 值 | 说明 |
|------|-----|------|
| Base Card | 16 all (`AppSpacing.base`) | 通用卡片 |
| Surface Card | 18,18,18,16 (LTRB) | 主要内容卡片（保持现有） |
| Bottom Action Bar | 20,8,20,8 + safe area | 底部操作栏 |

#### 字体层级（收敛到 AppTextStyles）
| 场景 | Style | 规格 |
|------|-------|------|
| 页面大标题 (header expanded) | `AppTextStyles.h1` | 28/w700 |
| Section 标题 | `AppTextStyles.h3` | 18/w600 |
| 卡片/列表标题 | `AppTextStyles.body1` | 16/w400 或 .copyWith(fontWeight: w600) |
| 正文 | `AppTextStyles.body2` | 14/w400 |
| 辅助信息 | `AppTextStyles.caption` | 12/w400 |
| 标签/meta | `AppTextStyles.overline` | 10/w500 |

非标字号 snap 规则：13→14(body2), 15→14(body2) or 16(body1), 17→18(h3), 22→h2

#### 阴影策略
- **卡片默认无阴影**，靠 tonal layering (#F9F9F9 背景 + #FFFFFF 卡片) 区分层级
- 弱边框: `0.5px outlineVariant` 用于需要边界但不需要阴影的场景
- **阴影仅保留给浮动元素**: FAB、Toast、Dropdown、BottomSheet
- 浮动阴影使用 `AppShadows.shadow2` 或更高

#### No-Line Rule（延续现有规范）
- 列表项之间不用 Divider，靠白空间分隔
- 允许: 输入框 ghost border、contrast 不足时的弱边界
- 禁止: 1px 实线切 section

### Token 补充
- 新增 `AppRadius.xxxl = 30`（Market featured card）
- 新增 `AppColors.badgeRed`、`warningForeground`、`infoForeground`
- 考虑新增 `AppSpacing.section = 28`（default section gap，如果 xxl=32 不够精确）

---

## Implementation Phases

### Phase 1: Shared Infrastructure

**1A. 补充缺失 token**
- File: `lib/app/theme/app_colors.dart`
- 新增: `AppRadius.xxxl = 30`, `AppColors.badgeRed`, `warningForeground`, `infoForeground`

**1B. 创建 VccEditorialAppBar**
- File: `lib/shared/widgets/vcc_editorial_app_bar.dart` (NEW)
- 参考: `VccFlowScaffold` 的 `_VccFlowHeaderDelegate` 模式
- API: `title`, `subtitle`, `compactTitle`, `infoPill`, `trailing`, `slivers`
- 展开 ~140px, 收缩 ~48px, SliverPersistentHeader + progress lerp

**1C. 创建 HomeHeroAppBar**
- File: `lib/features/home/widgets/home_hero_app_bar.dart` (NEW)
- 放在 features/home/ 而非 shared/（遵循 shared/widgets/CLAUDE.md）
- 展开 ~200px, 深色 tonal gradient, 用户名 + 指标
- 收缩 ~48px, 紧凑深色导航栏

### Phase 2: Tab Crossfade 转场

- File: `lib/app/routes.dart`
- 将 5 个 shell route 的 `NoTransitionPage` 替换为 `CustomTransitionPage` + FadeTransition
- 参考: 同文件中 `_onboardingFlowPage` 的 CustomTransitionPage 模式
- Duration: `AppDurations.normal` (200ms), Curve: `Curves.easeInOut`

### Phase 3: 逐页 Token 规范化

每页统一执行：
1. 硬编码 `Color(0xFF...)` → `AppColors.xxx`
2. 非标 `BorderRadius.circular(N)` → `AppRadius.xxx`
3. 字面量 `SizedBox` / `EdgeInsets` → `AppSpacing.xxx`
4. 内联 `TextStyle(fontSize:)` → `AppTextStyles.xxx.copyWith(...)`
5. 集成新 header 组件

**3A. 项目列表页**（最简单，作为 pilot）
- File: `lib/features/project/pages/project_list_page.dart`
- 主要: 替换默认 AppBar → VccEditorialAppBar, 统一 token

**3B. 通知页**
- File: `lib/features/notification/pages/notification_page.dart`
- 主要: 替换 _NotificationHero → VccEditorialAppBar, 清理 ~20 处硬编码值

**3C. 广场页**
- File: `lib/features/market/pages/market_page.dart`
- 注意: 当前是 Column+TabBarView 结构，集成 VccEditorialAppBar 需要改 sliver 布局
- 备选: 如果 sliver 重构代价太大，先只做 token 对齐，header 后续迭代

**3D. 首页**
- File: `lib/features/home/pages/home_page.dart` + home widgets
- 主要: 删除 `_HomeAppBar`, 集成 HomeHeroAppBar, 清理 home 子组件 token

**3E. Profile 页**
- File: `lib/features/profile/pages/profile_page.dart`
- 已有较好的 token 使用，主要是边缘清理（非标圆角 snap、少量内联样式）

### Phase 4: Market 卡片对齐

- File: `lib/features/market/widgets/market_project_card.dart`
- 不强制改为 VccCard（三种布局变体有独立存在理由）
- 只做 token 对齐：圆角→AppRadius, 字体→AppTextStyles, 间距→AppSpacing, 颜色→AppColors

---

## Dependencies

```
1A (tokens) ─┬─→ 1B (EditorialAppBar) ─→ 3A/3B/3C
             ├─→ 1C (HeroAppBar) ─→ 3D
             ├─→ 2 (tab transitions, independent)
             ├─→ 3E (Profile, only needs tokens)
             └─→ 4 (Market card, only needs tokens)
```

## Verification

每个 Phase 完成后：
1. `cd app && flutter analyze` — 零新增 warning
2. 目标文件 grep 硬编码值 — 应为零（或已记录的例外）
3. 模拟器实际滚动测试 header 收缩行为
4. Tab 切换确认 crossfade 动画生效
5. 前后截图对比确认视觉一致性

## 推荐执行顺序

1A → 1B → 2 → 3A (pilot) → 3B → 3C → 1C → 3D → 3E → 4

---

## 不做的事情

- 不改非 Tab 页面（settings、chat、team 等后续推广）
- 不重构 MarketProjectCard 为 VccCard（只做 token 对齐）
- 不新增 dark mode 支持（当前阶段只做 light mode 规范化）
- 不做 Hero 动画（属于 Connected Motion，Phase 2 转场方案，后续迭代）
