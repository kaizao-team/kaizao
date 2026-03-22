# 开造 VCC (VibeBuild Creative Community)

AI驱动的软件外包撮合平台 -- 连接需求方与开发者，用AI拆解需求、管理项目、保障交付。

## 架构概览

```
                         +-----------+
                         |  Flutter  |
                         | App/Web   |
                         +-----+-----+
                               |
                         +-----v-----+
                         |   Nginx   |
                         | (反向代理) |
                         +--+--+--+--+
                            |  |  |
              +-------------+  |  +--------------+
              |                |                 |
        +-----v-----+  +------v------+  +-------v-------+
        | /api/*    |  | /ws/*       |  | /ai/*         |
        | Go Server |  | WebSocket   |  | Python        |
        | (Gin)     |  | Gateway(Go) |  | AI Agent      |
        | Port:8080 |  | Port:8080   |  | (FastAPI)     |
        +-----+-----+  +------+------+  | Port:8000     |
              |                |         +---+---+---+---+
              |                |             |   |   |
     +--------+--------+      |      +------+   |   +------+
     |        |        |      |      |          |          |
+----v--+ +---v---+ +--v--+  |  +---v----+ +---v---+ +----v-----+
|Postgre| | Redis | | OSS |  |  | Milvus | | Redis | |Elastic-  |
|SQL 16 | |  7.x  | |(CDN)|  |  |  2.3   | |  7.x  | |search 8  |
+-------+ +-------+ +-----+  |  +--------+ +-------+ +----------+
                              |
                        +-----v-----+
                        | Redis     |
                        | Pub/Sub   |
                        | (跨节点)   |
                        +-----------+
```

## 技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| 移动端 | Flutter 3.x + Dart | 双端一套代码，Riverpod状态管理 |
| 后端 | Go 1.22+ + Gin | 微服务架构，高并发WebSocket |
| AI Agent | Python 3.11+ + LangGraph | 需求分析/项目管理/质量检查Agent |
| 数据库 | PostgreSQL 16 | 核心业务数据，ACID事务保障 |
| 缓存 | Redis 7 | 缓存/会话/消息队列(Streams) |
| 搜索 | Elasticsearch 8 | 全文检索 + BM25 |
| 向量库 | Milvus 2.3 | RAG知识库，语义检索 |
| 部署 | Docker + K8s(ACK) | 容器化编排 |
| 网关 | Nginx / Kong | 反向代理 + 限流 |

## 项目结构

```
vibebuild/
├── Makefile                    # 顶层构建命令
├── README.md                   # 本文件
├── deploy/                     # 部署配置
│   ├── docker-compose.yml      # Docker编排（一键启动）
│   ├── .env.example            # 环境变量模板
│   ├── healthcheck.sh          # 健康检查脚本
│   ├── nginx/
│   │   └── nginx.conf          # Nginx反向代理配置
│   └── init-db/
│       └── 01_create_tables.sql # 数据库DDL + 种子数据
├── vibebuild-app/              # Flutter APP (待创建)
├── vibebuild-server/           # Go 后端服务 (待创建)
├── vibebuild-ai-agent/         # Python AI Agent (待创建)
├── vibebuild-common/           # Go 公共库 (待创建)
├── vibebuild-proto/            # gRPC Proto定义 (待创建)
└── vibebuild-docs/             # 技术文档 (待创建)
```

## 快速开始

### 环境要求

- Docker 24.0+
- Docker Compose v2.20+
- Make
- 至少 8GB 可用内存

### 一键启动

```bash
# 克隆项目
git clone <repo-url> vibebuild && cd vibebuild

# 配置环境变量
cp deploy/.env.example deploy/.env
# 编辑 deploy/.env，填入数据库密码、JWT密钥等

# 启动全部服务
make up

# 检查服务状态
make health

# 查看日志
make logs
```

### 常用命令

```bash
make help       # 查看所有可用命令
make dev        # 启动开发环境（前台，带日志输出）
make up         # 启动所有服务（后台）
make down       # 停止所有服务
make logs       # 实时查看日志
make build      # 构建所有Docker镜像
make migrate    # 运行数据库迁移
make test       # 运行所有测试
make health     # 服务健康检查
make db-shell   # 进入数据库终端
make db-backup  # 备份数据库
make ps         # 查看容器状态
make stats      # 查看资源使用
```

## 核心业务流程

```
需求方发布需求 --> AI分析需求 --> 生成PRD+EARS卡片
    --> 供给方投标 --> 智能撮合匹配 --> 创建项目
    --> 担保支付 --> 任务看板管理 --> 里程碑验收
    --> AI质量检查 --> 释放款项 --> 双向评价
```

## API文档

- REST API基础路径: `/api/v1/`
- AI Agent路径: `/ai/`
- WebSocket: `/ws/`
- 认证方式: JWT Bearer Token

## 开发指南

### Go后端开发

```bash
cd vibebuild-server
go mod tidy
go run cmd/server/main.go

# 运行测试
go test -race -cover ./...
```

### AI Agent开发

```bash
cd vibebuild-ai-agent
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000

# 运行测试
pytest -v
```

### Flutter APP开发

```bash
cd vibebuild-app
flutter pub get
flutter run

# 运行测试
flutter test
```

## 环境说明

| 环境 | 分支 | 用途 |
|------|------|------|
| DEV | develop | 日常开发调试 |
| STG | release/* | 集成测试、UAT |
| PROD | main | 正式生产环境 |

## License

Proprietary - All rights reserved.
