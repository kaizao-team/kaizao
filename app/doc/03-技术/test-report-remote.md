# API 远程服务器测试报告

> 测试日期：2026-03-23 23:23
> 测试环境：阿里云 ECS（47.236.165.75），Alibaba Cloud Linux 3
> 服务端口：39527
> 容器版本：kaizao-server:latest / mysql:8.0 / redis:7-alpine
> 测试方式：SSH 到远程服务器执行 `test_api.py`，目标 `http://localhost:39527`

## 2026-03-26 复核结论

- 远端登录接口当前仍使用旧字段 `code`；仅传 `sms_code` 会返回 `400 参数校验失败`，同时传 `code + sms_code` 可正常登录。
- 远端 `POST /api/v1/projects/draft` 返回 `draft_id`，不是完整项目对象。
- 远端不存在 `POST /api/v1/projects/:uuid/publish`，会返回 `404 page not found`。
- 需求方四步引导在远端需按兼容路径执行：
  1. `PUT /api/v1/users/me`
  2. `POST /api/v1/projects/draft`
  3. `PUT /api/v1/projects/:draft_id`
  4. `POST /api/v1/projects`
- 以上兼容链路已于 2026-03-26 实测通过，最终发布项目状态为 `2`。
- 专家引导补充验证已于 2026-03-26 实测通过：
  1. `PUT /api/v1/users/me` 写入 `role=2`、昵称、报价、排期
  2. `PUT /api/v1/users/me/skills` 返回 `200 / 技能更新成功`
  3. `PUT /api/v1/users/me` 写入 `bio`
- 当前现网现象：`PUT /api/v1/users/me/skills` 成功后，`GET /api/v1/users/me` 的 `skills` 仍为空数组，技能回显链路待后端进一步确认。

## 2026-03-26 专家引导补充验证

| # | 接口 | 方法 | 路径 | 结果 |
|---|------|------|------|------|
| E1 | 发送短信验证码 | POST | `/api/v1/auth/sms-code` | ✓ PASS |
| E2 | 登录（`code + sms_code`） | POST | `/api/v1/auth/login` | ✓ PASS |
| E3 | 更新专家基础资料 | PUT | `/api/v1/users/me` | ✓ PASS |
| E4 | 更新专家技能 | PUT | `/api/v1/users/me/skills` | ✓ PASS |
| E5 | 更新专家简介 | PUT | `/api/v1/users/me` | ✓ PASS |
| E6 | 回读当前用户资料 | GET | `/api/v1/users/me` | ✓ PASS（`skills` 未回显） |

## 测试结果：17/17 全部通过

| # | 接口 | 方法 | 路径 | 结果 |
|---|------|------|------|------|
| 1.1 | 发送短信验证码 | POST | `/api/v1/auth/sms-code` | ✓ PASS |
| 1.2a | 登录（错误验证码） | POST | `/api/v1/auth/login` | ✓ PASS（返回 10003） |
| 1.2b | 登录（正确验证码/自动注册） | POST | `/api/v1/auth/login` | ✓ PASS |
| 1.3 | 刷新 Token | POST | `/api/v1/auth/refresh` | ✓ PASS |
| 2.1 | 获取当前用户信息 | GET | `/api/v1/users/me` | ✓ PASS |
| 2.2 | 更新用户信息 | PUT | `/api/v1/users/me` | ✓ PASS |
| 3.1 | 创建项目（发布） | POST | `/api/v1/projects` | ✓ PASS |
| 3.1b | 创建项目（第二个） | POST | `/api/v1/projects` | ✓ PASS |
| 3.2 | 获取项目列表 | GET | `/api/v1/projects` | ✓ PASS |
| 3.3 | 获取项目详情 | GET | `/api/v1/projects/:id` | ✓ PASS |
| 4.1 | 需求方首页数据 | GET | `/api/v1/home/demander` | ✓ PASS |
| 4.2 | 专家首页数据 | GET | `/api/v1/home/expert` | ✓ PASS |
| 5.1 | 需求广场列表 | GET | `/api/v1/market/projects` | ✓ PASS |
| 5.2 | 需求广场（分类筛选） | GET | `/api/v1/market/projects?category=app` | ✓ PASS |
| 5.3 | 需求广场（预算排序） | GET | `/api/v1/market/projects?sort=budget_desc` | ✓ PASS |
| 6.1 | 退出登录 | POST | `/api/v1/auth/logout` | ✓ PASS |
| 6.2 | 无 Token 访问 | GET | `/api/v1/users/me` | ✓ PASS（返回 10008） |

## 服务器状态

| 容器 | 状态 | 端口映射 |
|------|------|----------|
| kaizao-server | Up (healthy) | 0.0.0.0:39527 → 8080 |
| kaizao-mysql | Up (healthy) | 127.0.0.1:3306（仅内部） |
| kaizao-redis | Up (healthy) | 127.0.0.1:6379（仅内部） |

## 部署信息

- **服务器**: 阿里云 ECS，3.5GB 内存，49GB 磁盘
- **OS**: Alibaba Cloud Linux 3.2104 U12
- **Docker**: 26.1.3 / Compose v2.27.0
- **镜像大小**: 23.4MB（本地 WSL 构建后传输）
- **运行模式**: release
- **外网访问**: `http://47.236.165.75:39527`（需阿里云安全组放行 TCP 39527）

## 运行远程测试

```bash
# 将测试脚本传到服务器执行
scp api/test_api.py kaizao:~/test_api.py
ssh kaizao 'python3 ~/test_api.py --base http://localhost:39527 --redis-password redis_prod_2026'

# 安全组放行后，也可本地直接测试
python3 api/test_api.py --base http://47.236.165.75:39527
```
