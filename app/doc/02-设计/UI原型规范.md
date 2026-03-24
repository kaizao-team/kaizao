# 开造 (VCC) — UI 原型规范

> 文档版本：v1.0
> 设计团队：UI Designer + UX Architect
> 日期：2026-03-22
> 状态：初稿
> 适用技术栈：Flutter (Dart)
> 设计基准屏幕：375 x 812 px (iPhone 13/14)

---

## 1. 设计系统基础

### 1.1 颜色系统

#### 1.1.1 品牌主色（渐变色系）

| Token | HEX | Flutter Color | 说明 |
|-------|-----|---------------|------|
| `brand-purple` | `#7C3AED` | `Color(0xFF7C3AED)` | 星辉紫，渐变起点 |
| `brand-indigo` | `#6366F1` | `Color(0xFF6366F1)` | 深邃靛，渐变中段 |
| `brand-blue` | `#3B82F6` | `Color(0xFF3B82F6)` | 天际蓝，渐变终点 |
| `brand-dark-purple` | `#5B21B6` | `Color(0xFF5B21B6)` | 暗夜紫，深色变体/按下态 |

**主渐变定义（Flutter）**：

```dart
// 渐变组A：星河紫蓝（主力渐变）
static const gradientPrimary = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF7C3AED), Color(0xFF6366F1), Color(0xFF3B82F6)],
  stops: [0.0, 0.5, 1.0],
);

// 渐变组B：极光流转（运营/辅助场景）
static const gradientAurora = LinearGradient(
  begin: Alignment(-0.5, -1),
  end: Alignment(0.5, 1),
  colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
);

// 渐变组C：深空沉浸（启动页/深色场景）
static const gradientDeepSpace = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF5B21B6), Color(0xFF3730A3), Color(0xFF1E3A5F)],
  stops: [0.0, 0.5, 1.0],
);

// 按钮按下态渐变
static const gradientPrimaryPressed = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF6D28D9), Color(0xFF2563EB)],
);

// 深色模式主渐变（提亮12%）
static const gradientPrimaryDark = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF8B5CF6), Color(0xFF818CF8), Color(0xFF60A5FA)],
  stops: [0.0, 0.5, 1.0],
);
```

#### 1.1.2 辅助色

| Token | HEX | Flutter Color | 说明 |
|-------|-----|---------------|------|
| `accent-cyan` | `#06B6D4` | `Color(0xFF06B6D4)` | 极光青，数据可视化/标签 |
| `accent-gold` | `#F59E0B` | `Color(0xFFF59E0B)` | 星芒金，等级/成就/评分 |

#### 1.1.3 语义色

| Token | HEX | Flutter Color | 背景色 HEX | 背景色 Flutter | 说明 |
|-------|-----|---------------|-----------|----------------|------|
| `success` | `#10B981` | `Color(0xFF10B981)` | `#ECFDF5` | `Color(0xFFECFDF5)` | 成功/通过/在线 |
| `warning` | `#F59E0B` | `Color(0xFFF59E0B)` | `#FFFBEB` | `Color(0xFFFFFBEB)` | 警告/待处理 |
| `error` | `#EF4444` | `Color(0xFFEF4444)` | `#FEF2F2` | `Color(0xFFFEF2F2)` | 错误/失败 |
| `info` | `#3B82F6` | `Color(0xFF3B82F6)` | `#EFF6FF` | `Color(0xFFEFF6FF)` | 信息/引导 |

#### 1.1.4 中性色阶

| Token | HEX | Flutter Color | 典型用途 |
|-------|-----|---------------|---------|
| `gray-50` | `#F8FAFC` | `Color(0xFFF8FAFC)` | 页面底色 |
| `gray-100` | `#F1F5F9` | `Color(0xFFF1F5F9)` | 输入框背景/骨架屏 |
| `gray-200` | `#E2E8F0` | `Color(0xFFE2E8F0)` | 分割线/边框 |
| `gray-300` | `#CBD5E1` | `Color(0xFFCBD5E1)` | 禁用态边框 |
| `gray-400` | `#94A3B8` | `Color(0xFF94A3B8)` | 占位文字/次要图标 |
| `gray-500` | `#64748B` | `Color(0xFF64748B)` | 次要文字/辅助说明 |
| `gray-600` | `#475569` | `Color(0xFF475569)` | 副标题 |
| `gray-700` | `#334155` | `Color(0xFF334155)` | 正文文字（浅色模式） |
| `gray-800` | `#1E293B` | `Color(0xFF1E293B)` | 标题文字（浅色模式） |
| `gray-900` | `#0F172A` | `Color(0xFF0F172A)` | 极深灰/深色模式背景 |

#### 1.1.5 EARS 卡片类型色

| EARS 类型 | 渐变起点 | 渐变终点 | 标签文字 |
|-----------|---------|---------|---------|
| Ubiquitous（始终） | `#7C5CFC` | `#6C5CE7` | 白色 |
| Event（事件） | `#0A7AFF` | `#4A6CF7` | 白色 |
| State（状态） | `#FF9500` | `#F7B731` | 白色 |
| Optional（可选） | `#34C759` | `#7BED9F` | 白色 |
| Unwanted（异常） | `#FF3B30` | `#FC5C65` | 白色 |

#### 1.1.6 项目状态色

| 状态 | HEX | Flutter Color | 图标 |
|------|-----|---------------|------|
| 已完成 | `#10B981` | `Color(0xFF10B981)` | 实心圆 |
| 进行中 | `#3B82F6` | `Color(0xFF3B82F6)` | 实心圆 |
| 待开始 | `#CBD5E1` | `Color(0xFFCBD5E1)` | 空心圆 |
| 有风险 | `#EF4444` | `Color(0xFFEF4444)` | 实心圆+脉冲动画 |
| 已逾期 | `#EF4444` | `Color(0xFFEF4444)` | 实心三角 |

---

### 1.2 字体系统

#### 字体栈

```dart
// Flutter 字体定义
static const String fontFamilyPrimary = 'PingFang SC'; // iOS
static const String fontFamilyAndroid = 'Noto Sans SC'; // Android
static const String fontFamilyMono = 'JetBrains Mono'; // 代码

// 在 ThemeData 中设置
ThemeData(
  fontFamily: Platform.isIOS ? 'PingFang SC' : 'Noto Sans SC',
)
```

#### 字号阶梯与 TextStyle 定义

```dart
class AppTextStyles {
  // H1 大标题
  static const h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700, // Bold
    height: 1.21, // lineHeight = 34px / 28px
    letterSpacing: -0.5,
    color: Color(0xFF1E293B),
  );

  // H2 章节标题
  static const h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600, // SemiBold
    height: 1.27, // lineHeight = 28px / 22px
    letterSpacing: -0.3,
    color: Color(0xFF1E293B),
  );

  // H3 小节标题
  static const h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600, // SemiBold
    height: 1.33, // lineHeight = 24px / 18px
    color: Color(0xFF1E293B),
  );

  // Body1 正文
  static const body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    height: 1.5, // lineHeight = 24px / 16px
    color: Color(0xFF334155),
  );

  // Body2 辅助正文
  static const body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    height: 1.43, // lineHeight = 20px / 14px
    color: Color(0xFF64748B),
  );

  // Caption 注释
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400, // Regular
    height: 1.33, // lineHeight = 16px / 12px
    color: Color(0xFF94A3B8),
  );

  // Overline 极小标注
  static const overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500, // Medium
    height: 1.4, // lineHeight = 14px / 10px
    letterSpacing: 0.5,
    color: Color(0xFF94A3B8),
  );

  // Num1 大数字
  static const num1 = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700, // Bold
    height: 1.17, // lineHeight = 42px / 36px
    color: Color(0xFF1E293B),
  );

  // Num2 中数字
  static const num2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600, // SemiBold
    height: 1.25, // lineHeight = 30px / 24px
    color: Color(0xFF1E293B),
  );

  // Num3 小数字
  static const num3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500, // Medium
    height: 1.38, // lineHeight = 22px / 16px
    color: Color(0xFF1E293B),
  );

  // Button1 按钮文字
  static const button1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600, // SemiBold
    height: 1.38, // lineHeight = 22px / 16px
    color: Colors.white,
  );

  // Button2 小按钮文字
  static const button2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500, // Medium
    height: 1.43, // lineHeight = 20px / 14px
    color: Color(0xFF7C3AED),
  );
}
```

#### 字号阶梯速查表

| 层级 | 字号 | 字重 | 行高(px) | Flutter height | 使用场景 |
|------|------|------|---------|----------------|---------|
| H1 | 28px | Bold (w700) | 34px | 1.21 | 页面主标题 |
| H2 | 22px | SemiBold (w600) | 28px | 1.27 | 分区标题 |
| H3 | 18px | SemiBold (w600) | 24px | 1.33 | 卡片标题、模块名 |
| Body1 | 16px | Regular (w400) | 24px | 1.5 | 正文内容、列表项 |
| Body2 | 14px | Regular (w400) | 20px | 1.43 | 辅助说明、描述 |
| Caption | 12px | Regular (w400) | 16px | 1.33 | 时间戳、标签 |
| Overline | 10px | Medium (w500) | 14px | 1.4 | 极小标注 |
| Num1 | 36px | Bold (w700) | 42px | 1.17 | 核心数据 |
| Num2 | 24px | SemiBold (w600) | 30px | 1.25 | 卡片数据 |
| Num3 | 16px | Medium (w500) | 22px | 1.38 | 列表内数字 |
| Button1 | 16px | SemiBold (w600) | 22px | 1.38 | 主按钮 |
| Button2 | 14px | Medium (w500) | 20px | 1.43 | 次按钮/链接 |

---

### 1.3 间距系统

基础网格单位：**4px**

| Token | 值 | Flutter | 使用场景 |
|-------|-----|---------|---------|
| `space-2xs` | 2px | `2.0` | 极小微调间距 |
| `space-xs` | 4px | `4.0` | 图标与文字间距、极小元素间距 |
| `space-sm` | 8px | `8.0` | 行内元素间距、标签间距 |
| `space-md` | 12px | `12.0` | 表单元素间距、列表项间距、卡片间距（垂直） |
| `space-base` | 16px | `16.0` | 基础间距：卡片内边距、页面水平边距 |
| `space-lg` | 20px | `20.0` | 分区间距 |
| `space-xl` | 24px | `24.0` | 板块间距、分区标题上间距 |
| `space-2xl` | 32px | `32.0` | 大区域分隔 |
| `space-3xl` | 48px | `48.0` | 页面级分区 |

```dart
class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}
```

#### 页面布局间距

| 维度 | 值 | 说明 |
|------|-----|------|
| 页面水平边距 | 16px | 左右各 16px |
| 卡片内边距 | 16px | 四周各 16px |
| 卡片间距（垂直） | 12px | 卡片之间 |
| 分区标题上间距 | 24px | 分区标题距上方内容 |
| 分区标题下间距 | 12px | 分区标题距下方内容 |
| 顶部导航栏高度 | 44px | 不含状态栏 |
| 底部 TabBar 高度 | 56px | 不含安全区 |
| 安全区域-顶部 | ~47px | 刘海屏状态栏 |
| 安全区域-底部 | ~34px | Home Indicator |

---

### 1.4 圆角规范

| Token | 值 | Flutter | 使用场景 |
|-------|-----|---------|---------|
| `radius-xs` | 4px | `BorderRadius.circular(4)` | 标签/Chip/徽章 |
| `radius-sm` | 8px | `BorderRadius.circular(8)` | 输入框、小按钮、Toast |
| `radius-md` | 12px | `BorderRadius.circular(12)` | 通用卡片、主按钮、EARS卡片 |
| `radius-lg` | 16px | `BorderRadius.circular(16)` | 大卡片、毛玻璃卡片、图片容器 |
| `radius-xl` | 20px | `BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))` | 底部弹窗（顶部圆角） |
| `radius-2xl` | 24px | `BorderRadius.circular(24)` | 全屏Modal顶部 |
| `radius-full` | 999px | `BorderRadius.circular(999)` | 头像、圆形按钮、进度条、胶囊标签 |

#### 圆角使用场景速查

| 组件 | 圆角值 |
|------|-------|
| 主按钮 (CTA) | 12px |
| 次要按钮 | 12px |
| 小按钮 | 8px |
| 输入框 | 8px |
| 通用卡片 | 16px |
| EARS 卡片 | 12px |
| 模块节点（概览图） | 12px |
| 用户头像 | 999px（圆形） |
| 团队头像 | 8px |
| 底部弹窗 | 20px（顶部两角） |
| 标签/徽章 | 4px |
| 进度条 | 999px（胶囊） |
| Toast/Snackbar | 8px |
| 搜索框 | 999px（胶囊） |

---

### 1.5 阴影系统

```dart
class AppShadows {
  // Level 1 - 微阴影：输入框、小标签
  static final shadow1 = [
    BoxShadow(
      color: Color(0x0F000000), // rgba(0,0,0,0.06)
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: Color(0x0A000000), // rgba(0,0,0,0.04)
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  // Level 2 - 轻阴影：通用卡片、列表卡片
  static final shadow2 = [
    BoxShadow(
      color: Color(0x14000000), // rgba(0,0,0,0.08)
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
    BoxShadow(
      color: Color(0x0A000000), // rgba(0,0,0,0.04)
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  // Level 3 - 中阴影：悬浮按钮、弹窗、展开态卡片
  static final shadow3 = [
    BoxShadow(
      color: Color(0x1F000000), // rgba(0,0,0,0.12)
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
    BoxShadow(
      color: Color(0x0F000000), // rgba(0,0,0,0.06)
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
  ];

  // Level 4 - 重阴影：全屏Modal
  static final shadow4 = [
    BoxShadow(
      color: Color(0x29000000), // rgba(0,0,0,0.16)
      offset: Offset(0, 16),
      blurRadius: 48,
    ),
    BoxShadow(
      color: Color(0x14000000), // rgba(0,0,0,0.08)
      offset: Offset(0, 8),
      blurRadius: 16,
    ),
  ];

  // 品牌色阴影：主按钮、品牌卡片
  static final brandShadow = [
    BoxShadow(
      color: Color(0x597C3AED), // rgba(124,58,237,0.35)
      offset: Offset(0, 4),
      blurRadius: 15,
    ),
  ];

  // 品牌色阴影-按下态
  static final brandShadowPressed = [
    BoxShadow(
      color: Color(0x4D7C3AED), // rgba(124,58,237,0.30)
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  // 品牌色阴影-悬浮态（加强）
  static final brandShadowHover = [
    BoxShadow(
      color: Color(0x807C3AED), // rgba(124,58,237,0.50)
      offset: Offset(0, 6),
      blurRadius: 20,
    ),
  ];
}
```

---

### 1.6 图标规范

| 属性 | 规范 |
|------|------|
| 风格 | 圆润线性（Round Cap, Round Join） |
| 线宽 | 1.5px，小尺寸(16px及以下)调整为 2px |
| 基础网格 | 24x24px |
| 安全区域 | 四周各留 2px（实际绘制区域 20x20px） |
| 推荐图标库 | Phosphor Icons / Remix Icon |

#### 图标尺寸规范

| 场景 | 尺寸 | Flutter IconSize |
|------|------|-----------------|
| 底部 TabBar 图标 | 24x24px | `24.0` |
| 列表项前置图标 | 20x20px | `20.0` |
| 标签/标注图标 | 16x16px | `16.0` |
| 角标/徽章图标 | 12x12px | `12.0` |
| 页面大图标（空状态等） | 48x48px | `48.0` |
| AppBar 操作图标 | 24x24px | `24.0` |

#### 图标颜色状态

| 状态 | 浅色模式 | 深色模式 |
|------|---------|---------|
| 默认 | `#475569` (gray-600) | `#E2E8F0` (gray-200) |
| 选中/激活 | 品牌渐变 `#7C3AED -> #3B82F6` | `#8B5CF6 -> #60A5FA` |
| 禁用 | `#CBD5E1` (gray-300) | `#475569` (gray-600) |
| 语义-成功 | `#10B981` | `#34D399` |
| 语义-错误 | `#EF4444` | `#F87171` |

---

## 2. 高保真组件库

### 2.1 按钮组件

#### 2.1.1 主按钮 (Primary Button)

| 属性 | 正常态 | 按压态 | 禁用态 | 加载态 |
|------|-------|--------|--------|--------|
| 高度 | 48px | 48px | 48px | 48px |
| 宽度 | `double.infinity`（通栏）或自适应最小 120px | 同左 | 同左 | 同左 |
| 圆角 | 12px | 12px | 12px | 12px |
| 背景 | 渐变 `#7C3AED -> #3B82F6` | 渐变 `#6D28D9 -> #2563EB` | `#E2E8F0` | 渐变 `#7C3AED -> #3B82F6` |
| 文字颜色 | `#FFFFFF` | `#FFFFFF` | `#94A3B8` | `#FFFFFF`（隐藏文字） |
| 字号/字重 | 16px / SemiBold (w600) | 16px / SemiBold | 16px / SemiBold | -- |
| 阴影 | `brandShadow` | `brandShadowPressed` | none | `brandShadow` |
| 内边距 | 水平 24px，垂直 13px | 同左 | 同左 | 同左 |
| 加载指示器 | -- | -- | -- | 白色 CircularProgressIndicator 20x20px，lineWidth 2px |

```dart
// 主按钮 Flutter 实现
Container(
  height: 48,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
    ),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Color(0xFF7C3AED).withOpacity(0.35),
        offset: Offset(0, 4),
        blurRadius: 15,
      ),
    ],
  ),
  child: Center(
    child: Text('发布需求', style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: 1.38,
    )),
  ),
)
```

#### 2.1.2 次要按钮 (Secondary Button)

| 属性 | 正常态 | 按压态 | 禁用态 |
|------|-------|--------|--------|
| 高度 | 48px | 48px | 48px |
| 圆角 | 12px | 12px | 12px |
| 背景 | `#FFFFFF` | `#F8F7FF` | `#F8FAFC` |
| 边框 | 1px solid `#7C3AED` | 1px solid `#6D28D9` | 1px solid `#E2E8F0` |
| 文字颜色 | `#7C3AED` | `#6D28D9` | `#94A3B8` |
| 字号/字重 | 16px / Medium (w500) | 16px / Medium | 16px / Medium |
| 阴影 | none | none | none |
| 内边距 | 水平 24px，垂直 13px | 同左 | 同左 |

#### 2.1.3 幽灵按钮 (Ghost Button)

| 属性 | 正常态 | 按压态 | 禁用态 |
|------|-------|--------|--------|
| 高度 | 48px | 48px | 48px |
| 圆角 | 12px | 12px | 12px |
| 背景 | 透明 | `Color(0xFF7C3AED).withOpacity(0.06)` | 透明 |
| 边框 | 1px solid `#7C3AED` | 1px solid `#6D28D9` | 1px solid `#E2E8F0` |
| 文字颜色 | `#7C3AED` | `#6D28D9` | `#CBD5E1` |
| 字号/字重 | 14px / Medium (w500) | 14px / Medium | 14px / Medium |

#### 2.1.4 文字按钮 (Text Button)

| 属性 | 正常态 | 按压态 | 禁用态 |
|------|-------|--------|--------|
| 高度 | 自适应 | 自适应 | 自适应 |
| 背景 | 透明 | 透明 | 透明 |
| 边框 | none | none | none |
| 文字颜色 | `#7C3AED` | `#5B21B6` | `#CBD5E1` |
| 字号/字重 | 14px / Medium (w500) | 14px / Medium | 14px / Medium |
| 下划线 | 无 | 有 | 无 |

#### 2.1.5 小按钮 (Small Button)

| 属性 | 值 |
|------|-----|
| 高度 | 32px |
| 圆角 | 8px |
| 字号/字重 | 14px / Medium (w500) |
| 内边距 | 水平 12px，垂直 6px |
| 其余状态 | 同主/次/幽灵按钮对应变体 |

#### 2.1.6 图标按钮 (Icon Button)

| 属性 | 值 |
|------|-----|
| 触控区域 | 44x44px |
| 图标尺寸 | 24x24px |
| 圆角 | 999px（圆形） |
| 正常背景 | 透明 |
| 按压背景 | `Color(0xFF7C3AED).withOpacity(0.08)` |
| 图标颜色 | `#475569`（默认），`#7C3AED`（激活） |

#### 2.1.7 危险按钮 (Danger Button)

| 属性 | 正常态 | 按压态 |
|------|-------|--------|
| 背景 | `#EF4444` | `#DC2626` |
| 文字 | `#FFFFFF` | `#FFFFFF` |
| 其余属性 | 同主按钮 | 同主按钮 |

---

### 2.2 输入框组件

#### 2.2.1 单行文本输入框

| 属性 | 默认态 | 聚焦态 | 错误态 | 禁用态 |
|------|-------|--------|--------|--------|
| 高度 | 48px | 48px | 48px | 48px |
| 圆角 | 8px | 8px | 8px | 8px |
| 背景 | `#F1F5F9` | `#FFFFFF` | `#FFFFFF` | `#F1F5F9` |
| 边框 | 1px solid `#E2E8F0` | 2px solid `#7C3AED` | 2px solid `#EF4444` | 1px solid `#E2E8F0` |
| 内边距 | 左右 16px | 左右 16px | 左右 16px | 左右 16px |
| 占位文字颜色 | `#94A3B8` | `#94A3B8` | `#94A3B8` | `#CBD5E1` |
| 输入文字颜色 | `#1E293B` | `#1E293B` | `#1E293B` | `#94A3B8` |
| 字号 | 16px / Regular | 16px / Regular | 16px / Regular | 16px / Regular |
| 标签（上方） | 14px / Medium, `#334155` | 14px / Medium, `#7C3AED` | 14px / Medium, `#EF4444` | 14px / Medium, `#CBD5E1` |
| 错误提示（下方） | -- | -- | 12px / Regular, `#EF4444`, 上间距 4px | -- |
| 前缀图标 | 20x20px, `#94A3B8` | 20x20px, `#7C3AED` | 20x20px, `#EF4444` | 20x20px, `#CBD5E1` |

```dart
// 输入框 Flutter 实现
TextField(
  decoration: InputDecoration(
    filled: true,
    fillColor: Color(0xFFF1F5F9),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Color(0xFF7C3AED), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Color(0xFFEF4444), width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
  ),
  style: TextStyle(fontSize: 16, color: Color(0xFF1E293B)),
)
```

#### 2.2.2 搜索输入框

| 属性 | 值 |
|------|-----|
| 高度 | 44px |
| 圆角 | 999px（胶囊） |
| 背景 | `#F1F5F9` |
| 边框 | none |
| 前缀图标 | 搜索图标 20x20px, `#94A3B8`, 距左 16px |
| 后缀 | 清除按钮（有输入内容时），20x20px |
| 内边距 | 左 44px（图标+间距），右 16px |
| 占位文字 | 16px / Regular, `#94A3B8` |

#### 2.2.3 多行文本输入框

| 属性 | 值 |
|------|-----|
| 最小高度 | 120px |
| 最大高度 | 240px（可滚动） |
| 圆角 | 8px |
| 内边距 | 上下左右各 16px |
| 字数统计 | 右下角显示，12px / Regular, `#94A3B8` |
| 其余属性 | 同单行输入框 |

---

### 2.3 卡片组件

#### 2.3.1 项目卡片（需求列表/推荐列表）

| 属性 | 值 |
|------|-----|
| 宽度 | `double.infinity`（通栏，减去页面边距 16px*2 = 343px） |
| 最小高度 | 自适应内容 |
| 圆角 | 16px |
| 背景 | `#FFFFFF` |
| 边框 | 0.5px solid `rgba(0,0,0,0.06)` |
| 阴影 | `shadow2`（Level 2） |
| 内边距 | 16px |

**内部布局**：
```
┌────────────────────────────────────────────┐
│ [匹配度标签 95%]               [金额 ¥3000] │  ← 顶部行，高度 20px
│ 标题文字（H3, 18px/w600）                    │  ← 间距 8px
│ 描述文字（Body2, 14px, 最多2行，超出省略）    │  ← 间距 4px
│                                             │  ← 间距 12px
│ [标签1] [标签2] [标签3]                      │  ← 标签行，间距 8px
│                                             │  ← 间距 12px
│ [AI建议提示条]（可选，背景 #EFF6FF）          │  ← 间距 12px
│ 需要：全栈开发 · 预计7天                      │  ← 底部信息行 Caption
└────────────────────────────────────────────┘
```

- 匹配度标签：背景渐变 `#7C3AED -> #3B82F6`, 文字白色 12px/w500, 圆角 4px, 内边距 4px 8px
- 金额文字：18px / SemiBold, `#1E293B`
- AI 建议提示条：背景 `#EFF6FF`, 圆角 8px, 内边距 8px 12px, 文字 12px/Regular `#3B82F6`

#### 2.3.2 用户卡片（推荐供给方）

| 属性 | 值 |
|------|-----|
| 宽度 | 140px |
| 高度 | 自适应 |
| 圆角 | 16px |
| 背景 | `#FFFFFF` |
| 阴影 | `shadow2` |
| 内边距 | 12px |

**内部布局**：
```
┌──────────────┐
│   [头像 48px] │  ← 居中
│    昵称       │  ← 14px/w600, 居中, 间距 8px
│    ⭐ 4.9    │  ← 12px/Regular, 间距 4px
│  [技能标签]   │  ← 12px/Regular, 居中, 间距 8px
└──────────────┘
```

#### 2.3.3 技能标签卡片/Chip

见 2.7 Tag/Chip 组件。

#### 2.3.4 EARS 任务卡片（折叠态）

| 属性 | 值 |
|------|-----|
| 宽度 | `double.infinity`（343px） |
| 圆角 | 12px |
| 背景 | `#FFFFFF`（普通灰色背景上）/ `rgba(255,255,255,0.60)` + `blur(24px)`（渐变背景上） |
| 左边框 | 3px solid [EARS类型色] |
| 整体边框 | 0.5px solid `rgba(255,255,255,0.18)` |
| 阴影 | `shadow2` / 品牌辉光阴影 |
| 内边距 | 16px |

**折叠态内部布局**（约 100px 高）：
```
┌──┬────────────────────────────────────┐
│▌ │ #T-042  [Event徽章]  前端  ⚪待办   │  ← 头部行 12px, 间距 8px
│▌ │─────────────────────────────────── │
│▌ │ 当用户上传设计稿时，系统应当自动     │  ← Body2 14px, 最多2行
│▌ │ 识别页面元素并生成组件清单           │
│▌ │─────────────────────────────────── │
│▌ │ 优先级：高 · ~60min · 依赖 #T-040  │  ← Caption 12px
└──┴────────────────────────────────────┘
```

- EARS 类型徽章：对应渐变背景，白色文字 12px/w500，圆角 4px，内边距 2px 8px

#### 2.3.5 EARS 任务卡片（展开态）

在折叠态基础上增加：
- 阴影升级为 `shadow3`
- 左边框升级为渐变（`border-image` 方式）
- 展示完整内容：EARS需求描述、验收标准（可勾选）、依赖关系、所属模块、预估工时/成本、备注
- 底部操作按钮：[领取] [沟通] [标记完成]，使用小按钮样式

---

### 2.4 导航组件

#### 2.4.1 底部 TabBar

| 属性 | 值 |
|------|-----|
| 高度 | 56px（不含安全区） |
| 背景 | `#FFFFFF`，顶部 0.5px 分割线 `#E2E8F0` |
| Tab 数量 | 5 |
| Tab 项宽度 | 等分（约 75px） |
| 图标尺寸 | 24x24px |
| 图标-文字间距 | 2px |
| 文字字号 | 10px / Medium (w500) |
| 未选中颜色 | 图标 `#94A3B8`, 文字 `#94A3B8` |
| 选中颜色 | 图标品牌渐变填充, 文字 `#7C3AED` |
| 选中指示器 | 顶部 2px 渐变色条，宽度 32px，圆角 999px |

**5 个 Tab**：
| Tab | 图标(未选中) | 图标(选中) | 文字 |
|-----|-------------|-----------|------|
| 首页 | 线性房屋 | 填充渐变房屋 | 首页 |
| 广场 | 线性列表 | 填充渐变列表 | 广场 |
| 消息 | 线性气泡 | 填充渐变气泡 | 消息 |
| 项目 | 线性看板 | 填充渐变看板 | 项目 |
| 我的 | 线性头像 | 填充渐变头像 | 我的 |

```dart
BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
  backgroundColor: Colors.white,
  selectedItemColor: Color(0xFF7C3AED),
  unselectedItemColor: Color(0xFF94A3B8),
  selectedFontSize: 10,
  unselectedFontSize: 10,
  iconSize: 24,
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: '首页'),
    BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: '广场'),
    BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: '消息'),
    BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: '项目'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: '我的'),
  ],
)
```

#### 2.4.2 顶部 AppBar

| 属性 | 值 |
|------|-----|
| 高度 | 44px（不含状态栏） |
| 背景 | `#FFFFFF`（或渐变背景页面上使用透明） |
| 底部分割线 | 0.5px solid `#E2E8F0` |
| 左侧返回按钮 | 24x24px 图标, 触控区域 44x44px |
| 标题 | 18px / SemiBold, `#1E293B`, 居中 |
| 右侧操作区 | 最多 2 个图标按钮，间距 8px |

#### 2.4.3 步骤指示器 (Flow页面顶部)

| 属性 | 值 |
|------|-----|
| 高度 | 48px |
| 节点圆点（已完成） | 8px 实心, 品牌渐变 |
| 节点圆点（当前） | 10px 实心, 品牌渐变, 外圈 2px 白色 + 品牌阴影 |
| 节点圆点（未完成） | 8px 空心, 1px solid `#CBD5E1` |
| 连线（已完成） | 2px solid 品牌渐变 |
| 连线（未完成） | 2px solid `#E2E8F0` |
| 步骤文字 | 12px / Regular |
| 文字-节点间距 | 4px |

---

### 2.5 列表项组件

#### 2.5.1 消息列表项

| 属性 | 值 |
|------|-----|
| 高度 | 72px |
| 水平内边距 | 16px |
| 背景 | `#FFFFFF`（未读时带左侧 3px 品牌渐变条） |
| 底部分割线 | 0.5px solid `#E2E8F0`, 左侧缩进 72px |

**内部布局**：
```
┌─────────────────────────────────────────┐
│ [头像 48px]  昵称(14px/w600)  时间戳(12px)│
│              最新消息(14px/Reg, 最多1行)   │
│              [未读数徽章]                  │
└─────────────────────────────────────────┘
```

- 头像：48x48px, 圆形
- 昵称-头像间距：12px
- 时间戳：右对齐, 12px, `#94A3B8`
- 未读数徽章：右对齐, 20px 圆形, 背景 `#EF4444`, 文字白色 10px/w600

#### 2.5.2 项目列表项

| 属性 | 值 |
|------|-----|
| 高度 | 自适应（约 88px） |
| 圆角 | 16px |
| 背景 | `#FFFFFF` |
| 内边距 | 16px |
| 阴影 | `shadow2` |

**内部布局**：
```
┌────────────────────────────────────────┐
│ [项目图标] 项目名称(16px/w600)  [状态标签]│  ← 间距 12px
│ ████████░░░░ 完成 68%                  │  ← 进度条 4px高, 间距 8px
│ 供给方：阿杰  下次交付：3/22            │  ← 12px/Reg, 间距 4px
└────────────────────────────────────────┘
```

#### 2.5.3 通知列表项

| 属性 | 值 |
|------|-----|
| 高度 | 自适应（约 68px） |
| 水平内边距 | 16px |
| 未读指示 | 左侧 8px 品牌色实心圆点 |

**内部布局**：
```
┌─────────────────────────────────────────┐
│ [类型图标 32px]  通知标题(14px/w600)      │
│                  通知描述(14px/Reg, 1行)  │
│                  时间(12px, #94A3B8)     │
└─────────────────────────────────────────┘
```

---

### 2.6 对话框/弹窗组件

#### 2.6.1 居中对话框 (Alert Dialog)

| 属性 | 值 |
|------|-----|
| 宽度 | 295px |
| 圆角 | 16px |
| 背景 | `#FFFFFF` |
| 阴影 | `shadow4` |
| 内边距 | 24px |
| 遮罩 | `rgba(0,0,0,0.4)` + 模糊 `blur(8px)` |
| 入场动画 | scale 0.95->1.0 + opacity 0->1, 260ms, cubic-bezier(0.16,1,0.3,1) |

**内部布局**：
```
┌───────────────────────────────────┐
│          [图标/图片 48px]          │  ← 居中, 可选
│                                   │  ← 间距 16px
│        标题(18px/w600, 居中)       │
│                                   │  ← 间距 8px
│   描述文字(14px/Reg, 居中, #64748B)│
│                                   │  ← 间距 24px
│  [次要按钮]          [主按钮]      │  ← 按钮行, 间距 12px
└───────────────────────────────────┘
```

#### 2.6.2 底部弹窗 (Bottom Sheet)

| 属性 | 值 |
|------|-----|
| 宽度 | `double.infinity` |
| 最大高度 | 屏幕高度 * 0.85 |
| 顶部圆角 | 20px |
| 背景 | `#FFFFFF` |
| 阴影 | `shadow4` |
| 顶部拖拽指示条 | 宽 40px, 高 4px, 圆角 999px, 颜色 `#CBD5E1`, 距顶 8px |
| 遮罩 | `rgba(0,0,0,0.4)` |
| 入场动画 | 从底部滑入, 300ms, cubic-bezier(0.16,1,0.3,1) |
| 内边距 | 水平 16px, 顶部 24px（拖拽条下方） |

---

### 2.7 Tag/Chip 组件

#### 2.7.1 技能标签

| 属性 | 值 |
|------|-----|
| 高度 | 28px |
| 圆角 | 4px |
| 背景 | `#F1F5F9` |
| 文字 | 12px / Regular, `#475569` |
| 内边距 | 水平 8px, 垂直 4px |
| 标签间距 | 8px |

#### 2.7.2 状态标签

| 状态 | 背景 | 文字颜色 | 文字 |
|------|------|---------|------|
| 进行中 | `#EFF6FF` | `#3B82F6` | "进行中" |
| 待验收 | `#FFFBEB` | `#F59E0B` | "待验收" |
| 已完成 | `#ECFDF5` | `#10B981` | "已完成" |
| 有风险 | `#FEF2F2` | `#EF4444` | "有风险" |
| 待开始 | `#F1F5F9` | `#64748B` | "待开始" |

所有状态标签：高度 24px, 圆角 4px, 字号 12px/w500, 内边距 水平 8px 垂直 3px

#### 2.7.3 EARS 类型标签

| EARS 类型 | 背景渐变 | 文字 |
|-----------|---------|------|
| 始终 | `#7C5CFC -> #6C5CE7` | 白 12px/w500 |
| 事件 | `#0A7AFF -> #4A6CF7` | 白 12px/w500 |
| 状态 | `#FF9500 -> #F7B731` | 白 12px/w500 |
| 可选 | `#34C759 -> #7BED9F` | 白 12px/w500 |
| 异常 | `#FF3B30 -> #FC5C65` | 白 12px/w500 |

尺寸：高度 22px, 圆角 4px, 内边距 2px 8px

#### 2.7.4 可删除标签 (Deletable Chip)

| 属性 | 值 |
|------|-----|
| 高度 | 32px |
| 圆角 | 999px（胶囊） |
| 背景 | `#F1F5F9` |
| 文字 | 14px / Regular, `#334155` |
| 删除图标 | 16x16px, `#94A3B8`, 距文字 4px |
| 内边距 | 左 12px, 右 8px |

---

### 2.8 Avatar 组件

| 场景 | 尺寸 | 圆角 | 边框 |
|------|------|------|------|
| 聊天列表 | 48x48px | 999px（圆形） | none |
| 个人主页大头像 | 80x80px | 999px | 2px solid `#FFFFFF`（有阴影时） |
| 推荐卡片 | 48x48px | 999px | none |
| 评论/评价 | 32x32px | 999px | none |
| 导航栏小头像 | 28x28px | 999px | none |
| 团队头像 | 48x48px | 8px | none |

**认证用户头像边框**：品牌渐变环形边框 2px，使用 `Container` 嵌套实现

```dart
Container(
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(
      colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
    ),
  ),
  padding: EdgeInsets.all(2),
  child: CircleAvatar(
    radius: 24, // 48px头像
    backgroundImage: NetworkImage(avatarUrl),
  ),
)
```

**默认占位头像**：背景 `#E2E8F0`, 中心人物线性图标 `#94A3B8`

---

### 2.9 评分组件

| 属性 | 值 |
|------|-----|
| 星星数量 | 5 |
| 星星尺寸 | 20x20px |
| 星星间距 | 4px |
| 已评颜色 | `#F59E0B`（星芒金，填充） |
| 未评颜色 | `#E2E8F0`（线性描边） |
| 半星支持 | 是 |
| 评分数值 | 可选显示，14px / SemiBold, `#1E293B`, 距最后一颗星 8px |

**交互态**：用户拖动选星时，未选中的星从 `#E2E8F0` 过渡为 `#F59E0B`, 过渡动画 150ms

```dart
// 小型评分展示（如列表内）
Row(
  children: [
    Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
    SizedBox(width: 2),
    Text('4.9', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
  ],
)
```

---

### 2.10 进度条/加载组件

#### 2.10.1 线性进度条

| 属性 | 值 |
|------|-----|
| 高度 | 4px（列表内）/ 8px（详情页） |
| 圆角 | 999px（胶囊） |
| 背景轨道 | `#E2E8F0` |
| 填充色 | 品牌渐变 `#7C3AED -> #3B82F6` |
| 动画 | 值变化时 600ms ease-out 过渡 |

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(999),
  child: LinearProgressIndicator(
    value: 0.68,
    minHeight: 4,
    backgroundColor: Color(0xFFE2E8F0),
    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
  ),
)
```

#### 2.10.2 环形进度（进度环）

| 属性 | 值 |
|------|-----|
| 尺寸 | 64x64px（小）/ 96x96px（大） |
| 轨道宽度 | 6px（小）/ 8px（大） |
| 轨道颜色 | `#E2E8F0` |
| 填充色 | 品牌渐变 |
| 中心文字 | Num2 (24px/w600) 或 Num3 (16px/w500) |
| 动画 | 数值递增 600ms ease-out |

#### 2.10.3 骨架屏 (Skeleton)

| 属性 | 值 |
|------|-----|
| 占位块颜色 | `#E2E8F0` |
| 光波扫过 | 从左到右渐变光波, 1.5s, linear, infinite |
| 光波颜色 | `#F1F5F9` |
| 占位块圆角 | 文字行 4px, 图片 12px, 头像 999px |

```dart
// 骨架屏光波动画
ShimmerEffect(
  baseColor: Color(0xFFE2E8F0),
  highlightColor: Color(0xFFF1F5F9),
  period: Duration(milliseconds: 1500),
)
```

#### 2.10.4 全屏加载指示器

| 属性 | 值 |
|------|-----|
| 指示器尺寸 | 40x40px |
| 指示器颜色 | 品牌渐变 |
| 线宽 | 3px |
| 背景遮罩 | `rgba(255,255,255,0.8)` |

#### 2.10.5 下拉刷新

| 属性 | 值 |
|------|-----|
| 指示器 | 品牌色 CircularProgressIndicator |
| 触发距离 | 80px |
| 指示器位置 | 列表顶部上方居中 |

---

### 2.11 空状态组件

| 属性 | 值 |
|------|-----|
| 插图尺寸 | 160x160px |
| 插图风格 | 品牌渐变色线性插图，星空/星光主题 |
| 主文字 | 18px / SemiBold, `#1E293B`, 距插图 24px |
| 副文字 | 14px / Regular, `#64748B`, 距主文字 8px |
| 行动按钮 | 主按钮或文字按钮，距副文字 24px |
| 整体居中 | 垂直居中于可用空间 |

#### 场景化文案

| 场景 | 主文字 | 副文字 | 按钮 |
|------|-------|--------|------|
| 无项目 | 还没有任何项目 | 把你的想法告诉 AI，让我们帮你变成现实 | 发布第一个需求 |
| 无消息 | 暂时没有新消息 | 发布需求或投标项目后，就可以在这里沟通了 | -- |
| 无搜索结果 | 没有找到相关内容 | 试试其他关键词 | 调整筛选条件 |
| 供给方无收入 | 还没有收入记录 | 完善技能标签和作品集，让更多需求方找到你 | 完善个人主页 |
| 网络错误 | 网络连接失败 | 请检查你的网络设置 | 重新加载 |

---

### 2.12 Toast/Snackbar 组件

#### 2.12.1 Toast（轻提示）

| 属性 | 值 |
|------|-----|
| 位置 | 屏幕底部上方 120px，居中 |
| 最大宽度 | 300px |
| 高度 | 自适应，最小 40px |
| 圆角 | 8px |
| 背景 | `#1E293B` (90% opacity) |
| 文字 | 14px / Regular, `#FFFFFF`, 居中 |
| 内边距 | 水平 16px, 垂直 10px |
| 显示时长 | 2s |
| 入场动画 | 从下方 20px 淡入上滑, 200ms |
| 退场动画 | 淡出, 200ms |

#### 2.12.2 Snackbar（操作提示）

| 属性 | 值 |
|------|-----|
| 位置 | 屏幕底部，距底部安全区 16px |
| 宽度 | 屏幕宽度 - 32px（两侧 16px） |
| 高度 | 自适应，最小 48px |
| 圆角 | 8px |
| 背景（成功） | `#10B981` |
| 背景（警告） | `#F59E0B` |
| 背景（错误） | `#EF4444` |
| 背景（信息） | `#1E293B` |
| 文字 | 14px / Regular, `#FFFFFF` |
| 操作按钮 | 14px / SemiBold, `#FFFFFF`, 右对齐 |
| 显示时长 | 3s（有操作按钮则 5s） |
| 内边距 | 水平 16px, 垂直 12px |

---

## 3. 12个核心页面精确设计规范

### 3.1 启动/引导页 (Splash & Onboarding)

#### 3.1.1 启动页 (Splash Screen)

**页面结构**：全屏，无导航栏无 TabBar

| 区域 | 规格 |
|------|------|
| 背景 | 渐变组C 全屏铺满：`#5B21B6 -> #3730A3 -> #1E3A5F`, 方向 180deg |
| 星光粒子层 | 30-50 颗，白色 1-3px，透明度 30%-80%，缓慢闪烁 2-4s |
| Logo 区域 | 居中偏上（距顶部 40%），Logo 80x80px，带呼吸辉光 |
| 品牌名 | Logo 下方 16px, "VCC", 白色 28px/w700, Space Grotesk |
| 中文名 | 品牌名下方 8px, "开造", 白色 22px/w600 |
| Slogan | 中文名下方 24px, "点亮每一个想法", 白色 14px/w400, 透明度 70% |
| 加载时长 | 控制在 2s 内 |
| 退场动画 | Logo 缩小至 0.8 + 全屏白色淡入覆盖, 400ms |

#### 3.1.2 引导页 (Onboarding) — 3 页滑动

**页面结构**：全屏，底部指示器 + 按钮

| 区域 | 规格 |
|------|------|
| 背景 | 页面1: `#F8F7FF`, 页面2: `#EFF6FF`, 页面3: 渐变组A 浅版 (10% opacity) |
| 插图区域 | 屏幕上半部 60%，居中，240x240px 品牌风格插图 |
| 标题 | 插图下方 32px, H2 (22px/w600), `#1E293B`, 居中 |
| 描述 | 标题下方 8px, Body2 (14px/w400), `#64748B`, 居中, 最大宽度 280px |
| 页面指示器 | 底部 120px 处, 3 个圆点，当前 24px 宽 6px 高 品牌渐变胶囊, 非当前 6x6px `#CBD5E1` |
| 跳过按钮 | 右上角, 文字按钮 "跳过", 14px, `#94A3B8` |
| 主按钮（最后一页） | 底部 48px, "开始使用", 通栏主按钮 |

**三页内容**：
1. "AI帮你理清需求" — 描述AI对话式需求拆解
2. "智能匹配造物者" — 描述撮合系统
3. "透明管理全流程" — 描述项目管理看板

---

### 3.2 登录/注册页

**页面结构**：全屏Flow页面

| 区域 | 规格 |
|------|------|
| 背景 | `#FFFFFF` |
| 顶部品牌区 | 距顶部安全区 48px，Logo 48x48px + 品牌名 "开造" 22px/w600, 居中 |
| 欢迎文案 | Logo 下方 24px, "欢迎来到开造", H1 (28px/w700), `#1E293B`, 居中 |
| 副标题 | 欢迎文案下方 8px, "让每一个好想法都能被造出来", Body2, `#64748B`, 居中 |

**手机号登录区（默认显示）**：距副标题 48px
| 组件 | 规格 |
|------|------|
| 手机号输入框 | 标准单行输入框, 前缀 "+86", 键盘类型 number |
| 验证码输入框 | 手机号下方 12px, 右侧内嵌"获取验证码"文字按钮 |
| 获取验证码按钮 | 14px / Medium, `#7C3AED`, 倒计时时变为 `#94A3B8` "60s后重发" |
| 登录按钮 | 验证码下方 24px, 通栏主按钮, "登录 / 注册" |
| 服务协议 | 按钮下方 16px, 12px, `#94A3B8`, 含可点击蓝色链接 |

**第三方登录区**：
| 组件 | 规格 |
|------|------|
| 分割线 | "或" 文字居中, 两侧分割线, 距登录按钮 32px |
| 微信登录 | 48x48px 圆形按钮, 微信绿 `#07C160` 背景, 白色微信图标 24px |
| Apple登录 | 48x48px 圆形按钮, `#000000` 背景, 白色Apple图标 24px (仅iOS) |
| 按钮间距 | 24px |

**角色选择页（首次登录后）**：
| 组件 | 规格 |
|------|------|
| 标题 | "你想怎么使用开造？", H2, 居中 |
| 选项卡片 | 2 个大卡片, 宽度 343px, 高度 120px, 圆角 16px |
| 卡片1 | "我有想法想实现"（需求方）, 左侧 48px 图标, 选中边框品牌渐变 2px |
| 卡片2 | "我是造物者"（供给方）, 左侧 48px 图标, 选中边框品牌渐变 2px |
| 卡片3 | "我两个都是", 副标题 "随时可以切换" |
| 卡片间距 | 12px |
| 确认按钮 | 底部通栏主按钮 "开始使用" |

---

### 3.3 首页/发现页（项目推荐流）

#### 需求方首页

**页面结构**：L0-Tab1, 有底部 TabBar, 可下拉刷新

| 区域 | Y偏移 | 规格 |
|------|------|------|
| 顶部导航栏 | 0 | 左：品牌Logo 28x28px + "开造" 18px/w600; 右：通知图标铃铛 24px |
| AI入口卡片 | 导航栏下方 16px | 宽 343px, 高 120px, 圆角 16px, 品牌渐变背景(组A), 星光粒子(3-5颗) |
| — 问候语 | 卡片内顶部 16px | "你好，李想", 白色 18px/w600 |
| — 引导语 | 问候语下 4px | "把你的想法告诉我，AI帮你变成现实", 白色 14px/w400, 透明度 80% |
| — 输入入口 | 引导语下 12px | 毛玻璃输入框样式, 高 40px, 圆角 999px, "描述你的需求...", 白色 14px 透明度 60% |
| 热门分类 | AI卡片下 24px | 标题 "热门分类" 16px/w600; 6宫格, 每格 (343-2*8)/3=109px 宽, 高 72px, 圆角 12px, 背景 `#F8FAFC` |
| — 分类项 | | 居中图标 24px + 文字 12px/w500, 间距 4px |
| 我的项目 | 分类下 24px | 标题 "我的项目" 16px/w600 + "查看全部 >" 14px/w500 `#7C3AED` |
| — 项目卡片 | 标题下 12px | 项目列表项组件, 纵向排列, 间距 12px |
| 推荐供给方 | 项目下 24px | 标题 "推荐供给方"; 水平滚动, 用户卡片 140px 宽, 间距 12px |
| 平台数据 | 推荐下 24px | 三格数据卡, 圆角 12px, 背景 `#F8FAFC`, 高 64px |

#### 供给方首页

| 区域 | 规格 |
|------|------|
| 收入概览卡片 | 宽 343px, 品牌渐变背景, 圆角 16px |
| — 收入金额 | Num1 (36px/w700), 白色 |
| — 趋势 | 12px/w500, `#ECFDF5` 背景, 绿色 "↑12%" |
| — 三项数据 | "进行中 3" / "待投标 5" / "已完成 12", 白色 24px/w600 + 12px/w400 |
| 推荐需求列表 | 标题下 12px 开始, 项目卡片列表, 间距 12px |
| 技能热度排行 | 列表下方 24px, 3 行排名, 每行高度 40px |
| 组队机会 | 排行下方 24px, 水平滑动卡片, 宽 280px |

---

### 3.4 项目详情页

**页面结构**：L1 二级页面, AppBar 含返回按钮

| 区域 | 规格 |
|------|------|
| AppBar | 标题 "项目名称", 右侧 更多操作(三点) |
| 项目概览卡片 | 内边距 16px, 圆角 16px, 背景 `#FFFFFF` |
| — 进度环 | 左侧 64x64px 环形进度, 6px 轨道 |
| — 信息区 | 右侧: "完成 68%" Num2, "剩余 3 天" Body2, "供给方：阿杰团队" Body2, "里程碑：开发阶段" Caption |
| 子Tab栏 | 概览卡片下 16px, 5个Tab: 看板/里程碑/PRD/文件/简报 |
| — Tab 高度 | 40px |
| — 选中指示器 | 底部 2px 品牌渐变条 |
| — 文字 | 选中 14px/w600 `#7C3AED`, 未选中 14px/w400 `#94A3B8` |

**看板视图（默认子Tab）**：
| 区域 | 规格 |
|------|------|
| 三列布局 | 水平滚动, 每列宽度 280px, 列间距 12px |
| 列头 | "待办(5)" / "进行中(3)" / "已完成(20)", 14px/w600, `#475569` |
| 任务卡片 | EARS 折叠态卡片, 纵向排列, 间距 8px |
| 长按拖拽 | 长按 300ms 进入拖拽模式, 卡片抬升(shadow3 + scale 1.02) |

**底部操作区**：
| 区域 | 规格 |
|------|------|
| 高度 | 64px + 安全区 |
| 布局 | 左: "沟通" 次要按钮(宽 50%); 右: "验收" 主按钮(宽 50%) |
| 按钮间距 | 12px |
| 水平内边距 | 16px |

---

### 3.5 发布项目页（表单设计）

**页面结构**：Flow 流程页, 5 步, 顶部步骤指示器

#### Step 1 — 选择需求类别

| 区域 | 规格 |
|------|------|
| AppBar | "发布需求", 右上角 "取消" 文字按钮 |
| 步骤指示器 | ●---○---○---○---○, 标签: 分类/对话/PRD/确认/发布 |
| 分类网格 | 6 个分类卡片, 2列布局, 每卡 (343-12)/2=165.5px 宽, 高 96px |
| 卡片样式 | 圆角 12px, 背景 `#F8FAFC`, 居中图标 32px + 文字 14px/w600 |
| 选中态 | 边框 2px 品牌渐变, 背景 `#F8F7FF` |
| 底部按钮 | 通栏主按钮 "下一步" |

#### Step 2 — AI 对话式需求录入

| 区域 | 规格 |
|------|------|
| 聊天区域 | 占据除输入框和步骤指示器外的全部空间 |
| AI 气泡 | 左对齐, 背景 `#F1F5F9`, 圆角 12px(右上+右下+左下), 左上 4px, 最大宽度 280px |
| 用户气泡 | 右对齐, 品牌渐变背景(极浅 10%), 圆角 12px(左上+左下+右下), 右上 4px |
| 快捷回复 | 底部输入框上方, 水平滚动 Chip 列表, 高度 32px |
| 输入栏 | 高度 52px, 左侧附件按钮 24px, 中间输入框, 右侧发送按钮 32x32px 品牌渐变圆形 |
| "生成PRD" 按钮 | AI判断信息充足后出现, 通栏主按钮, 在输入栏上方 |

#### Step 3 — AI 生成 PRD 预览

**概览视图**（默认）：
| 区域 | 规格 |
|------|------|
| 项目概要卡片 | 品牌渐变背景(浅), 项目名 H3, 预估价格/工期/复杂度 Body2 白色 |
| 视图切换Tab | "概览视图 ✓" / "卡片视图", 两个Chip, 选中为品牌填充 |
| 模块树状图 | 水平滚动, 每个模块节点 100px 宽, 自适应高, 含状态色块+名称+完成比+工时+进度微条 |
| 模块列表 | 树状图下方, 纵向模块卡片, 含AI摘要, 可点击展开为EARS卡片 |

#### Step 4 — 编辑/确认 PRD

| 区域 | 规格 |
|------|------|
| PRD编辑器 | 可编辑的结构化表单: 项目名/功能列表/验收标准, 各项可增删改 |
| AI建议提示 | 顶部提示条, 背景 `#EFF6FF`, "AI 建议添加：xxx" + 采纳/忽略按钮 |

#### Step 5 — 设置预算与撮合偏好

| 区域 | 规格 |
|------|------|
| 预算范围 | 双滑块选择器, 轨道 4px, 活跃色品牌渐变, 范围标签 Num3 |
| 工期偏好 | 单选组: "不急" / "1周内" / "3天内", Chip 样式 |
| 撮合模式 | 单选组: "等待投标" / "智能匹配" / "急速派单" |
| 发布按钮 | 通栏主按钮 "确认发布需求" |

---

### 3.6 个人主页/档案页

**页面结构**：L0-Tab5（"我的"）

#### 供给方个人主页

| 区域 | 规格 |
|------|------|
| 头部区域 | 高度 280px, 上部品牌渐变背景(组A, 高 180px) + 星光粒子 |
| 头像 | 80x80px, 圆形, 白色 3px 边框, 位于渐变区域与白色背景交界处(50%在渐变上) |
| 昵称 | 头像下方 12px, H3 (18px/w600), `#1E293B` |
| 角色描述 | 昵称下方 4px, "全栈 Vibe Coder", Body2, `#64748B` |
| 评分+信用分 | 角色下方 4px, "⭐ 4.9 · 信用分 920", Caption |
| 等级徽章 | 右侧, "精英" + "已认证", 品牌渐变色标签 |
| 数据三格 | 3格水平分布, 完成项目/好评率/平均交付, Num2+Caption, 间距均等 |
| 技能标签 | 水平流布局, 技能Chip, 间距 8px |
| 子Tab | 作品集/评价/团队/接单数据, 同项目详情页子Tab样式 |
| 作品集 | 2列瀑布流, 图片卡片 (343-12)/2=165.5px 宽, 圆角 12px, 底部叠加作品名+评分 |
| 最新评价 | 评价卡片, 头像+昵称+评分+日期+评价文字 |
| 底部操作 | "编辑主页" 次要按钮 + "分享" 图标按钮 |

#### 需求方"我的"页面

| 区域 | 规格 |
|------|------|
| 头部卡片 | 背景 `#FFFFFF`, 头像 64px + 昵称 + 角色 + 信用分 |
| 数据三格 | 已发布/进行中/已完成, 布局同供给方 |
| 常用功能列表 | 标准列表项: 左图标(20px) + 标题(16px/w400) + 右箭头, 高度 52px |
| 设置列表 | 同上样式, 分区间距 24px |
| 切换角色入口 | 列表项, 左图标 + "切换为供给方" + 右箭头 |

---

### 3.7 搜索/筛选页

**页面结构**：从首页或广场进入, 有返回按钮

| 区域 | 规格 |
|------|------|
| 搜索栏 | 顶部, 胶囊搜索输入框 44px高, 自动聚焦, 右侧"取消"文字按钮 |
| 搜索历史 | 搜索栏下方 16px, 标题 "搜索历史" + 清除按钮 |
| — 历史标签 | 水平流布局 Chip, 高 32px, 背景 `#F1F5F9`, 间距 8px |
| 热门搜索 | 历史下方 24px, 标题 "热门搜索" |
| — 热门列表 | 2列, 每项高 40px, 序号(品牌色) + 关键词(14px/w400) |

**搜索结果页**：
| 区域 | 规格 |
|------|------|
| 筛选栏 | 搜索栏下方, 水平滚动 Chip 筛选: 类别/预算/工期/排序 |
| 筛选Chip | 高 32px, 圆角 999px, 默认: 背景 `#F1F5F9` 文字 `#475569`, 选中: 品牌渐变背景 白色文字 |
| 结果数量 | 筛选栏下方 12px, "找到 32 个结果", Caption, `#94A3B8` |
| 结果列表 | 项目卡片列表, 间距 12px |

**高级筛选（底部弹窗）**：
| 区域 | 规格 |
|------|------|
| 预算区间 | 双滑块, 范围 ¥0-¥50,000 |
| 项目类别 | 多选 Chip 组 |
| 技能要求 | 多选 Chip 组 |
| 排序方式 | 单选组: 综合/最新/预算高到低/匹配度 |
| 底部 | "重置" 文字按钮 + "确认" 主按钮 |

---

### 3.8 匹配结果页（AI推荐列表）

**页面结构**：从发布需求后进入, 或从通知进入

| 区域 | 规格 |
|------|------|
| AppBar | "收到的投标 (5)", 返回按钮 |
| 排序栏 | 水平滚动 Chip: 综合排序/价格↑/工期↑/评分↓ |
| AI推荐卡片（第一个）| 边框 2px 品牌渐变, 左上角 "AI推荐" 品牌渐变标签 |
| — 卡片内部 | 左: 头像/团队头像 48px; 右: 名称(16px/w600) + 评分+完成率(12px) + 匹配度(品牌色 14px/w600) |
| — 报价信息 | "报价：¥3,000  工期：8天", Body1, `#1E293B` |
| — 方案摘要 | Body2, 最多 2 行, `#64748B` |
| — 操作按钮 | "查看详情" 小幽灵按钮 + "选 TA" 小主按钮, 右对齐 |
| 普通投标卡片 | 同上但无特殊边框和标签 |
| 卡片间距 | 12px |

---

### 3.9 对话/消息列表页

**页面结构**：L0-Tab3

| 区域 | 规格 |
|------|------|
| AppBar | "消息", 固定, 无返回按钮(Tab页) |
| 消息分类Tab | "全部" / "项目" / "系统", 同子Tab样式, 高度 40px |
| 消息列表 | 消息列表项组件, 按时间倒序 |
| 左滑操作 | 左滑消息项露出: "标记已读"(蓝色背景) + "删除"(红色背景), 每个操作宽 72px |
| 未读红点 | TabBar 消息Tab 上, 右上角 8px 红色实心圆 `#EF4444` |

---

### 3.10 聊天详情页

**页面结构**：L1 二级页面

| 区域 | 规格 |
|------|------|
| AppBar | 左: 返回; 中: 对方昵称(16px/w600) + 在线状态(绿色圆点8px + "在线" 12px); 右: 更多按钮 |
| 消息流 | 占据中间全部空间, 可滚动 |
| AI气泡 | 背景 `#F1F5F9`, 圆角 12px(右上+右下+左下), 左上 4px |
| 对方气泡 | 背景 `#F1F5F9`, 同AI气泡布局, 左侧显示 28px 头像 |
| 我的气泡 | 背景品牌渐变(浅 10%), 圆角 12px(左上+左下+右下), 右上 4px, 右对齐 |
| 气泡文字 | 16px / Regular, `#1E293B` |
| 气泡内边距 | 12px |
| 气泡最大宽度 | 屏幕宽度 * 0.7 (262px) |
| 气泡间距 | 同一发送者连续消息 4px, 不同发送者 16px |
| 时间分割 | 超过 5 分钟无消息显示时间, 居中, 12px, `#94A3B8`, 背景 `#F1F5F9` 胶囊 |
| 关联任务卡片 | 消息流中可嵌入迷你EARS卡片, 可点击跳转 |
| 输入栏 | 底部固定, 高 52px, 左: 附件(+) 按钮 32px, 中: 输入框, 右: 发送按钮 32px 品牌渐变圆形 |
| AI翻译开关 | 输入栏上方, "AI翻译" 小开关, 开启后气泡下方显示翻译结果 |

---

### 3.11 订单/支付页

**页面结构**：Flow 流程页

#### 订单确认页

| 区域 | 规格 |
|------|------|
| AppBar | "确认订单", 返回按钮 |
| 项目摘要 | 卡片: 项目名 H3 + 供给方信息(头像+昵称) + 报价金额 Num2 |
| 里程碑付款 | 分阶段显示: M1 30% ¥900, M2 40% ¥1200, M3 30% ¥900 |
| — 里程碑项 | 高 48px, 左: 里程碑名(14px/w500), 右: 金额(14px/w600) |
| 优惠券 | 列表项: "优惠券" + "3张可用" 红色标签 + 右箭头, 可选择 |
| 金额明细 | 项目费用/平台服务费/优惠减免/实付金额, 14px, 实付金额 Num2 品牌色 |
| 担保说明 | 提示条: 锁图标 + "款项将安全托管在担保账户，验收通过后释放给造物者", 12px, `#64748B`, 背景 `#F1F5F9` |
| 支付按钮 | 通栏主按钮 "安心付款 ¥2,880" |

#### 支付方式选择（底部弹窗）

| 区域 | 规格 |
|------|------|
| 标题 | "选择支付方式", 18px/w600 |
| 微信支付 | 列表项, 左: 微信图标 24px, 中: "微信支付" 16px, 右: 单选圆圈 |
| 支付宝 | 同上, 支付宝蓝色图标 |
| 确认按钮 | 通栏主按钮 "确认支付" |

#### 支付结果页

| 区域 | 规格 |
|------|------|
| 成功状态 | 居中, 64px 绿色对勾动画(品牌粒子庆祝效果) + "支付成功" H2 + 金额 Num1 |
| 项目信息 | "项目已启动，可在看板中追踪进度", Body2, `#64748B` |
| 操作按钮 | "查看项目" 主按钮 + "返回首页" 文字按钮 |

---

### 3.12 设置页

**页面结构**：L1 二级页面

| 区域 | 规格 |
|------|------|
| AppBar | "设置", 返回按钮 |
| 列表分组 | 多组设置列表, 组间距 24px, 组标题 12px/w500 `#94A3B8` 大写 |

**设置项列表**：

| 分组 | 设置项 | 右侧控件 |
|------|--------|---------|
| 账号 | 手机号 | 文字 "138****8888" + 箭头 |
| 账号 | 微信绑定 | 文字 "已绑定" + 箭头 |
| 账号 | 实名认证 | 状态标签 "已认证" 绿色 |
| 偏好 | 深色模式 | Switch 开关 |
| 偏好 | 通知设置 | 箭头 |
| 偏好 | 隐私设置 | 箭头 |
| 偏好 | 语言 | 文字 "简体中文" + 箭头 |
| 关于 | 帮助与反馈 | 箭头 |
| 关于 | 关于开造 | 箭头 |
| 关于 | 版本 | 文字 "v1.0.0" |
| -- | 退出登录 | 居中红色文字按钮, 无箭头 |

**列表项规格**：
| 属性 | 值 |
|------|-----|
| 高度 | 52px |
| 左侧文字 | 16px / Regular, `#1E293B` |
| 右侧文字 | 14px / Regular, `#94A3B8` |
| 右侧箭头 | 16x16px, `#CBD5E1` |
| 分割线 | 0.5px solid `#E2E8F0`, 左侧缩进 16px |
| Switch 控件 | 关闭: 轨道 `#E2E8F0`, 圆钮 `#FFFFFF`; 开启: 轨道品牌渐变, 圆钮 `#FFFFFF` |

---

## 4. 深色模式

### 4.1 完整颜色映射表

| 元素 | 浅色模式 | 深色模式 | Flutter Dark |
|------|---------|---------|-------------|
| 页面背景 | `#F8F7FF` | `#0F0B1E` | `Color(0xFF0F0B1E)` |
| 二级背景 | `#F1F5F9` | `#1A1035` | `Color(0xFF1A1035)` |
| 卡片背景 | `#FFFFFF` | `#1E1640` | `Color(0xFF1E1640)` |
| 卡片悬停 | `#F8F7FF` | `#261D52` | `Color(0xFF261D52)` |
| 标题文字 | `#1E293B` | `#F8FAFC` | `Color(0xFFF8FAFC)` |
| 正文文字 | `#334155` | `#E2E8F0` | `Color(0xFFE2E8F0)` |
| 次要文字 | `#94A3B8` | `#64748B` | `Color(0xFF64748B)` |
| 占位文字 | `#94A3B8` | `#475569` | `Color(0xFF475569)` |
| 分割线 | `#E2E8F0` | `#2D2650` | `Color(0xFF2D2650)` |
| 边框 | `#E2E8F0` | `#2D2650` | `Color(0xFF2D2650)` |
| 输入框背景 | `#F1F5F9` | `#1A1035` | `Color(0xFF1A1035)` |
| 主渐变 | `#7C3AED -> #3B82F6` | `#8B5CF6 -> #60A5FA` | 提亮12% |
| 按钮渐变 | `#7C3AED -> #3B82F6` | `#7C3AED -> #3B82F6` | 保持不变 |
| 底部导航背景 | `#FFFFFF` | `#0F0B1E` | `Color(0xFF0F0B1E)` |
| 底部导航分割 | `#E2E8F0` | `#2D2650` | `Color(0xFF2D2650)` |
| 成功色 | `#10B981` | `#34D399` | `Color(0xFF34D399)` |
| 警告色 | `#F59E0B` | `#FBBF24` | `Color(0xFFFBBF24)` |
| 错误色 | `#EF4444` | `#F87171` | `Color(0xFFF87171)` |
| 信息色 | `#3B82F6` | `#60A5FA` | `Color(0xFF60A5FA)` |
| 阴影 | `rgba(0,0,0,x)` | `rgba(0,0,0,x*1.5)` | 加深 50% |
| 毛玻璃 | `rgba(255,255,255,0.72)` | `rgba(30,30,46,0.70)` | 深色半透明 |
| 星光粒子 | 不使用 | 启用, 透明度 20%-50% | -- |
| 品牌辉光 | `rgba(124,58,237,0.20)` | `rgba(124,58,237,0.30)` | 增强 50% |

### 4.2 组件深色模式样式变化

#### 按钮

| 类型 | 深色模式变化 |
|------|------------|
| 主按钮 | 渐变保持不变（按钮需要对比度），阴影品牌色增强至 0.45 |
| 次要按钮 | 背景 `#1E1640`, 边框 `#8B5CF6` |
| 幽灵按钮 | 边框 `#8B5CF6`, 文字 `#8B5CF6` |
| 文字按钮 | 文字 `#8B5CF6` |
| 危险按钮 | 背景 `#F87171`, 文字 `#FFFFFF` |

#### 输入框

| 状态 | 深色模式 |
|------|---------|
| 默认 | 背景 `#1A1035`, 边框 `#2D2650`, 文字 `#E2E8F0` |
| 聚焦 | 背景 `#1E1640`, 边框 `#8B5CF6` 2px |
| 错误 | 背景 `#1E1640`, 边框 `#F87171` 2px |

#### 卡片

| 卡片类型 | 深色模式 |
|---------|---------|
| 通用卡片 | 背景 `#1E1640`, 边框 0.5px `rgba(255,255,255,0.06)`, 阴影加深 |
| EARS卡片 | 背景 `#1E1640`, 毛玻璃效果增强, 左边框色保持 |
| AI推荐卡片 | 边框 `#8B5CF6` 2px |

### 4.3 切换逻辑

```dart
// 深色模式切换
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // 默认跟随系统

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

// 在设置页提供三个选项：
// 1. 跟随系统（默认）
// 2. 浅色模式
// 3. 深色模式
// Switch 控件切换，过渡动画 300ms
```

**切换过渡动画**：全局 crossfade, 300ms, ease-in-out。切换时当前主题淡出、新主题淡入，避免闪烁。

---

## 5. 响应式/适配规范

### 5.1 屏幕断点定义

| 断点名称 | 宽度范围 | 典型设备 | 布局策略 |
|---------|---------|---------|---------|
| `compact` | < 360px | iPhone SE, 小屏Android | 紧凑布局, 缩小间距至 12px, 卡片单列 |
| `medium` | 360-414px | iPhone 13/14, 主流Android | **基准设计**, 间距 16px, 卡片单列 |
| `expanded` | 415-599px | iPhone 14 Pro Max, 大屏Android | 加宽间距至 20px, 部分卡片可双列 |
| `tablet` | 600-1023px | iPad Mini, Android平板 | 双列/多列布局, 侧边栏导航 |
| `desktop` | >= 1024px | iPad Pro横屏, 桌面 | 三列布局, 固定侧边栏 |

### 5.2 Flutter 响应式实现

```dart
class Breakpoints {
  static const double compact = 360;
  static const double medium = 414;
  static const double expanded = 600;
  static const double tablet = 1024;

  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < compact;
  static bool isMedium(BuildContext context) =>
      MediaQuery.of(context).size.width >= compact &&
      MediaQuery.of(context).size.width < expanded;
  static bool isExpanded(BuildContext context) =>
      MediaQuery.of(context).size.width >= expanded &&
      MediaQuery.of(context).size.width < tablet;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;
}
```

### 5.3 关键页面适配规则

#### 首页

| 断点 | 布局变化 |
|------|---------|
| compact | AI入口卡片高度缩至 100px, 热门分类 2x3 网格, 推荐供给方卡片宽 120px |
| medium | 基准设计（如前述） |
| expanded | 热门分类 3x2 网格, 推荐供给方卡片可展示更多 |
| tablet | 左侧固定导航栏(240px宽), 右侧内容区双列卡片 |

#### 项目看板

| 断点 | 布局变化 |
|------|---------|
| compact/medium | 三列水平滚动, 每列 280px |
| tablet | 三列并排显示, 等分屏幕宽度 |
| desktop | 三列并排 + 右侧详情面板(360px) |

#### 聊天详情页

| 断点 | 布局变化 |
|------|---------|
| compact/medium | 全屏聊天 |
| tablet | 左侧消息列表(320px) + 右侧聊天详情 |

#### 搜索/筛选页

| 断点 | 布局变化 |
|------|---------|
| compact/medium | 搜索结果单列 |
| tablet | 搜索结果双列, 筛选面板固定左侧 |

### 5.4 安全区域适配

```dart
// 始终使用 SafeArea 包裹页面内容
SafeArea(
  child: Scaffold(
    body: // 页面内容,
  ),
)

// 底部按钮区域额外处理
Padding(
  padding: EdgeInsets.only(
    bottom: MediaQuery.of(context).padding.bottom + 16,
    left: 16,
    right: 16,
  ),
  child: PrimaryButton(text: '确认'),
)
```

### 5.5 文字缩放适配

```dart
// 最大字体缩放倍数限制为 1.3
MediaQuery(
  data: MediaQuery.of(context).copyWith(
    textScaler: TextScaler.linear(
      MediaQuery.of(context).textScaler.scale(1).clamp(0.8, 1.3),
    ),
  ),
  child: child,
)
```

---

## 附录 A：设计Token 完整清单（Flutter）

```dart
class AppColors {
  // 品牌色
  static const brandPurple = Color(0xFF7C3AED);
  static const brandIndigo = Color(0xFF6366F1);
  static const brandBlue = Color(0xFF3B82F6);
  static const brandDarkPurple = Color(0xFF5B21B6);

  // 辅助色
  static const accentCyan = Color(0xFF06B6D4);
  static const accentGold = Color(0xFFF59E0B);

  // 语义色
  static const success = Color(0xFF10B981);
  static const successBg = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const warningBg = Color(0xFFFFFBEB);
  static const error = Color(0xFFEF4444);
  static const errorBg = Color(0xFFFEF2F2);
  static const info = Color(0xFF3B82F6);
  static const infoBg = Color(0xFFEFF6FF);

  // 中性色阶
  static const gray50 = Color(0xFFF8FAFC);
  static const gray100 = Color(0xFFF1F5F9);
  static const gray200 = Color(0xFFE2E8F0);
  static const gray300 = Color(0xFFCBD5E1);
  static const gray400 = Color(0xFF94A3B8);
  static const gray500 = Color(0xFF64748B);
  static const gray600 = Color(0xFF475569);
  static const gray700 = Color(0xFF334155);
  static const gray800 = Color(0xFF1E293B);
  static const gray900 = Color(0xFF0F172A);

  // 深色模式专用
  static const darkBg = Color(0xFF0F0B1E);
  static const darkBg2 = Color(0xFF1A1035);
  static const darkCard = Color(0xFF1E1640);
  static const darkCardHover = Color(0xFF261D52);
  static const darkDivider = Color(0xFF2D2650);

  // 深色模式语义色（提亮版）
  static const successDark = Color(0xFF34D399);
  static const warningDark = Color(0xFFFBBF24);
  static const errorDark = Color(0xFFF87171);
  static const infoDark = Color(0xFF60A5FA);
}

class AppGradients {
  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF6366F1), Color(0xFF3B82F6)],
    stops: [0.0, 0.5, 1.0],
  );

  static const primaryPressed = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6D28D9), Color(0xFF2563EB)],
  );

  static const aurora = LinearGradient(
    begin: Alignment(-0.5, -1),
    end: Alignment(0.5, 1),
    colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
  );

  static const deepSpace = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF5B21B6), Color(0xFF3730A3), Color(0xFF1E3A5F)],
    stops: [0.0, 0.5, 1.0],
  );

  static const primaryDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF818CF8), Color(0xFF60A5FA)],
    stops: [0.0, 0.5, 1.0],
  );
}

class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;
}

class AppDurations {
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 300);
  static const progress = Duration(milliseconds: 600);
}

class AppCurves {
  static const standard = Cubic(0.16, 1, 0.3, 1); // 主缓动曲线
  static const easeOut = Curves.easeOut;
  static const easeInOut = Curves.easeInOut;
}
```

---

## 附录 B：页面转场动效规范

| 转场类型 | 动效描述 | 时长 | 曲线 |
|---------|---------|------|------|
| Push（前进） | 新页面从右侧滑入，当前页面左移并轻微缩小至 0.95 | 300ms | `Cubic(0.16,1,0.3,1)` |
| Pop（返回） | 当前页面向右滑出，上一页面从左侧还原至 1.0 | 250ms | `easeIn` |
| Modal（底部弹窗） | 从底部上滑弹出，背景添加遮罩 | 300ms | `Cubic(0.16,1,0.3,1)` |
| Tab切换 | 淡入淡出（crossfade），无位移 | 200ms | `linear` |
| 卡片展开 | 原地展开，其他卡片下移让位 | 260ms | `Cubic(0.16,1,0.3,1)` |
| 进度更新 | 进度条/进度环数值平滑过渡 | 600ms | `easeOut` |
| 状态变更 | 状态色块渐变过渡 | 260ms | `Cubic(0.16,1,0.3,1)` |
| 列表项删除 | 向左滑出 + 下方项平滑上移 | 250ms | `easeOut` |
| 页面内容加载 | 从下方 20px 处淡入上滑 | 400ms | `easeOut` |
| Toast 入场 | 从下方 20px 淡入上滑 | 200ms | `easeOut` |
| Toast 退场 | 淡出 | 200ms | `easeOut` |

---

## 附录 C：毛玻璃效果 Flutter 实现

```dart
// 毛玻璃卡片（浅色模式）
ClipRRect(
  borderRadius: BorderRadius.circular(16),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: // 卡片内容,
    ),
  ),
)

// 深色模式毛玻璃
ClipRRect(
  borderRadius: BorderRadius.circular(16),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
    child: Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E1E2E).withOpacity(0.70),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 0.5,
        ),
      ),
      child: // 卡片内容,
    ),
  ),
)
```

---

## 附录 D：极简美学自检清单

每次设计评审前逐一检查：

| # | 检查项 | 通过标准 |
|---|--------|---------|
| 1 | 页面核心目标 | 能用一句话说清 |
| 2 | 元素必要性 | 每个元素都不可移除 |
| 3 | 3秒理解法则 | 用户3秒内能理解页面要他做什么 |
| 4 | 渐变/光效面积 | 不超过视觉总面积的 15% |
| 5 | 主要行动点数量 | 每页不超过 1 个主按钮 |
| 6 | 最小可点击区域 | >= 44x44px |
| 7 | 动效持续时间 | UI动效不超过 300ms |
| 8 | 文字层级 | 不超过 3 层（标题/正文/辅助） |
| 9 | WCAG 对比度 | 正文 >= 4.5:1, 大标题 >= 3:1 |
| 10 | 深色模式完备 | 每个组件均有深色模式样式 |

---

> 下一步：基于本UI原型规范，Flutter 开发团队可直接开始组件库搭建 -> 页面开发 -> 联调测试
