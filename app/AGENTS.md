# 开造 VCC — 前端 AI 协作规范

> 适用对象：Claude Code、Codex、Cursor 及一切 AI 编码助手。
> 编写任何 Flutter UI 代码前，必须理解并遵守本文件。

---

## 设计语言：Quiet Craft

**核心调性**：安静、精致、有温度。不用渐变证明高级，用留白和层次说话。
**参考对标**：Notion 的克制 × Luma 的透气 × ChatGPT 的现代感。

---

## 色彩系统（必须使用 AppColors Token）

### 品牌色
| Token | Hex | 用途 |
|-------|-----|------|
| `AppColors.accent` | `#7C3AED` | 选中态、链接文字、小面积强调。**绝不做大面积填充** |
| `AppColors.accentLight` | `#F3EEFF` | 标签底色、图标容器底色 |
| `AppColors.accentMuted` | `#DDD6FE` | 次级紫色背景 |

### 中性色
| Token | Hex | 用途 |
|-------|-----|------|
| `AppColors.gray50` | `#FAFAFA` | 全局画布背景（暖白，不是冷灰）|
| `AppColors.white` | `#FFFFFF` | 卡片、面板、输入框内部 |
| `AppColors.gray100` | `#F5F5F5` | 次级容器背景 |
| `AppColors.gray200` | `#E5E7EB` | 分隔、卡片边框、默认输入框边框 |
| `AppColors.gray400` | `#9CA3AF` | 占位符、时间戳 |
| `AppColors.gray500` | `#6B7280` | 次级正文 |
| `AppColors.gray700` | `#374151` | 主要正文 |
| `AppColors.black` | `#111111` | 标题、主 CTA 按钮背景 |

### 语义色
| Token | Hex | 用途 |
|-------|-----|------|
| `AppColors.success` | `#10B981` | 完成、通过 |
| `AppColors.warning` | `#F59E0B` | 评分、提醒 |
| `AppColors.error` | `#EF4444` | 错误、逾期 |
| `AppColors.info` | `#3B82F6` | AI 内容标注 |
| `AppColors.infoBg` | `#EFF6FF` | AI 生成内容底色 |

### EARS 标签 / 卡片渐变
| Token | 类型 |
|-------|------|
| `AppGradients.earsUbiquitous` | Ubiquitous |
| `AppGradients.earsEvent` | Event |
| `AppGradients.earsState` | State |
| `AppGradients.earsOptional` | Optional |
| `AppGradients.earsUnwanted` | Unwanted |

---

## 排版系统（AppTextStyles）

| Token | Size | Weight | 用途 |
|-------|------|--------|------|
| `AppTextStyles.h1` | 28px / 700 | Bold | 页面大标题 |
| `AppTextStyles.h2` | 22px / 600 | SemiBold | 区块标题 |
| `AppTextStyles.h3` | 18px / 600 | SemiBold | 卡片标题 |
| `AppTextStyles.body1` | 16px / 400 | Regular | 正文 |
| `AppTextStyles.body2` | 14px / 400 | Regular | 次级正文 |
| `AppTextStyles.caption` | 12px / 400 | Regular | 辅助标签 |
| `AppTextStyles.button1` | 16px / 600 | SemiBold | 主按钮文字 |
| `AppTextStyles.tag` | 12px / 400 | Regular | 标签 |
| `AppTextStyles.statusTag` | 12px / 500 | Medium | 状态标签 |


## 间距系统（AppSpacing）

| Token | Value | 用途 |
|-------|-------|------|
| `AppSpacing.xxs` | 2px | 极小间距 |
| `AppSpacing.xs` | 4px | 图标与文字间距 |
| `AppSpacing.sm` | 8px | 内部元素间距 |
| `AppSpacing.md` | 12px | 卡片内间距 |
| `AppSpacing.base` | 16px | 标准间距（最常用）|
| `AppSpacing.lg` | 20px | 区块间距 |
| `AppSpacing.xl` | 24px | 大区块间距 |
| `AppSpacing.xxl` | 32px | 页面级间距 |
| `AppSpacing.xxxl` | 48px | 超大留白 |

## 圆角系统（AppRadius）

| Token | Value | 用途 |
|-------|-------|------|
| `AppRadius.xs` | 4px | 标签、Badge |
| `AppRadius.sm` | 8px | 小按钮、小卡片 |
| `AppRadius.md` | 12px | 标准卡片（最常用）|
| `AppRadius.lg` | 16px | 大卡片、面板 |
| `AppRadius.xl` | 20px | 底部弹层 |
| `AppRadius.xxl` | 24px | 超大容器 |
| `AppRadius.full` | 999px | 圆角胶囊（Tag、Chip）|

> **分类图标容器**：必须用 squircle `AppRadius.md`（12px）。**头像**是唯一允许使用圆形的元素。

---

## 共享组件目录（`lib/shared/widgets/`）

### VccButton
```dart
VccButton(
  text: '发布需求',
  type: VccButtonType.primary,   // primary | secondary | ghost | text | danger | small
  onPressed: () {},
  isLoading: false,
  isFullWidth: true,
  icon: Icons.add,               // 可选
)
```
- `primary`：`#111111` 实底白字，高度 48px，圆角 10px
- `secondary`：白底黑边，高度 48px，圆角 10px
- `ghost`：透明黑边，高度 48px，圆角 10px
- `small`：高度 32px，圆角 8px
- **禁止**：自行用 `Container` + `GestureDetector` 实现按钮，统一用 `VccButton`

### VccInput
```dart
VccInput(
  label: '用户名',
  hint: '请输入用户名',
  controller: _controller,
  focusNode: _focusNode,
  isSearch: false,               // true 时启用搜索样式
  suffixIcon: ...,
  onChanged: (v) {},
)
```
- 常规输入使用主题 `InputDecoration`
- 搜索输入高度 44px，底色 `AppColors.gray50`
- Focus 边框：`AppColors.black` 1.5px
- 错误边框：`AppColors.error`

### VccCard
```dart
VccCard(
  child: ...,
  padding: const EdgeInsets.all(16),
  borderRadius: 12,
  backgroundColor: AppColors.white,
  onTap: () {},
)
```
- 默认白底 + `AppColors.gray200` 1px 边框 + 12px 圆角
- 仅在品牌主视觉、启动页、明确设计稿场景下允许 `gradient`

### VccTag
小标签组件，用于技能标签、项目类型标签。

### VccAvatar
用户头像，**唯一允许圆形**的组件。

### VccToast
轻提示，不要用系统 SnackBar。

### VccEmptyState
空状态占位组件，禁止自行绘制空状态。

### VccLoading
加载状态组件。

### VccBottomNav
底部导航栏，5 个 Tab：首页 / 广场 / 消息 / 项目 / 我的。

---

## 动效规范（AppDurations / AppCurves）

| 场景 | 时长 | 曲线 |
|------|------|------|
| 按钮 press 缩放 | 120ms | linear |
| 微交互（颜色切换）| `AppDurations.fast` 150ms | `AppCurves.easeOut` |
| 页面元素进场 | `AppDurations.normal` 200ms | `AppCurves.standard` |
| 面板滑入 / 模态 | `AppDurations.slow` 300ms | `AppCurves.standard` |
| Logo 弹簧入场 | 800ms | `Curves.elasticOut` |

- **标准曲线** `AppCurves.standard`：`Cubic(0.16, 1, 0.3, 1)`（类 iOS spring feel）
- **禁止**：`Curves.bounceOut`、`Curves.elasticIn`（除 Logo 外）
- **按钮按压动效**：scale `1.0 → 0.96`，120ms，释放回弹

---

## EARS 标签系统

当前共享组件里的 EARS 相关样式以 `VccStatusTag` 为准。

| 类型 | 全称 | 颜色 | 含义 |
|------|------|------|------|
| `ubiquitous` | Ubiquitous | 紫色渐变 | 默认 EARS 标签 |
| `event` | Event | 蓝色渐变 | 行为 / 事件 |
| `state` | State | 橙色渐变 | 状态 |
| `optional` | Optional | 绿色渐变 | 可选项 |
| `unwanted` | Unwanted | 红色渐变 | 不期望项 |

规则：
- 标签类型通过 `VccStatusTag(type: VccTagType.ears, earsType: ...)` 驱动
- 不要在业务代码里重新定义 EARS 颜色名
- 新的 EARS 类型要先补到 `AppGradients` / `VccStatusTag`

---

## 严禁事项

| 禁止 | 正确做法 |
|------|----------|
| ❌ 无依据的渐变（LinearGradient / RadialGradient）| ✅ 纯色填充；品牌主视觉和 EARS 标签按设计稿使用既有渐变 |
| ❌ 圆形图标容器（`BorderRadius.circular(999)` 包图标）| ✅ squircle `AppRadius.md` |
| ❌ 重阴影（`blurRadius > 16` 或 `spreadRadius > 0`）| ✅ 轻阴影 `shadow1`/`shadow2` |
| ❌ 1px 分隔线作为布局分隔 | ✅ 用间距 + 背景色层次区分 |
| ❌ 纯黑 `#000000` | ✅ `AppColors.black` = `#111111` |
| ❌ 冷灰背景 `#F0F0F0` | ✅ 暖白 `AppColors.gray50` = `#FAFAFA` |
| ❌ 直接写 hex 颜色字符串 | ✅ 必须用 `AppColors.*` token |
| ❌ 直接写字号数字 | ✅ 必须用 `AppTextStyles.*` |
| ❌ 自定义按钮容器 | ✅ 使用 `VccButton` |
| ❌ 系统 SnackBar | ✅ 使用 `VccToast` |
| ❌ `withOpacity(x)` | ✅ `withValues(alpha: x)` |

---

## 项目结构速查

```
app/lib/
├── app/
│   ├── routes.dart          # GoRouter，redirect 逻辑在这里
│   └── theme/
│       ├── app_colors.dart  # AppColors + AppShadows + AppSpacing + AppRadius + AppDurations
│       └── app_text_styles.dart  # AppTextStyles
├── core/
│   └── storage/storage_service.dart
├── features/
│   ├── auth/                # splash / onboarding / login / role_select
│   ├── home/                # 首页（发起人视角）
│   ├── market/              # 需求广场
│   ├── match/               # 匹配 / 投标
│   ├── chat/                # 消息
│   ├── project/             # 项目详情
│   ├── profile/             # 个人主页
│   └── payment/             # 支付
└── shared/
    ├── widgets/             # Vcc* 共享组件
    └── models/              # 共享数据模型
```

## 状态管理

- 使用 **Riverpod**（`flutter_riverpod`）
- 路由使用 **GoRouter**，`RoutePaths` 常量在 `app/routes.dart`
- Auth 状态：`authStateProvider`（`AuthNotifier extends StateNotifier<AuthState>`）
- GoRouter 通过 `refreshListenable` 监听 `authChangeNotifierProvider`

## 术语表（禁止使用错误称呼）

| 正确 | 禁止 |
|------|------|
| 造物者 | 程序员、码农、开发者 |
| 发起人 | 甲方、客户、用户 |
| 接造 | 接单 |
| EARS 卡片 | 需求卡片、任务卡 |
| 开造 / VCC | 外包平台 |
