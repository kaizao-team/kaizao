# 开造 VCC — 前端 AI 协作规范

> 适用对象：Claude Code、Codex、Cursor 及一切 AI 编码助手。
> 编写任何 Flutter UI 代码前，必须理解并遵守本文件。

---

## 总原则

主规范不是品牌展示页思路，而是 **Architectural Minimalism / The Digital Atheneum**。

核心要求：
- 单色为主，靠层级、排版、留白做区分，不靠彩色强调
- 结构像高端杂志和建筑导视，安静、克制、权威
- UI 是内容容器，不是视觉主角
- 优先非对称构图、长留白、分层背景
- 默认不要渐变、不要重阴影、不要线框分割

---

## 颜色与层级

### Foundation
| 角色 | 色值 | 说明 |
|------|------|------|
| `surface` | `#F9F9F9` | 主画布 |
| `on_surface` | `#1A1C1C` | 主文本 |
| `primary` | `#000000` | 主操作 |
| `outline_variant` | `#C6C6C6` at 20% | Ghost Border / 极弱结构边界 |

### Surface Hierarchy
| 层级 | 色值 | 用途 |
|------|------|------|
| Level 0 | `#F9F9F9` | 页面底 |
| Level 1 | `#F3F3F3` | 子区块、侧栏、hover 分层 |
| Level 2 | `#FFFFFF` | 卡片、输入框、浮层内容面 |
| Level 3 | `#E8E8E8` | 次级按钮、高显著度容器 |

### 规则
- 禁止紫色、蓝色等彩色作为大面积背景或主层级色
- 默认不要靠边框分区，优先用背景层级切换
- 文本不要用纯黑，正文统一靠近 `#1A1C1C`
- CTA 默认黑底，不做品牌彩色按钮
- 默认禁止普通渐变，只有下方这条 tonal shift 例外

### 唯一允许的“纹理”
- Hero 或主 CTA 可使用极轻的 tonal shift
- 只允许：`#000000 -> #3C3B3B`
- 目的不是做“渐变感”，而是做柔和、天鹅绒式的体积感

---

## No-Line Rule

硬性规则：
- 不允许用标准 1px 实线做区块分隔
- 不允许用 `Divider()` 作为主要层次手段
- 分隔必须优先通过背景色层级变化完成

可用例外：
- 输入框默认态的 Ghost Border
- 浮层在对比不足时使用 1px `outline_variant`，透明度 15%
- Focus 态 1.5px 黑色边框

---

## 排版

目标气质：
- 标题像杂志刊名
- 元数据像建筑蓝图标注
- 正文不抢戏，强调阅读稳定性

### Typeface Strategy
- Display / Headlines：**Plus Jakarta Sans**
- Body / Labels：**Inter**

### Hierarchy
- 大标题优先拉大级差，不要一路平均排下去
- 允许 `display` 搭 `body-sm`，跳过中间层级
- metadata 用全大写、小字号、加字距

### 文本规则
- 不要把所有标题都做成 18/20/22 的均匀梯度
- 不要让说明文和标题挤在一起
- 不要用彩色文本制造“层次”

---

## 间距

主规范强调大留白，不是密排。

规则：
- 大区块之间优先使用“明显更大”的留白
- 重要模块之间要敢用 48px 以上的间距
- 列表项之间不要插分隔线，用垂直白空间隔开
- 页面不要“中间一坨”

---

## 深度

默认不用传统阴影塑形，优先 **Tonal Layering**。

规则：
- Level 2 白卡放在 Level 1 灰底上，就已经形成自然抬升
- 常规卡片不加重阴影
- 真正浮动的元素允许极弱 ambient shadow

### Ambient Shadow
- Blur：24px - 40px
- Opacity：4% - 6%
- Color：从 `#1A1C1C` 派生

---

## 组件规则

### Buttons
- `Primary`：黑底浅字，圆角偏大但克制
- `Secondary`：`#E8E8E8` 背景
- `Tertiary`：无底，hover 时才出现 Ghost Border

禁止：
- 紫色主按钮
- 渐变按钮
- 发光按钮

### Cards & Lists
- 禁止使用 divider 切列表
- 通过垂直留白和背景变化区分
- hover 优先用 `surface_container_low`

### Input Fields
- 默认背景：白色
- 默认边界：1px Ghost Border
- Focus：1.5px 黑色边框
- 不要 glow

### Avatars
- 圆形是唯一允许的圆形 UI 元素

### Breadcrumbs
- 推荐用小号全大写文本 + `/` 分隔
- 这是系统签名组件之一

---

## 共享组件

优先使用：
- `VccButton`
- `VccInput`
- `VccCard`
- `VccTag`
- `VccAvatar`
- `VccToast`
- `VccEmptyState`
- `VccLoading`
- `VccBottomNav`

补充要求：
- 共享组件如果不符合本规范，要先修组件，再复用
- 不要为了复用而保留错误视觉

---

## 严禁事项

| 禁止 | 正确做法 |
|------|----------|
| ❌ 紫色/蓝色大面积铺底 | ✅ 单色层级 + 黑白灰结构 |
| ❌ 彩色渐变 Hero | ✅ 单色主视觉，必要时只用 `#000000 -> #3C3B3B` |
| ❌ divider / 实线切区块 | ✅ 背景层级切换 |
| ❌ 重阴影 / 发光 / 科技蓝 | ✅ Tonal Layering |
| ❌ 所有内容居中堆叠 | ✅ 非对称构图 + 留白 |
| ❌ 圆形图标容器 | ✅ 8px-12px 圆角方形 |
| ❌ 纯黑正文 | ✅ `#1A1C1C` |
| ❌ 平均字号梯度 | ✅ 拉大层级差 |

---

## 项目结构速查

```text
app/lib/
├── app/
│   ├── routes.dart
│   └── theme/
│       ├── app_colors.dart
│       └── app_text_styles.dart
├── core/
│   └── storage/storage_service.dart
├── features/
│   ├── auth/
│   ├── home/
│   ├── market/
│   ├── match/
│   ├── chat/
│   ├── project/
│   ├── profile/
│   └── payment/
└── shared/
    ├── widgets/
    └── models/
```

## 状态管理

- 使用 **Riverpod**
- 路由使用 **GoRouter**
- Auth 状态入口：`authStateProvider`
- GoRouter 刷新监听：`authChangeNotifierProvider`

---

## 术语

| 正确 | 禁止 |
|------|------|
| 造物者 | 程序员、码农、开发者 |
| 发起人 | 甲方、客户、用户 |
| 开造 / VCC | 外包平台 |
