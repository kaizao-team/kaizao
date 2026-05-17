# API 更新说明（2026-03-28）

本文档单独汇总 **2026-03-28** 起与「项目分类」相关的接口与数据变更，便于客户端与联调对照。完整规范仍以 `api-spec_v2.md` 为准；后续若合并进主文档，可删除本文件或改为指向主文档章节。

---

## 1. 变更摘要

- **项目分类枚举**由原先的 6 类（`app` / `web` / `miniprogram` / `design` / `data` / `consult`）调整为 **4 类**：`data` | `dev` | `visual` | `solution`。
- **需求方首页** `GET /api/v1/home/demander` 返回的 `categories` 固定为上述 4 项（含展示名、图标标识与数量），不再返回 6 类结构。
- **服务端校验**：创建/更新项目时，`category` 必须为四者之一；传入旧值将触发参数校验失败。
- **历史数据**：已通过迁移脚本 `kaizao/server/migrations/005_project_category_normalize.up.sql` 将 `projects.category` 清洗为新枚举（部署流程中会对已有库补跑该脚本）。

---

## 2. 分类键与展示（首页 / 业务约定）

| `key`（请求与存储） | 含义     | 首页 `name`（展示） | 首页 `icon`（字符串标识，供前端映射图标） |
|---------------------|----------|---------------------|------------------------------------------|
| `data`              | 数据     | 数据                | `bar_chart`                              |
| `dev`               | 研发     | 研发                | `code`                                   |
| `visual`            | 视觉设计 | 视觉设计            | `brush`                                  |
| `solution`          | 解决方案 | 解决方案            | `lightbulb`                              |

**历史值映射（库内已清洗）**：

- `app` / `web` / `miniprogram` → `dev`
- `design` → `visual`
- `consult` → `solution`
- `data` 保持 `data`
- 其余无法识别值 → `dev`（由迁移脚本约定）

---

## 3. 受影响接口

### 3.1 `GET /api/v1/home/demander`

- **变更**：响应 `data.categories` 数组长度由 6 变为 **4**，且 `key` / `name` / `icon` 与上表一致。
- **字段**（单项，未改字段名，仅取值集合变化）：
  - `key`：string，`data` | `dev` | `visual` | `solution`
  - `name`：string，中文展示名
  - `icon`：string，Material 风格标识（非 URL）
  - `count`：number，当前库中 **已发布（`status = 2`）** 且 `category = key` 的项目数量

### 3.2 `POST /api/v1/projects`

- **Body** `category`（必填）：仅允许 `data` | `dev` | `visual` | `solution`。
- 使用 `app`、`web` 等旧值将返回 **400**（参数校验失败）。

### 3.3 `PUT /api/v1/projects/:id`

- **Body** `category`（可选）：若传入，则同样必须为上述四值之一。

### 3.4 `GET /api/v1/projects`（含 `?category=`）

- **Query** `category`：建议仅传新四值；用于按 `projects.category` 精确筛选。传旧值时，若库内已无该字符串，列表结果为空（数据已清洗后旧键不再存在）。

### 3.5 `GET /api/v1/market/projects`

- **Query** `category`：语义同项目列表筛选；请使用新四值。

### 3.6 `POST /api/v1/projects/draft`（保存需求草稿）

- **行为**：若请求体未带 `category`，服务端创建草稿项目时默认写入 **`dev`**（原为 `app`）。
- 若显式传 `category`，须为新四值之一（与创建项目校验一致）。

### 3.7 `POST /api/v1/projects/ai-chat`、`POST /api/v1/projects/generate-prd`

- **说明**：请求体中的 `category` 字段建议与上述枚举对齐，便于后续与创建项目、草稿逻辑一致；具体是否做强校验以实现为准，客户端应统一改为新四值。

---

## 4. 响应中的 `category` 字符串

凡响应体中含项目信息的 `category` 字段（如列表项、详情、`my_projects`、`recommended_demands` 等），在数据清洗完成后，取值均为 **`data` | `dev` | `visual` | `solution`** 之一。

---

