# 开造 VCC - 部署指南

## 前置要求

- Docker 24.0+
- Docker Compose v2.20+
- 至少 8GB 可用内存
- 至少 20GB 可用磁盘空间

## 快速启动

```bash
cd deploy

# 1. 复制环境变量模板并编辑
cp .env.example .env
# 编辑 .env 文件，至少修改以下项：
#   - POSTGRES_PASSWORD
#   - REDIS_PASSWORD
#   - MINIO_ROOT_PASSWORD
#   - JWT_SECRET
#   - LLM API Keys (按需)

# 2. 一键启动所有服务
docker-compose up -d

# 3. 查看服务状态
docker-compose ps

# 4. 等待所有服务健康 (约2-3分钟)
# 可运行健康检查脚本
bash healthcheck.sh

# 5. 访问服务
# Web界面: http://localhost
# API接口: http://localhost/api/v1/
# AI Agent: http://localhost/ai/
# MinIO控制台: http://localhost:9001
```

## 服务端口清单

| 服务 | 容器端口 | 默认映射端口 | 说明 |
|------|---------|-------------|------|
| Nginx | 80/443 | 80/443 | 反向代理入口 |
| Go Server | 8080 | 8080 | 后端API |
| AI Agent | 8000 | 8000 | Python AI服务 |
| PostgreSQL | 5432 | 5432 | 核心数据库 |
| Redis | 6379 | 6379 | 缓存/队列 |
| Elasticsearch | 9200 | 9200 | 全文搜索 |
| Milvus | 19530 | 19530 | 向量数据库 |
| MinIO Console | 9001 | 9001 | 对象存储管理 |

## 常用命令

```bash
# 查看日志
docker-compose logs -f server       # Go后端日志
docker-compose logs -f ai-agent     # AI Agent日志
docker-compose logs -f nginx        # Nginx日志

# 重启单个服务
docker-compose restart server

# 停止所有服务 (保留数据)
docker-compose down

# 停止并删除所有数据卷 (危险操作)
docker-compose down -v

# 重建单个服务
docker-compose up -d --build server

# 进入容器调试
docker exec -it vcc-postgres psql -U vibebuild -d vibebuild
docker exec -it vcc-redis redis-cli -a <密码>
```

## 数据备份

```bash
# PostgreSQL 备份
docker exec vcc-postgres pg_dump -U vibebuild vibebuild > backup_$(date +%Y%m%d).sql

# PostgreSQL 恢复
docker exec -i vcc-postgres psql -U vibebuild vibebuild < backup_20260322.sql

# Redis 备份 (RDB文件在 redis_data 卷中)
docker cp vcc-redis:/data/dump.rdb ./redis_backup.rdb
```

## 故障排查

1. **服务启动失败**: 检查 `docker-compose logs <服务名>` 输出
2. **数据库连接失败**: 确认 POSTGRES_PASSWORD 在 .env 中已设置
3. **Milvus 启动慢**: 首次启动需要约90秒，请耐心等待
4. **端口冲突**: 修改 .env 中对应的端口映射
5. **内存不足**: Elasticsearch 和 Milvus 各需要至少 1GB 内存
