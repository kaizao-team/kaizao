# TaskFlow - 架构设计文档

## 一、系统架构

### 1.1 架构模式

**模块化单体架构（Modular Monolith）**

- **选择理由**：初期团队规模小（5-20 人），业务复杂度不高，微服务会增加运维成本和分布式系统复杂度。模块化单体架构保持代码清晰，支持未来拆分为微服务。
- **优势**：开发效率高、部署简单、调试方便、事务管理简单。
- **演进路径**：随着业务增长，可逐步拆分为独立服务（如通知服务、支付服务）。

### 1.2 技术栈

#### 前端技术栈

| 技术 | 版本 | 选择理由 |
|------|------|----------|
| React | 18+ | 生态成熟，组件化开发，适合复杂交互 |
| TypeScript | 5.x | 类型安全，减少运行时错误，提升代码质量 |
| Ant Design | 5.x | 企业级 UI 组件库，设计规范完善，开发效率高 |
| Zustand | 4.x | 极简轻量（1KB），适合管理客户端状态 |
| React Query | 5.x | 服务端状态管理，自动缓存、重试、乐观更新 |
| Vite | 5.x | 构建速度快，开发体验好 |
| react-beautiful-dnd | 13.x | 拖拽功能实现，支持触摸设备 |

#### 后端技术栈

| 技术 | 版本 | 选择理由 |
|------|------|----------|
| NestJS | 10.x | 企业级框架，模块化架构，内置 TypeScript 支持 |
| TypeScript | 5.x | 类型安全，与前端技术栈统一 |
| Node.js | 18 LTS | 稳定版本，性能优秀 |
| Prisma | 5.x | 类型安全的 ORM，自动生成 TypeScript 类型 |
| PostgreSQL | 14+ | 支持 JSONB，查询优化器智能，扩展性强 |
| Redis | 7.x | 缓存、会话存储、实时数据 |

#### 基础设施

| 服务 | 提供商 | 用途 |
|------|--------|------|
| ECS | 阿里云 | 应用服务器 |
| RDS PostgreSQL | 阿里云 | 托管数据库（主从架构） |
| Redis | 阿里云 | 缓存服务（集群模式） |
| OSS | 阿里云 | 对象存储（附件） |
| SLB | 阿里云 | 负载均衡 |
| CDN | 阿里云 | 静态资源加速 |
| 邮件推送 | 阿里云 | 邮件通知服务 |

#### 第三方服务

| 服务 | 用途 |
|------|------|
| 支付宝 SDK | 支付集成 |
| 微信支付 SDK | 支付集成 |

### 1.3 部署拓扑

#### 开发环境

```
本地 Docker Compose
├── frontend (React 应用)
├── backend (NestJS 应用)
├── postgres (PostgreSQL)
└── redis (Redis)
```

#### 生产环境

```
客户端
  ↓
CDN（静态资源）
  ↓
Nginx（反向代理）
  ↓
SLB（负载均衡）
  ↓
NestJS 应用（Docker 容器，2+ 实例）
  ↓
├── RDS PostgreSQL（主从架构）
├── Redis（集群模式）
└── OSS（对象存储）
```

---

## 二、前端模块设计

### 2.1 模块划分

#### 看板模块（Board）

**组件**：
- `BoardList`：看板列表视图
- `BoardView`：看板详情视图（包含列表和任务）
- `BoardSettings`：看板设置弹窗
- `ListColumn`：列表列组件
- `AddListButton`：添加列表按钮

**页面路由**：
- `/boards`：看板列表
- `/boards/:id`：看板详情

**状态管理**：
- Zustand：管理当前看板上下文
- React Query：管理看板数据（缓存、乐观更新）

**核心功能**：
- 看板 CRUD
- 列表管理（创建、编辑、删除、排序）
- 拖拽排序（react-beautiful-dnd）

#### 任务模块（Task）

**组件**：
- `TaskCard`：任务卡片组件
- `TaskDetail`：任务详情弹窗
- `TaskForm`：任务创建/编辑表单
- `MarkdownEditor`：Markdown 编辑器
- `TagSelector`：标签选择器
- `PrioritySelector`：优先级选择器
- `AssigneeSelector`：负责人选择器

**页面路由**：
- 嵌入在看板视图中

**状态管理**：
- React Query：管理任务数据，乐观更新提升拖拽体验

**核心功能**：
- 任务 CRUD
- Markdown 描述编辑
- 标签管理
- 优先级设置
- 拖拽排序（跨列表）
- 任务分配

#### 团队模块（Team）

**组件**：
- `TeamList`：团队列表
- `TeamMembers`：成员管理
- `InviteModal`：邀请成员弹窗
- `PermissionSettings`：权限设置
- `MemberCard`：成员卡片

**页面路由**：
- `/teams`：团队列表
- `/teams/:id`：团队详情

**状态管理**：
- Zustand：管理当前团队上下文

**核心功能**：
- 团队管理
- 成员邀请（邮箱邀请）
- 权限控制（RBAC）
- 角色分配

#### 通知模块（Notification）

**组件**：
- `NotificationCenter`：通知中心（悬浮面板）
- `NotificationItem`：通知项
- `NotificationBadge`：未读徽章
- `NotificationList`：通知列表

**页面路由**：
- 全局组件，悬浮显示

**状态管理**：
- WebSocket：实时推送通知
- React Query：缓存通知数据

**核心功能**：
- 实时通知推送
- 已读/未读标记
- 通知筛选（类型、时间）

#### 用户模块（User）

**组件**：
- `LoginForm`：登录表单
- `RegisterForm`：注册表单
- `UserProfile`：用户资料
- `Settings`：设置页
- `AvatarUpload`：头像上传

**页面路由**：
- `/login`：登录页
- `/register`：注册页
- `/profile`：个人资料
- `/settings`：设置页

**状态管理**：
- Zustand：管理用户认证状态（token、用户信息）

**核心功能**：
- 登录注册
- 个人资料管理
- 偏好设置
- 头像上传

#### 订阅模块（Subscription）

**组件**：
- `PricingPage`：定价页
- `PaymentForm`：支付表单
- `SubscriptionStatus`：订阅状态
- `UpgradeModal`：升级弹窗

**页面路由**：
- `/pricing`：定价页
- `/subscription`：订阅管理

**状态管理**：
- React Query：管理订阅状态

**核心功能**：
- 订阅管理
- 支付集成（支付宝/微信）
- 套餐升级/降级

### 2.2 状态管理方案

#### 客户端状态（Zustand）

```typescript
// 用户认证状态
interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  login: (user: User, token: string) => void;
  logout: () => void;
}

// 当前团队上下文
interface TeamContextState {
  currentTeam: Team | null;
  setCurrentTeam: (team: Team) => void;
}

// UI 状态
interface UIState {
  isSidebarOpen: boolean;
  theme: 'light' | 'dark';
  toggleSidebar: () => void;
  setTheme: (theme: 'light' | 'dark') => void;
}
```

#### 服务端状态（React Query）

```typescript
// 看板数据
const { data: boards } = useQuery(['boards'], fetchBoards);

// 任务数据
const { data: tasks } = useQuery(['tasks', boardId], fetchTasks);

// 通知数据
const { data: notifications } = useQuery(['notifications'], fetchNotifications);

// 乐观更新示例（拖拽任务）
const mutation = useMutation(moveTask, {
  onMutate: async (newPosition) => {
    // 取消正在进行的请求
    await queryClient.cancelQueries(['tasks', boardId]);
    
    // 保存旧数据
    const previousTasks = queryClient.getQueryData(['tasks', boardId]);
    
    // 乐观更新
    queryClient.setQueryData(['tasks', boardId], (old) => {
      // 更新任务位置
      return updateTaskPosition(old, newPosition);
    });
    
    return { previousTasks };
  },
  onError: (err, newPosition, context) => {
    // 回滚
    queryClient.setQueryData(['tasks', boardId], context.previousTasks);
  },
});
```

### 2.3 路由设计

```typescript
const routes = [
  { path: '/login', component: LoginPage, public: true },
  { path: '/register', component: RegisterPage, public: true },
  { path: '/', component: DashboardPage, protected: true },
  { path: '/boards', component: BoardListPage, protected: true },
  { path: '/boards/:id', component: BoardDetailPage, protected: true },
  { path: '/teams', component: TeamListPage, protected: true },
  { path: '/teams/:id', component: TeamDetailPage, protected: true },
  { path: '/profile', component: ProfilePage, protected: true },
  { path: '/settings', component: SettingsPage, protected: true },
  { path: '/pricing', component: PricingPage, protected: true },
  { path: '/subscription', component: SubscriptionPage, protected: true },
];
```

---

## 三、后端模块设计

### 3.1 模块划分

#### AuthModule（认证模块）

**职责**：
- 用户注册、登录
- JWT Token 生成与验证
- Token 刷新机制
- 密码加密与验证

**依赖**：
- UserModule
- JwtModule

**核心功能**：
- bcrypt 密码加密（salt rounds: 10）
- JWT 有效期 7 天
- Refresh Token 机制（支持无感刷新）

**关键代码**：

```typescript
@Injectable()
export class AuthService {
  async register(registerDto: RegisterDto) {
    // 密码加密
    const hashedPassword = await bcrypt.hash(registerDto.password, 10);
    
    // 创建用户
    const user = await this.userService.create({
      ...registerDto,
      password: hashedPassword,
    });
    
    // 生成 Token
    const token = this.generateToken(user);
    return { user, token };
  }
  
  async login(loginDto: LoginDto) {
    // 验证用户
    const user = await this.userService.findByEmail(loginDto.email);
    if (!user) throw new UnauthorizedException('用户不存在');
    
    // 验证密码
    const isPasswordValid = await bcrypt.compare(loginDto.password, user.password);
    if (!isPasswordValid) throw new UnauthorizedException('密码错误');
    
    // 生成 Token
    const token = this.generateToken(user);
    const refreshToken = this.generateRefreshToken(user);
    
    return { user, token, refreshToken };
  }
}
```

#### UserModule（用户模块）

**职责**：
- 用户信息管理
- 用户偏好设置
- 用户头像上传

**依赖**：
- AuthModule

**实体**：
- User

#### TeamModule（团队模块）

**职责**：
- 团队 CRUD
- 成员管理
- 邀请机制
- 权限控制（RBAC）

**依赖**：
- UserModule
- AuthModule

**实体**：
- Team
- TeamMember
- Invitation

**核心功能**：
- 邮箱邀请成员
- 邀请链接 7 天有效
- 角色：管理员（admin）、成员（member）、只读成员（readonly）
- 免费版最多 5 人，Pro 版无限制

**权限控制**：

```typescript
@Injectable()
export class TeamGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user;
    const teamId = request.params.teamId;
    
    // 检查用户是否是团队成员
    const member = await this.teamService.findMember(teamId, user.id);
    if (!member) throw new ForbiddenException('无权访问此团队');
    
    // 检查权限
    const requiredRole = this.reflector.get<string>('role', context.getHandler());
    if (requiredRole && !this.hasRole(member.role, requiredRole)) {
      throw new ForbiddenException('权限不足');
    }
    
    return true;
  }
}
```

#### BoardModule（看板模块）

**职责**：
- 看板 CRUD
- 列表管理
- 看板权限控制

**依赖**：
- TeamModule
- UserModule

**实体**：
- Board
- List

**核心功能**：
- 创建看板时自动生成三个默认列表（待办、进行中、已完成）
- 每个看板最多 10 个列表
- 列表拖拽排序

#### TaskModule（任务模块）

**职责**：
- 任务 CRUD
- 任务分配
- 标签管理
- 优先级设置
- 任务排序

**依赖**：
- BoardModule
- UserModule
- NotificationModule

**实体**：
- Task
- TaskAssignment
- Tag
- TaskTag

**核心功能**：
- Markdown 描述支持
- 多人分配
- 拖拽排序（乐观更新）
- 优先级（高/中/低）
- 标签管理

#### CommentModule（评论模块）

**职责**：
- 评论 CRUD
- @ 提及功能
- Markdown 支持

**依赖**：
- TaskModule
- UserModule
- NotificationModule

**实体**：
- Comment
- Mention

**核心功能**：
- 实时评论更新
- @ 成员自动通知

#### AttachmentModule（附件模块）

**职责**：
- 文件上传
- 文件大小限制
- OSS 集成

**依赖**：
- TaskModule
- UserModule

**实体**：
- Attachment

**核心功能**：
- 免费版单文件 5MB，Pro 版 20MB
- 支持拖拽上传
- 阿里云 OSS 存储

#### NotificationModule（通知模块）

**职责**：
- 通知生成
- 通知推送
- 已读管理

**依赖**：
- UserModule

**实体**：
- Notification

**核心功能**：
- WebSocket 实时推送
- 邮件通知（可配置）
- 应用内通知中心

#### ReminderModule（提醒模块）

**职责**：
- 截止日期提醒
- 定时任务调度
- 提醒规则管理

**依赖**：
- TaskModule
- NotificationModule

**实体**：
- Reminder

**核心功能**：
- 提前 1 天和 1 小时提醒
- 自定义提醒时间
- Cron 定时任务

#### SubscriptionModule（订阅模块）

**职责**：
- 订阅管理
- 支付集成
- 权限控制

**依赖**：
- UserModule
- TeamModule

**实体**：
- Subscription
- Payment

**核心功能**：
- 支付宝/微信支付集成
- 按人/月计费（¥29/人/月）
- 订阅到期降级

#### CommonModule（公共模块）

**职责**：
- 全局异常过滤器
- 日志记录
- 文件上传工具
- 邮件服务
- OSS 服务

**核心功能**：
- 统一错误处理
- 请求日志
- 文件上传工具类

### 3.2 中间件和工具层

#### 日志中间件

```typescript
@Injectable()
export class LoggerMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: Function) {
    const { method, originalUrl } = req;
    const startTime = Date.now();
    
    res.on('finish', () => {
      const { statusCode } = res;
      const duration = Date.now() - startTime;
      
      this.logger.log(
        `${method} ${originalUrl} ${statusCode} - ${duration}ms`
      );
    });
    
    next();
  }
}
```

#### 异常过滤器

```typescript
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();
    
    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;
    
    const message =
      exception instanceof HttpException
        ? exception.getResponse()
        : 'Internal server error';
    
    response.status(status).json({
      statusCode: status,
      timestamp: new Date().toISOString(),
      path: request.url,
      message,
    });
  }
}
```

---

## 四、API 设计

### 4.1 认证接口

#### POST /api/auth/register

**描述**：用户注册

**请求体**：
```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "张三"
}
```

**响应**：
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "张三"
  },
  "token": "jwt_token"
}
```

#### POST /api/auth/login

**描述**：用户登录

**请求体**：
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**响应**：
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "张三"
  },
  "token": "jwt_token",
  "refreshToken": "refresh_token"
}
```

#### POST /api/auth/refresh

**描述**：刷新 Token

**请求体**：
```json
{
  "refreshToken": "refresh_token"
}
```

**响应**：
```json
{
  "token": "new_jwt_token",
  "refreshToken": "new_refresh_token"
}
```

### 4.2 看板接口

#### GET /api/boards

**描述**：获取用户的看板列表

**查询参数**：
- `teamId`（可选）：团队 ID

**响应**：
```json
{
  "boards": [
    {
      "id": "uuid",
      "name": "产品开发",
      "description": "产品开发看板",
      "teamId": "uuid",
      "createdAt": "2025-01-01T00:00:00Z",
      "updatedAt": "2025-01-01T00:00:00Z"
    }
  ]
}
```

#### POST /api/boards

**描述**：创建看板

**请求体**：
```json
{
  "name": "产品开发",
  "description": "产品开发看板",
  "teamId": "uuid"
}
```

**响应**：
```json
{
  "board": {
    "id": "uuid",
    "name": "产品开发",
    "description": "产品开发看板",
    "teamId": "uuid",
    "lists": [
      { "id": "uuid", "name": "待办", "position": 0 },
      { "id": "uuid", "name": "进行中", "position": 1 },
      { "id": "uuid", "name": "已完成", "position": 2 }
    ]
  }
}
```

#### GET /api/boards/:id

**描述**：获取看板详情（包含列表和任务）

**响应**：
```json
{
  "board": {
    "id": "uuid",
    "name": "产品开发",
    "description": "产品开发看板"
  },
  "lists": [
    {
      "id": "uuid",
      "name": "待办",
      "position": 0,
      "tasks": [
        {
          "id": "uuid",
          "title": "设计登录页面",
          "description": "## 任务描述\n...",
          "priority": "high",
          "dueDate": "2025-01-15T00:00:00Z",
          "assignees": [
            { "id": "uuid", "name": "张三", "avatar": "url" }
          ],
          "tags": [
            { "id": "uuid", "name": "设计", "color": "#FF5733" }
          ]
        }
      ]
    }
  ]
}
```

#### PUT /api/boards/:id

**描述**：更新看板

**请求体**：
```json
{
  "name": "产品开发 v2",
  "description": "更新后的描述"
}
```

#### DELETE /api/boards/:id

**描述**：删除看板

**响应**：
```json
{
  "success": true
}
```

### 4.3 列表接口

#### POST /api/lists

**描述**：创建列表

**请求体**：
```json
{
  "boardId": "uuid",
  "name": "测试中"
}
```

#### PUT /api/lists/:id

**描述**：更新列表

**请求体**：
```json
{
  "name": "测试完成",
  "position": 3
}
```

#### DELETE /api/lists/:id

**描述**：删除列表

### 4.4 任务接口

#### GET /api/tasks

**描述**：获取任务列表

**查询参数**：
- `boardId`：看板 ID
- `listId`（可选）：列表 ID
- `assigneeId`（可选）：负责人 ID
- `tagId`（可选）：标签 ID

#### POST /api/tasks

**描述**：创建任务

**请求体**：
```json
{
  "title": "设计登录页面",
  "description": "## 任务描述\n设计登录页面的 UI 和交互",
  "listId": "uuid",
  "dueDate": "2025-01-15T00:00:00Z",
  "priority": "high",
  "assigneeIds": ["uuid1", "uuid2"]
}
```

#### PUT /api/tasks/:id

**描述**：更新任务

**请求体**：
```json
{
  "title": "设计登录页面 v2",
  "description": "更新后的描述",
  "listId": "uuid",
  "position": 2,
  "dueDate": "2025-01-20T00:00:00Z",
  "priority": "medium"
}
```

#### PUT /api/tasks/:id/move

**描述**：移动任务（拖拽）

**请求体**：
```json
{
  "listId": "uuid",
  "position": 1
}
```

#### DELETE /api/tasks/:id

**描述**：删除任务

#### POST /api/tasks/:id/assign

**描述**：分配任务

**请求体**：
```json
{
  "userIds": ["uuid1", "uuid2"]
}
```

### 4.5 标签接口

#### POST /api/tags

**描述**：创建标签

**请求体**：
```json
{
  "name": "设计",
  "color": "#FF5733",
  "boardId": "uuid"
}
```

#### POST /api/tasks/:id/tags

**描述**：为任务添加标签

**请求体**：
```json
{
  "tagId": "uuid"
}
```

### 4.6 团队接口

#### GET /api/teams

**描述**：获取用户的团队列表

#### POST /api/teams

**描述**：创建团队

**请求体**：
```json
{
  "name": "产品团队",
  "description": "产品开发团队"
}
```

#### POST /api/teams/:id/invite

**描述**：邀请成员

**请求体**：
```json
{
  "email": "member@example.com",
  "role": "member"
}
```

#### POST /api/teams/join/:token

**描述**：接受邀请

#### DELETE /api/teams/:teamId/members/:userId

**描述**：移除成员

#### PUT /api/teams/:teamId/members/:userId/role

**描述**：更新成员角色

**请求体**：
```json
{
  "role": "admin"
}
```

### 4.7 通知接口

#### GET /api/notifications

**描述**：获取通知列表

**查询参数**：
- `isRead`（可选）：是否已读
- `type`（可选）：通知类型
- `page`：页码
- `limit`：每页数量

#### PUT /api/notifications/:id/read

**描述**：标记通知已读

#### PUT /api/notifications/read-all

**描述**：标记所有通知已读

### 4.8 评论接口

#### POST /api/comments

**描述**：创建评论

**请求体**：
```json
{
  "taskId": "uuid",
  "content": "这个设计很棒！@张三",
  "mentions": ["uuid"]
}
```

#### GET /api/tasks/:taskId/comments

**描述**：获取任务评论

### 4.9 附件接口

#### POST /api/attachments

**描述**：上传附件

**请求体**：`multipart/form-data`

**字段**：
- `taskId`：任务 ID
- `file`：文件

**响应**：
```json
{
  "attachment": {
    "id": "uuid",
    "fileName": "design.png",
    "fileUrl": "https://oss.example.com/...",
    "fileSize": 102400,
    "mimeType": "image/png"
  }
}
```

### 4.10 订阅接口

#### GET /api/subscriptions

**描述**：获取订阅状态

#### POST /api/subscriptions/checkout

**描述**：创建支付订单

**请求体**：
```json
{
  "plan": "pro",
  "quantity": 5
}
```

**响应**：
```json
{
  "paymentUrl": "https://alipay.com/..."
}
```

#### POST /api/subscriptions/webhook/alipay

**描述**：支付宝回调

#### POST /api/subscriptions/webhook/wechat

**描述**：微信支付回调

### 4.11 认证授权方案

#### JWT Token 认证

- **Token 有效期**：7 天
- **Refresh Token 有效期**：30 天
- **Token 载荷**：
  ```json
  {
    "sub": "user_id",
    "email": "user@example.com",
    "iat": 1234567890,
    "exp": 1234567890
  }
  ```

#### 权限控制（RBAC）

**角色定义**：
- **管理员（admin）**：所有权限
- **成员（member）**：创建/编辑任务，不能删除看板
- **只读成员（readonly）**：仅查看，不能编辑

**权限检查**：
- 每个 API 请求验证用户权限
- 使用 Guard 装饰器进行权限控制

---

## 五、数据模型

### 5.1 实体定义

#### User（用户）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PRIMARY KEY | 主键 |
| email | VARCHAR(255) | UNIQUE, NOT NULL | 邮箱 |
| password | VARCHAR(255) | NOT NULL | 密码（bcrypt 加密） |
| name | VARCHAR(100) | NOT NULL | 姓名 |
| avatar | VARCHAR(500) | NULL | 头像（OSS URL） |
| isPro | BOOLEAN | DEFAULT false | 是否 Pro 用户 |
| preferences | JSONB | DEFAULT {} | 用户偏好设置 |
| createdAt | TIMESTAMP | NOT NULL | 创建时间 |
| updatedAt | TIMESTAMP | NOT NULL | 更新时间 |

**索引**：
- UNIQUE INDEX on email
- INDEX on createdAt

#### Team（团队）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PRIMARY KEY | 主键 |
| name | VARCHAR(100) | NOT NULL | 团队名称 |
| description | TEXT | NULL | 团队描述 |
| ownerId | UUID | REFERENCES User(id) | 所有者 ID |
| isPro | BOOLEAN | DEFAULT false | 是否 Pro 团队 |
| createdAt | TIMESTAMP | NOT NULL | 创建时间 |
| updatedAt | TIMESTAMP | NOT NULL | 更新时间 |

**索引**：
- INDEX on ownerId
- INDEX on createdAt

#### TeamMember（团队成员）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PRIMARY KEY | 主键 |
| teamId | UUID | REFERENCES Team(id), NOT NULL | 团队 ID |
| userId | UUID | REFERENCES User(id), NOT NULL | 用户 ID |
| role | ENUM | ('admin', 'member', 'readonly'), NOT NULL | 角色 |
| joinedAt | TIMESTAMP | NOT NULL | 加入时间 |

**索引**：
- UNIQUE INDEX on (teamId, userId)
- INDEX on userId

#### Invitation（邀请）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PRIMARY KEY | 主键 |
| teamId | UUID | REFERENCES Team(id), NOT NULL | 团队 ID |
| email | VARCHAR(255) | NOT NULL | 被邀请者邮箱 |
| role | ENUM | ('admin', 'member', 'readonly'), NOT NULL | 角色 |
| token | VARCHAR(255) | UNIQUE, NOT NULL | 邀请 Token |
| status | ENUM | ('pending', 'accepted', 'expired'), NOT NULL | 状态 |
| expiresAt | TIMESTAMP | NOT NULL | 过期时间（7 天） |
| createdAt | TIMESTAMP | NOT NULL | 创建时间 |

**索引**：
- UNIQUE INDEX on token
- INDEX on email
- INDEX on expiresAt

#### Board（看板）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PRIMARY KEY | 主键 |
| name | VARCHAR(50) | NOT NULL | 看板名称 |
| description | TEXT | NULL | 看板描述 |
| teamId | UUID | REFERENCES Team(id), NOT NULL | 团队 ID |
| createdBy | UUID | REFERENCES User(id), NOT NULL | 创建者 ID |
| isArchived | BOOLEAN | DEFAULT false | 是否归档 |
| createdAt | TIMESTAMP | NOT NULL | 创建时间 |
| updatedAt | TIMESTAMP | NOT NULL | 更新时间 |

**索引**：
- INDEX on teamId
- INDEX on createdBy
- INDEX on isArchived

#### List（列表）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PRIMARY KEY | 主键 |
| name | VARCHAR(100) | NOT NULL | 列表名称 |
| boardId | UUID | REFERENCES Board(id), NOT NULL | 看板 ID |
| position | INTEGER | NOT NULL | 位置 |
| createdAt | TIMESTAMP | NOT NULL | 创建时间 |
| updatedAt | TIMESTAMP | NOT NULL | 更新时间 |

**索引**：
- INDEX on boardId
- UNIQUE INDEX on (boardId, position)

#### Task（任务）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PRIMARY KEY | 主键 |
| title | VARCHAR(100) | NOT NULL | 任务标题 |
| description | TEXT | NULL | 任务描述（Markdown） |
| listId | UUID | REFERENCES List(id), NOT NULL | 列表 ID |
| position | INTEGER | NOT NULL | 位置 |
| priority | ENUM | ('high', 'medium', 'low'), DEFAULT 'medium' | 优先级 |
| dueDate | TIMESTAMP | NULL | 截止日期 |
| isArchived | BOOLEAN | DEFAULT false | 是否归档 |
| createdBy | UUID | REFERENCES User(id), NOT NULL | 创建者 ID |
| createdAt | TIMESTAMP | NOT NULL | 创建时间 |
| updatedAt | TIMESTAMP | NOT NULL | 更新时间 |

**索引**：
- INDEX on listId
- INDEX on createdBy
- INDEX on dueDate
- INDEX on priority
- UNIQUE INDEX on (listId, position)

#### TaskAssignment（任务分配）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PRIMARY KEY | 主键 |
| taskId | UUID | REFERENCES Task(id), NOT NULL | 任务 ID |
| userId | UUID | REFERENCES User(id), NOT NULL | 用户 ID |
| assignedAt | TIMESTAMP | NOT NULL | 分配时间 |

**索引**：
- UNIQUE INDEX on (taskId, userId)
- INDEX on userId

#### Tag（标签）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PRIMARY KEY | 主键 |
| name | VARCHAR(50) | NOT NULL | 标签名称 |
| color | VARCHAR(7) | NOT NULL | 颜色（HEX） |
| boardId | UUID | REFERENCES Board(id), NOT NULL | 看板 ID |
| createdAt | TIMESTAMP | NOT NULL | 创建时间 |

**索引**：
- INDEX on boardId
- UNIQUE INDEX on (boardId, name)

#### TaskTag（任务标签）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PRIMARY KEY | 主键 |
| taskId | UUID | REFERENCES Task(id), NOT NULL | 任务 ID |
| tagId | UUID | REFERENCES Tag(id), NOT NULL | 标签 ID |

**索引**：
- UNIQUE INDEX on (taskId, tagId)

#### Comment（评论）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PRIMARY KEY | 主键 |
| taskId | UUID | REFERENCES Task(id), NOT NULL | 任务 ID |
| userId | UUID | REFERENCES User(id), NOT NULL | 用户 ID |
| content | TEXT | NOT NULL | 评论内容（Markdown） |
| createdAt | TIMESTAMP | NOT NULL | 创建时间 |
| updatedAt | TIMESTAMP | NOT NULL | 更新时间 |

**索引**：
- INDEX on taskId
- INDEX on userId
- INDEX on createdAt

#### Attachment（附件）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PRIMARY KEY | 主键 |
| taskId | UUID | REFERENCES Task(id), NOT NULL | 任务 ID |
| userId | UUID | REFERENCES User(id), NOT NULL | 用户 ID |
| fileName | VARCHAR(255) | NOT NULL | 文件名 |
| fileUrl | VARCHAR(500) | NOT NULL | 文件 URL（OSS） |
| fileSize | INTEGER | NOT NULL | 文件大小（字节） |
| mimeType | VARCHAR(100) | NOT NULL | MIME 类型 |
| createdAt | TIMESTAMP | NOT NULL | 创建时间 |

**索引**：
- INDEX on taskId
- INDEX on userId

#### Notification（通知）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PRIMARY KEY | 主键 |
| userId | UUID | REFERENCES User(id), NOT NULL | 用户 ID |
| type | ENUM | ('task_assigned', 'task_updated', 'comment', 'mention', 'due_reminder'), NOT NULL | 通知类型 |
| title | VARCHAR(255) | NOT NULL | 标题 |
| content | TEXT | NOT NULL | 内容 |
| data | JSONB | DEFAULT {} | 附加数据 |
| isRead | BOOLEAN | DEFAULT false | 是否已读 |
| createdAt | TIMESTAMP | NOT NULL | 创建时间 |

**索引**：
- INDEX on userId
- INDEX on isRead
- INDEX on createdAt

#### Subscription（订阅）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PRIMARY KEY | 主键 |
| teamId | UUID | REFERENCES Team(id), NOT NULL | 团队 ID |
| plan | ENUM | ('free', 'pro'), NOT NULL | 套餐 |
| quantity | INTEGER | NOT NULL | 人数 |
| status | ENUM | ('active', 'canceled', 'expired'), NOT NULL | 状态 |
| currentPeriodStart | TIMESTAMP | NOT NULL | 当前周期开始时间 |
| currentPeriodEnd | TIMESTAMP | NOT NULL | 当前周期结束时间 |
| createdAt | TIMESTAMP | NOT NULL | 创建时间 |
| updatedAt | TIMESTAMP | NOT NULL | 更新时间 |

**索引**：
- INDEX on teamId
- INDEX on status
- INDEX on currentPeriodEnd

#### Payment（支付）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | UUID | PRIMARY KEY | 主键 |
| subscriptionId | UUID | REFERENCES Subscription(id), NOT NULL | 订阅 ID |
| amount | DECIMAL(10,2) | NOT NULL | 金额 |
| currency | VARCHAR(3) | DEFAULT 'CNY' | 货币 |
| provider | ENUM | ('alipay', 'wechat'), NOT NULL | 支付提供商 |
| providerTransactionId | VARCHAR(255) | NULL | 第三方交易 ID |
| status | ENUM | ('pending', 'completed', 'failed'), NOT NULL | 状态 |
| createdAt | TIMESTAMP | NOT NULL | 创建时间 |

**索引**：
- INDEX on subscriptionId
- INDEX on status
- UNIQUE INDEX on providerTransactionId

### 5.2 实体关系图

```
User
  ├── TeamMember (n:m) → Team
  ├── Invitation (1:n)
  ├── Board (1:n)
  ├── Task (1:n)
  ├── TaskAssignment (n:m) → Task
  ├── Comment (1:n)
  ├── Attachment (1:n)
  └── Notification (1:n)

Team
  ├── TeamMember (1:n)
  ├── Invitation (1:n)
  ├── Board (1:n)
  └── Subscription (1:1)

Board
  ├── List (1:n)
  └── Tag (1:n)

List
  └── Task (1:n)

Task
  ├── TaskAssignment (1:n)
  ├── TaskTag (1:n) → Tag
  ├── Comment (1:n)
  └── Attachment (1:n)

Subscription
  └── Payment (1:n)
```

---

## 六、非功能性设计

### 6.1 性能设计

#### 性能目标

| 指标 | 目标 | 实现策略 |
|------|------|----------|
| 页面首屏加载时间 | < 2s | 代码分割、懒加载、CDN 加速、Gzip 压缩 |
| API 响应时间（P95） | < 500ms | 数据库索引优化、Redis 缓存热点数据、查询优化 |
| 拖拽操作延迟 | < 300ms | 乐观更新、防抖节流、WebSocket 实时同步 |
| 并发用户数 | 1000+ | 负载均衡、数据库连接池、Redis 缓存、水平扩展 |

#### 缓存策略

- **Redis 缓存**：
  - 用户会话和权限信息
  - 看板列表、任务列表
  - 热点数据缓存（TTL: 5-15 分钟）

- **React Query 缓存**：
  - 服务端数据缓存（staleTime: 30s）
  - 减少重复请求

- **CDN 缓存**：
  - 静态资源（JS、CSS、图片）
  - 缓存策略：长期缓存 + 文件名哈希

- **数据库查询缓存**：
  - 看板列表、任务列表查询结果缓存
  - 使用 Redis 作为查询缓存层

### 6.2 安全设计

#### 认证安全

- **JWT Token 认证**：
  - Token 有效期 7 天
  - Refresh Token 有效期 30 天
  - Token 载荷最小化（仅包含 user_id、email）

- **密码安全**：
  - bcrypt 加密（salt rounds: 10）
  - 密码强度要求（8-32 位，包含字母和数字）

#### 授权安全

- **基于角色的访问控制（RBAC）**：
  - 管理员（admin）：所有权限
  - 成员（member）：创建/编辑任务，不能删除看板
  - 只读成员（readonly）：仅查看，不能编辑

- **权限检查**：
  - 每个 API 请求验证用户权限
  - 使用 Guard 装饰器进行权限控制

#### 数据安全

- **传输安全**：
  - HTTPS 强制加密传输
  - TLS 1.2+ 协议

- **存储安全**：
  - 敏感数据（密码、Token）加密存储
  - 数据库访问控制（最小权限原则）

- **防护措施**：
  - SQL 注入防护（Prisma 参数化查询）
  - XSS 防护（前端输入过滤、输出编码）
  - CSRF 防护（SameSite Cookie）

#### API 安全

- **Rate Limiting**：
  - 每用户 100 req/min
  - 超出限制返回 429 状态码

- **CORS 配置**：
  - 白名单域名
  - 仅允许指定域名访问

- **请求验证**：
  - class-validator 参数验证
  - DTO 类型检查

### 6.3 可扩展性设计

#### 水平扩展

- **应用层**：
  - 无状态设计，支持水平扩展
  - 使用 SLB 负载均衡
  - 支持 2+ 实例部署

- **数据库层**：
  - PostgreSQL 主从架构
  - 读写分离
  - 连接池管理

- **缓存层**：
  - Redis 集群模式
  - 支持分片和复制

- **存储层**：
  - 阿里云 OSS 无限扩展
  - CDN 加速

#### 垂直扩展

- **数据库优化**：
  - 索引优化
  - 查询优化
  - 分区表（按时间分区）

- **应用优化**：
  - 代码优化
  - 异步处理
  - 批量操作

### 6.4 可用性设计

#### 高可用目标

- **可用性目标**：99.5% 以上
- **年度停机时间**：< 44 小时

#### 高可用策略

- **负载均衡**：
  - SLB 负载均衡
  - 健康检查
  - 自动故障转移

- **多实例部署**：
  - 应用服务器 2+ 实例
  - 数据库主从架构
  - Redis 集群模式

- **健康检查**：
  - 应用健康检查接口
  - 数据库连接检查
  - Redis 连接检查

- **自动重启**：
  - PM2 进程管理
  - 自动重启策略

#### 备份策略

- **自动备份**：
  - 每日凌晨 2 点自动备份
  - 备份保留 30 天
  - 支持手动触发备份

- **备份监控**：
  - 备份失败发送告警
  - 备份成功通知

- **恢复测试**：
  - 每月进行恢复测试
  - 验证备份完整性

### 6.5 监控与告警

#### 应用监控

- **日志收集**：
  - Winston 日志框架
  - 阿里云日志服务
  - 日志分级（error、warn、info、debug）

- **性能监控**：
  - 响应时间监控
  - 错误率监控
  - QPS 监控

- **业务指标**：
  - 用户数
  - 任务数
  - 订阅数
  - 活跃度

#### 基础设施监控

- **服务器监控**：
  - CPU 使用率
  - 内存使用率
  - 磁盘使用率
  - 网络流量

- **数据库监控**：
  - 连接数
  - 查询性能
  - 慢查询日志

- **Redis 监控**：
  - 内存使用
  - 连接数
  - 命令执行时间

#### 告警策略

- **错误告警**：
  - 错误率超过 5% 告警
  - 5xx 错误立即告警

- **性能告警**：
  - 响应时间超过 1s 告警
  - 数据库慢查询告警

- **资源告警**：
  - CPU 使用率超过 80% 告警
  - 内存使用率超过 85% 告警
  - 磁盘使用率超过 90% 告警

- **业务告警**：
  - 数据库备份失败告警
  - 支付失败告警

---

## 七、技术决策

### 7.1 架构模式选择

#### 决策：采用模块化单体架构

**理由**：
- 初期团队规模小（5-20 人），业务复杂度不高
- 微服务会增加运维成本和分布式系统复杂度
- 模块化单体架构保持代码清晰，支持未来拆分为微服务

**优势**：
- 开发效率高
- 部署简单
- 调试方便
- 事务管理简单

**劣势**：
- 扩展性受限
- 单点故障风险

**权衡分析**：
- 初期选择模块化单体架构，快速迭代
- 随着业务增长，逐步拆分为微服务
- 优先拆分独立服务：通知服务、支付服务

**替代方案**：
- **微服务**：扩展性好但复杂度高，初期不适用
- **Serverless**：成本低但限制多，不适合长期发展

### 7.2 后端框架选择

#### 决策：采用 NestJS 而非 Express

**理由**：
- NestJS 提供完整的架构体系（模块化、依赖注入、装饰器）
- 内置 TypeScript 支持，类型安全
- 适合团队协作和长期维护
- 企业级应用的最佳实践

**优势**：
- 架构规范清晰
- 依赖注入机制
- 装饰器语法优雅
- 内置 WebSocket 支持

**劣势**：
- 学习曲线较陡
- 框架较重

**权衡分析**：
- 学习成本较高，但长期收益更高
- 规范性比灵活性更重要

**替代方案**：
- **Express**：更灵活但缺乏规范，适合小型项目
- **Fastify**：性能更好但生态较小

### 7.3 ORM 选择

#### 决策：采用 Prisma 而非 TypeORM

**理由**：
- Prisma 提供类型安全的查询 API
- 自动生成 TypeScript 类型，减少运行时错误
- Prisma Schema 直观易读
- 迁移工具强大

**优势**：
- 类型安全
- 自动生成类型
- Schema 直观
- 迁移工具强大

**劣势**：
- 复杂查询需要使用原生 SQL
- 学习成本

**权衡分析**：
- 大多数场景 Prisma 已足够
- 复杂查询可使用原生 SQL

**替代方案**：
- **TypeORM**：更接近传统 ORM，但类型支持较弱
- **Sequelize**：成熟但 TypeScript 支持较弱

### 7.4 前端状态管理选择

#### 决策：采用 Zustand + React Query 而非 Redux Toolkit

**理由**：
- Zustand 极简轻量（1KB），适合管理客户端状态
- React Query 专注服务端状态管理，自动处理缓存、重试、乐观更新
- 相比 Redux 的复杂度，这套方案更简单高效

**优势**：
- Zustand：极简、轻量、易学
- React Query：自动缓存、重试、乐观更新

**劣势**：
- 需要学习两个库

**权衡分析**：
- 各自职责清晰，学习成本可控
- 开发效率更高

**替代方案**：
- **Redux Toolkit**：功能强大但复杂，适合大型项目
- **MobX**：响应式但学习成本高

### 7.5 数据库选择

#### 决策：采用 PostgreSQL 而非 MySQL

**理由**：
- PostgreSQL 支持 JSONB 类型，适合存储半结构化数据
- 查询优化器更智能，支持复杂查询
- 开源生态活跃，扩展性强

**优势**：
- JSONB 支持
- 查询优化器智能
- 扩展性强

**劣势**：
- 学习成本稍高
- 社区相对较小

**权衡分析**：
- 功能更强大，适合复杂业务
- JSONB 支持是关键优势

**替代方案**：
- **MySQL**：更流行但功能较弱
- **MongoDB**：灵活但事务支持弱

### 7.6 云平台选择

#### 决策：采用阿里云而非 AWS

**理由**：
- 目标用户在国内，阿里云网络延迟更低
- 合规性更好
- 支付宝/微信支付集成更方便
- 成本相对 AWS 更低

**优势**：
- 国内访问速度快
- 合规性好
- 支付集成方便
- 成本低

**劣势**：
- 全球化部署受限

**权衡分析**：
- 目标用户在国内，阿里云是最佳选择
- 未来如需全球化，可使用多云架构

**替代方案**：
- **AWS**：全球化但国内访问慢
- **腾讯云**：类似但生态稍弱

### 7.7 容器化部署选择

#### 决策：采用 Docker 容器化部署

**理由**：
- 容器化保证开发、测试、生产环境一致性
- Docker Compose 简化本地开发环境搭建
- 支持快速部署和回滚
- 为未来 Kubernetes 迁移做准备

**优势**：
- 环境一致性
- 快速部署
- 支持回滚
- 易于迁移

**劣势**：
- 需要学习 Docker

**权衡分析**：
- 学习成本可控，长期收益高

**替代方案**：
- **传统部署**：简单但环境不一致
- **Kubernetes**：强大但初期复杂

### 7.8 实时通知选择

#### 决策：采用 WebSocket 实现实时通知

**理由**：
- 任务分配、评论、拖拽等操作需要实时同步
- WebSocket 双向通信延迟低，用户体验好
- NestJS 内置 WebSocket 支持

**优势**：
- 实时性好
- 双向通信
- 延迟低

**劣势**：
- 需要处理连接管理

**权衡分析**：
- 实时性是关键需求，WebSocket 是最佳选择

**替代方案**：
- **轮询**：简单但延迟高
- **Server-Sent Events**：单向通信，不适合双向交互

---

## 八、部署方案

### 8.1 开发环境

#### 本地开发环境

```yaml
# docker-compose.yml
version: '3.8'

services:
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    volumes:
      - ./frontend:/app
    environment:
      - API_URL=http://localhost:3001
    
  backend:
    build: ./backend
    ports:
      - "3001:3001"
    volumes:
      - ./backend:/app
    environment:
      - DATABASE_URL=postgresql://user:password@postgres:5432/taskflow
      - REDIS_URL=redis://redis:6379
    depends_on:
      - postgres
      - redis
    
  postgres:
    image: postgres:14
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=taskflow
    volumes:
      - postgres_data:/var/lib/postgresql/data
    
  redis:
    image: redis:7
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

### 8.2 生产环境

#### 部署架构

```
┌─────────────────────────────────────────────────────────┐
│                      阿里云                              │
│                                                          │
│  ┌──────────────┐        ┌──────────────┐              │
│  │     CDN      │        │     OSS      │              │
│  │  (静态资源)   │        │   (附件)      │              │
│  └──────────────┘        └──────────────┘              │
│         │                        ▲                      │
│         ▼                        │                      │
│  ┌──────────────┐                │                      │
│  │     SLB      │                │                      │
│  │  (负载均衡)   │                │                      │
│  └──────────────┘                │                      │
│         │                        │                      │
│         ▼                        │                      │
│  ┌──────────────┐        ┌──────────────┐              │
│  │   Nginx      │        │    Redis     │              │
│  │  (反向代理)   │        │   (缓存)      │              │
│  └──────────────┘        └──────────────┘              │
│         │                        ▲                      │
│         ▼                        │                      │
│  ┌──────────────┐                │                      │
│  │  NestJS App  │────────────────┘                      │
│  │  (Docker x2) │                                        │
│  └──────────────┘                                        │
│         │                                                 │
│         ▼                                                 │
│  ┌──────────────┐                                        │
│  │ RDS Postgres │                                        │
│  │  (主从架构)   │                                        │
│  └──────────────┘                                        │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

#### Docker 部署配置

```dockerfile
# backend/Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY dist ./dist

EXPOSE 3001

CMD ["node", "dist/main.js"]
```

```dockerfile
# frontend/Dockerfile
FROM node:18-alpine as builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM nginx:alpine

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### 8.3 CI/CD 流程

#### GitHub Actions 配置

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run tests
        run: npm test
      
      - name: Run linter
        run: npm run lint
  
  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Docker images
        run: docker-compose build
      
      - name: Push to registry
        run: docker-compose push
  
  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to production
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.HOST }}
          username: ${{ secrets.USERNAME }}
          key: ${{ secrets.KEY }}
          script: |
            cd /app/taskflow
            docker-compose pull
            docker-compose up -d
            docker system prune -f
```

---

## 九、开发规范

### 9.1 代码规范

#### TypeScript 规范

- 使用 ESLint + Prettier 进行代码格式化
- 使用严格模式（strict: true）
- 所有变量、函数、类都需要类型注解
- 优先使用 interface 而非 type
- 使用枚举（enum）定义常量

#### 命名规范

- **变量/函数**：camelCase（如：getUserById）
- **类/接口**：PascalCase（如：UserService）
- **常量**：UPPER_SNAKE_CASE（如：MAX_LIST_COUNT）
- **文件名**：kebab-case（如：user-service.ts）
- **数据库表名**：PascalCase（如：User、TeamMember）

#### Git 规范

- **分支命名**：
  - feature/功能名称（如：feature/task-drag）
  - fix/修复内容（如：fix/login-error）
  - refactor/重构内容（如：refactor/auth-module）

- **提交信息**：
  - feat: 新功能
  - fix: 修复 bug
  - refactor: 重构
  - docs: 文档更新
  - style: 代码格式调整
  - test: 测试相关
  - chore: 构建/工具相关

### 9.2 API 规范

#### RESTful API 设计

- 使用名词复数形式（如：/api/boards）
- 使用 HTTP 方法表示操作：
  - GET：查询
  - POST：创建
  - PUT：更新
  - DELETE：删除

#### 响应格式

```json
{
  "success": true,
  "data": {},
  "message": "操作成功"
}
```

#### 错误格式

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "参数验证失败",
    "details": []
  }
}
```

### 9.3 数据库规范

- 所有表都有主键（id: UUID）
- 所有表都有 createdAt 和 updatedAt 字段
- 使用软删除（isArchived）而非物理删除
- 外键约束使用 ON DELETE CASCADE
- 索引命名：idx_表名_字段名

---

## 十、风险与应对

### 10.1 技术风险

| 风险 | 影响 | 应对措施 |
|------|------|----------|
| 数据库性能瓶颈 | 高 | 早期优化查询、引入缓存、读写分离 |
| WebSocket 连接管理复杂 | 中 | 使用 Socket.io 库、连接池管理 |
| 支付集成复杂 | 中 | 使用成熟 SDK、充分测试 |
| 文件上传安全 | 中 | 文件类型验证、大小限制、OSS 安全配置 |

### 10.2 业务风险

| 风险 | 影响 | 应对措施 |
|------|------|----------|
| 竞品压力（Trello、Notion） | 高 | 专注小型团队，简化功能，降低学习成本 |
| 用户付费意愿低 | 中 | 提供足够价值的 Pro 功能，优化定价策略 |
| 用户增长过快 | 中 | 提前规划扩展方案，监控性能指标 |

### 10.3 运维风险

| 风险 | 影响 | 应对措施 |
|------|------|----------|
| 服务器故障 | 高 | 多实例部署、负载均衡、自动故障转移 |
| 数据丢失 | 高 | 每日自动备份、异地备份、恢复测试 |
| 安全漏洞 | 高 | 定期安全审计、依赖更新、渗透测试 |

---

**文档版本**：v1.0  
**创建日期**：2025-01-XX  
**最后更新**：2025-01-XX