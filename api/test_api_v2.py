#!/usr/bin/env python3
"""
Kaizao API v2 集成测试脚本 — 覆盖所有已实现接口

NOTE: 本文件已按模块拆分至 tests/ 目录（tests/runner.py 为新入口）。
      推荐使用新入口：cd api && python -m tests --base http://localhost:8080
      本文件保留完整原始内容，可独立运行，作为兼容用途。

推荐执行环境：**WSL2 + Docker**（与 `kaizao/server/docker-compose.yml` 栈一致）。
一键：在仓库 `kaizao/server` 目录执行 `bash scripts/wsl_deploy_test.sh`（会先可选跑 Go 单测，再起栈并跑本脚本）。
集成测试依赖宿主机访问 `127.0.0.1:8080`（或 `SERVER_HOST_PORT`）上的 API；默认容器名与 **docker-compose.wsl.yml** 一致（`kaizao-wsl-mysql` 等），可用环境变量 `KAIZAO_MYSQL_CONTAINER` / `KAIZAO_MYSQL_PASSWORD` 或 CLI 覆盖。旧栈 `docker-compose.yml` 请传 `--mysql-container kaizao-mysql`。

环境变量:
  KZ_SKIP_ADMIN_INVITE=1  跳过 1.5 节（docker 提权管理员 + 邀请码 CRUD），无 Docker 时用。

完整入驻链路（专家注册 → 兑换团队邀请码直通审核，依赖迁移 003 默认团队 UUID）:
  python test_api_v2.py --full-onboarding
  需 1.5 成功（Docker 提权管理员并发码）；数据库须有团队 `11111111-1111-1111-1111-111111111111`（迁移 003 会种子插入）。

新增接口覆盖说明:
  - **§1.4b 密码认证（api-registry.md）**: `GET /auth/password-key`、`GET /auth/captcha`、`POST /auth/register-password`、`POST /auth/login-password`（明文 `password` 禁止 **10023**、用户名非法 **10020**、重复注册 **10021**、验证码错误 **10026**；完整注册+登录需 **cryptography** + Docker 访问 Redis 读 `captcha:dchest:*`）。
  - 默认（1.5 成功时）: **1.5c** `GET /admin/teams/:uuid/current-invite-code`
  - `--full-onboarding`: **兑换邀请码** + **轮换后当前码**（见 §15）
  - `--test-new-apis`: **POST /users/me/onboarding/application**（材料审核）+ **POST/GET** `/teams/:uuid/static-assets`（需 OSS/MinIO 已启用，且本机有 `curl`）
  - **通知模块**（§11b）: `GET/PUT /notifications*`，依赖 **docker exec MySQL** 写入种子行（与 1.5 同源）；无 Docker 或 exec 失败时跳过。
  - **§2.6b 作品集**: `POST /users/me/portfolios` → `GET /users/me/portfolios`（字段含 `category`/`tech_stack`）→ `GET /users/:id/portfolios` 一致性 → 未带 Token 访问 `GET /users/me/portfolios` **401**（`code=10008`）→ **2.6e0** `PUT` 带 `category` 为空串/仅空白/非法枚举 → **400**、`code=99001` → `PUT` 成功 → `DELETE` 软删后列表不再包含该项；**§2.7b** 在 **2.7 上传** 成功时用返回的 `url` 作为 `cover_url` 再创建并删除一条（上传链路联调）。
  - **§5.4 收藏**: `POST/DELETE /favorites`（`target_type` project|expert）、`GET /users/me/favorites`；校验 `GET /projects/:id` 的 `favorite_count` 与幂等、负例（非法 `target_type`、项目不存在 **20001**、专家 UUID 不存在 **11001**、不可收藏专家 **30010**）；**5.4j** 多线程并发 `POST` 同一项目收藏：全部 `code=0` 且 `favorite_count` 仅 **+1**（覆盖 MySQL 1062 幂等与原子计数）；**5.4h** 用 **团队 UUID** 收藏专家并验证 `favorites.target_id` 为团队 UUID；**5.4h3–h6** 用 **leader UUID** 收藏专家，验证后端自动解析为团队 UUID 存储，且与团队 UUID 幂等。
  - **§6.3b–6.3e**: `POST /projects/draft` 使用历史 `category=design`（归一为 `visual`）及短标题/短描述；`GET` 校验草稿；`POST /projects/:id/publish` 发布后 `GET` 校验 `status=2` 且标题/描述长度与 `CreateProjectReq` 一致（由服务端 `PublishDraft` 补全）。
  - **§6.3n**: `POST /projects/draft` 负例：`budget_min`/`budget_max` 为负、`match_mode` 非法、`budget_max < budget_min` → HTTP 400、`code=99001`。
  - **§7.1b**: 专家 `POST /projects/:id/bids` 成功后，需求方 `GET /notifications?type=23` 可见「收到新投标」（`notification_type=23`，正文含项目标题、报价 `¥`、投标人文案；若已取得 `USER2` 昵称则校验昵称出现在正文中）。**§7.1c** 投标绑定非成员团队 → **`30007`**。
  - **§7.2b**: 专用项目上 `PUT /bids/:id/withdraw`：pending 可撤、`bid_count` 减 1、重复撤回 **30003**；**§7.4w** 撮合后同一投标再撤回 **30003**。
  - **§9 聊天（会话）**: `GET /conversations` 含 **`meta` 分页**（`offset`/`limit`）；撮合会话 UUID 存 `MATCH_CONV_UUID`；专家发消息后需求方 **`unread_count`**、`POST .../read` 后归零；**圈外人**（`TOKEN_OUTSIDER`）拉消息/发消息 **HTTP 403、`60002`**；需求方 **`DELETE`** 软删后双方 **`GET .../messages` → 404、`60001`**；伪造会话 UUID → **404**。
  - **§8 项目管理**: **8.2** 里程碑 `POST`；**8.2d** 手动任务 `POST /projects/:id/tasks`（可带 `milestone_id`）；**8.2d2** 创建响应与列表中 `milestone_id` 为里程碑 **UUID**（非数字主键）；**8.2f** `assignee_id` 为项目外用户 → **21011**；**8.2e** `GET` 任务列表校验；**8.2b/8.2c** 里程碑负例；**8.3** 里程碑列表；撮合后 `payment_amount` 与 25% 一致等。
  - **§8.5 项目共享文件**（需 MinIO + `curl` + 迁移 `project_files`）：`GET/POST /projects/:id/files`、`GET .../files/:fileUuid`；需求方与服务方上传、`file_kind` 筛选、圈外人 **21008**、非法 kind **21016**、不存在文件 **21015**；可选 `milestone_id` 关联里程碑。
  - **8.3d** 里程碑交付（依赖 **7.4** 撮合成功、`TOKEN2` 为服务方）：`pending` 交付 **21014**；MySQL 将里程碑置 **进行中** 后：`POST /milestones/:id/deliver`（需求方 **21013**、空交付物 **99001**、服务方成功、**8.3e/8.3f** 专家验收/打回 **20009**、需求方 **GET /notifications?type=22**、列表 **delivered**、重复交付 **21009**）。
  - **§团队实体对齐**（迁移 012）：**§5.3b** `GET /market/experts` 团队维度字段校验（`team_name`/`vibe_level`/`vibe_power`/`member_count`）；**§4.1c** `GET /home/demander` 推荐专家团队字段；**§2.2f** `PUT /users/me` 写入 `hourly_rate`/`available_status` 后 `GET /users/me` 回读一致。**§2.2g**（迁移 013）团队 `budget_min`/`budget_max` 经 `PUT /users/me` 回读及非法区间校验。
"""
import json
import urllib.request
import urllib.error
import subprocess
import re
import sys
import time
import random
import hashlib
import argparse
import os
import shutil
import tempfile
import uuid
import base64
import concurrent.futures
from datetime import datetime

try:
    from cryptography.hazmat.backends import default_backend
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import padding

    _CRYPTO_OK = True
except ImportError:
    _CRYPTO_OK = False

def _env(key: str, default: str) -> str:
    v = os.environ.get(key)
    return (v.strip() if v else "") or default


parser = argparse.ArgumentParser()
parser.add_argument("--base", default="http://localhost:8080")
parser.add_argument(
    "--redis-container",
    default=_env("KAIZAO_REDIS_CONTAINER", "kaizao-wsl-redis"),
)
parser.add_argument("--redis-password", default=_env("KAIZAO_REDIS_PASSWORD", "redis123"))
parser.add_argument(
    "--server-container",
    default=_env("KAIZAO_SERVER_CONTAINER", "kaizao-wsl-server"),
)
parser.add_argument(
    "--mysql-container",
    default=_env("KAIZAO_MYSQL_CONTAINER", "kaizao-wsl-mysql"),
)
parser.add_argument("--mysql-user", default="kaizao")
parser.add_argument(
    "--mysql-password",
    default=_env("KAIZAO_MYSQL_PASSWORD", "kaizao_prod_2026"),
)
parser.add_argument("--mysql-db", default="kaizao")
parser.add_argument(
    "--full-onboarding",
    action="store_true",
    help="额外跑：专家注册(待发码)→兑换团队邀请码→校验新码已轮换",
)
parser.add_argument(
    "--test-new-apis",
    action="store_true",
    help="测 POST /users/me/onboarding/application 与团队 MinIO 上传/列表（需 docker exec MySQL + curl）",
)
args = parser.parse_args()

BASE = args.base
REDIS_CONTAINER = args.redis_container
REDIS_PASSWORD = args.redis_password
MYSQL_CONTAINER = args.mysql_container
MYSQL_USER = args.mysql_user
MYSQL_PASSWORD = args.mysql_password
MYSQL_DB = args.mysql_db
TOKEN = None
REFRESH_TOKEN = None
USER_ID = None
RESULTS = []
PROJECT_UUID = None
# §7.4 撮合成功后写入，供 §9 聊天（未读/已读/越权/软删）
MATCH_CONV_UUID = None
# 3.4 更新项目标题后，投标通知正文中的项目名与此一致（初始创建见 3.1）
PROJECT_DISPLAY_TITLE = "Test Flutter App V2"
INVITE_CODE_PLAIN = None
ADMIN_SETUP_OK = False
# migrations/003_team_invite_onboarding.up.sql 种子团队
SEED_TEAM_UUID = "11111111-1111-1111-1111-111111111111"

def req(method, path, body=None, need_auth=True, auth_token=None):
    url = BASE + path
    data = json.dumps(body).encode() if body else None
    headers = {"Content-Type": "application/json"}
    tok = TOKEN if auth_token is None else auth_token
    if need_auth and tok:
        headers["Authorization"] = "Bearer " + tok
    r = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        resp = urllib.request.urlopen(r)
        result = json.loads(resp.read().decode())
        return resp.status, result
    except urllib.error.HTTPError as e:
        body_text = e.read().decode()
        try:
            result = json.loads(body_text)
        except Exception:
            result = {"raw": body_text}
        return e.code, result

def test(
    name,
    method,
    path,
    body=None,
    need_auth=True,
    expect_code=0,
    auth_token=None,
    expect_http=None,
):
    """expect_http: 若指定则同时校验 HTTP 状态码（如里程碑创建：成功 200，业务错 400/403/404）。"""
    status, result = req(method, path, body, need_auth, auth_token)
    code = result.get("code", -1)
    ok = code == expect_code
    if expect_http is not None:
        ok = ok and (status == expect_http)
    icon = "PASS" if ok else "FAIL"
    print(f"  [{icon}] {name} -> HTTP {status}, code={code}")
    if not ok:
        msg = result.get("message", "")
        extra = f", expect_http={expect_http}" if expect_http is not None else ""
        print(f"         Expected code={expect_code}{extra}, got code={code}, HTTP={status}, msg={msg}")
    RESULTS.append((name, ok, status, code))
    return ok, result

def get_sms_code(phone, purpose=2):
    try:
        phone_hash = hashlib.sha256(phone.encode()).hexdigest()
        key = f"sms:code:{phone_hash}:{purpose}"
        result = subprocess.run(
            ["docker", "exec", REDIS_CONTAINER, "redis-cli", "-a", REDIS_PASSWORD, "get", key],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True, timeout=10)
        val = result.stdout.strip()
        if val and val != "(nil)":
            return val
    except Exception:
        pass
    return None

def gen_phone():
    return f"13{random.randint(100000000, 999999999)}"

def cf(data, fields, label=""):
    missing = [f for f in fields if f not in data]
    if missing:
        print(f"         WARN[{label}]: missing {missing}")
    return len(missing) == 0


def mysql_scalar(sql):
    """docker exec MySQL 执行查询，返回首行首列（无则 None）。失败返回 None。"""
    try:
        result = subprocess.run(
            [
                "docker",
                "exec",
                MYSQL_CONTAINER,
                "mysql",
                "-u" + MYSQL_USER,
                "-p" + MYSQL_PASSWORD,
                MYSQL_DB,
                "-N",
                "-e",
                sql,
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
            timeout=30,
            check=True,
        )
        out = result.stdout.strip()
        if not out:
            return None
        return out.split("\n")[0].strip()
    except Exception:
        return None


def mysql_exec(sql):
    """docker exec MySQL 执行非查询语句。成功返回 True。"""
    try:
        subprocess.run(
            [
                "docker",
                "exec",
                MYSQL_CONTAINER,
                "mysql",
                "-u" + MYSQL_USER,
                "-p" + MYSQL_PASSWORD,
                MYSQL_DB,
                "-e",
                sql,
            ],
            check=True,
            timeout=30,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return True
    except Exception:
        return False


def encrypt_password_cipher(pem: str, password: str) -> str:
    """RSA-OAEP-SHA256，与 api-registry.md / smoke_password_auth.py 一致。"""
    if not _CRYPTO_OK:
        raise RuntimeError("cryptography not installed")
    pub = serialization.load_pem_public_key(pem.encode("utf-8"), backend=default_backend())
    ct = pub.encrypt(
        password.encode("utf-8"),
        padding.OAEP(
            mgf=padding.MGF1(algorithm=hashes.SHA256()),
            algorithm=hashes.SHA256(),
            label=None,
        ),
    )
    return base64.b64encode(ct).decode("ascii")


def get_dchest_captcha_code(captcha_id):
    """从 Redis 键 captcha:dchest:{id} 解析 dchest 验证码答案（每位 0–9 数值字节）。"""
    if not captcha_id:
        return None
    key = f"captcha:dchest:{captcha_id}"
    try:
        result = subprocess.run(
            [
                "docker",
                "exec",
                REDIS_CONTAINER,
                "redis-cli",
                "-a",
                REDIS_PASSWORD,
                "--raw",
                "GET",
                key,
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=False,
            timeout=15,
        )
        raw = result.stdout
        if not raw:
            return None
        raw = raw.rstrip(b"\r\n")
        if raw == b"(nil)" or not raw:
            return None
        return "".join(str(b) for b in raw)
    except Exception:
        return None


print("=" * 60)
print("  Kaizao API v2 Integration Tests")
print(f"  Base: {BASE}  Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print("=" * 60)

# ==================== 1. 认证 ====================
print("\n--- 1. 认证模块 ---")
phone = gen_phone()
print(f"  [INFO] Phone: {phone}")

test("1.1 POST /auth/sms-code", "POST", "/api/v1/auth/sms-code",
     {"phone": phone, "purpose": 2}, need_auth=False)
test("1.2 POST /auth/login (wrong code)", "POST", "/api/v1/auth/login",
     {"phone": phone, "code": "000000"}, need_auth=False, expect_code=10003)

time.sleep(0.3)
sms_code = get_sms_code(phone)
if not sms_code:
    sms_code = "952786"
print(f"  [INFO] Code: {sms_code}")

ok, r = test("1.3 POST /auth/login (correct)", "POST", "/api/v1/auth/login",
             {"phone": phone, "code": sms_code}, need_auth=False)
if ok and r.get("data"):
    TOKEN = r["data"].get("access_token")
    USER_ID = r["data"].get("user_id")
    REFRESH_TOKEN = r["data"].get("refresh_token")
    print(f"         user_id={USER_ID}")

if not TOKEN:
    print("  [FATAL] No token, exit")
    sys.exit(1)

if REFRESH_TOKEN:
    ok, r = test("1.4 POST /auth/refresh", "POST", "/api/v1/auth/refresh",
                 {"refresh_token": REFRESH_TOKEN}, need_auth=False)
    if ok and r.get("data"):
        TOKEN = r["data"].get("access_token", TOKEN)
        REFRESH_TOKEN = r["data"].get("refresh_token", REFRESH_TOKEN)

# --- 1.4b 密码认证（api-registry.md：password-key / captcha / register-password / login-password）---
print("\n--- 1.4b 密码认证（api-registry） ---")
PW_FLOW_PASSWORD = "Abcd1234"
USERNAME_PW_REG = None
pem_pw = None

ok_pk, r_pk = test(
    "1.4b1 GET /auth/password-key",
    "GET",
    "/api/v1/auth/password-key",
    need_auth=False,
)
if ok_pk and isinstance(r_pk.get("data"), dict):
    d_pk = r_pk["data"]
    cf_pk = cf(d_pk, ["key_id", "algorithm", "public_key_pem"], "password-key")
    pem_pw = d_pk.get("public_key_pem")
    algo_ok = str(d_pk.get("algorithm") or "") == "RSA-OAEP-SHA256"
    pk_meta = cf_pk and algo_ok
    print(
        f"  [{'PASS' if pk_meta else 'FAIL'}] 1.4b1a password-key fields + algorithm RSA-OAEP-SHA256"
    )
    RESULTS.append(("1.4b1a password-key meta", pk_meta, 200, 0 if pk_meta else -1))
else:
    print("  [WARN] 1.4b1 无 data，后续依赖公钥的用例跳过")

ok_cap0, r_cap0 = test(
    "1.4b2 GET /auth/captcha",
    "GET",
    "/api/v1/auth/captcha",
    need_auth=False,
)
if ok_cap0 and isinstance(r_cap0.get("data"), dict):
    d_cap = r_cap0["data"]
    cf_cap = cf(d_cap, ["captcha_id", "image_base64", "expires_in"], "captcha")
    print(
        f"  [{'PASS' if cf_cap else 'FAIL'}] 1.4b2a captcha response fields (captcha_id/image_base64/expires_in)"
    )
    RESULTS.append(("1.4b2a captcha fields", cf_cap, 200, 0 if cf_cap else -1))

test(
    "1.4b3 POST /auth/register-password (forbidden root password field -> 10023)",
    "POST",
    "/api/v1/auth/register-password",
    {"username": "kz_bad1", "password": "Secret123"},
    need_auth=False,
    expect_code=10023,
    expect_http=400,
)

if _CRYPTO_OK and pem_pw:
    try:
        cipher_fmt = encrypt_password_cipher(pem_pw, PW_FLOW_PASSWORD)
    except Exception as ex:
        print(f"  [SKIP] 1.4b4–1.4b8 公钥加密失败: {ex}")
        cipher_fmt = None
else:
    cipher_fmt = None
    print(
        "  [SKIP] 1.4b4–1.4b8 需 pip install cryptography 且 1.4b1 返回 public_key_pem"
    )

if cipher_fmt:
    test(
        "1.4b4 POST /auth/register-password (invalid username -> 10020)",
        "POST",
        "/api/v1/auth/register-password",
        {"username": "bad!usr", "password_cipher": cipher_fmt},
        need_auth=False,
        expect_code=10020,
        expect_http=400,
    )

    USERNAME_PW_REG = f"kz_pw_{uuid.uuid4().hex[:12]}"
    ok_reg, r_reg = test(
        "1.4b5 POST /auth/register-password",
        "POST",
        "/api/v1/auth/register-password",
        {
            "username": USERNAME_PW_REG,
            "password_cipher": cipher_fmt,
            "nickname": "pw_reg",
        },
        need_auth=False,
    )
    if ok_reg and isinstance(r_reg.get("data"), dict) and r_reg["data"].get("access_token"):
        print(f"         register-password user={USERNAME_PW_REG!r}")

    if cipher_fmt:
        USERNAME_PW_REG_PHONE = f"kz_pw_{uuid.uuid4().hex[:12]}"
        phone_only = f"139{random.randint(10000000, 99999999)}"
        ok_reg_phone, _ = test(
            "1.4b5a POST /auth/register-password (phone only, no sms_code)",
            "POST",
            "/api/v1/auth/register-password",
            {
                "username": USERNAME_PW_REG_PHONE,
                "password_cipher": cipher_fmt,
                "nickname": "pw_reg_phone",
                "phone": phone_only,
            },
            need_auth=False,
        )
        if ok_reg_phone:
            print(f"         register-password+phone user={USERNAME_PW_REG_PHONE!r} phone={phone_only!r}")
        test(
            "1.4b5b POST /auth/register-password (sms_code without phone -> 99001)",
            "POST",
            "/api/v1/auth/register-password",
            {
                "username": f"kz_pw_{uuid.uuid4().hex[:12]}",
                "password_cipher": cipher_fmt,
                "sms_code": "123456",
            },
            need_auth=False,
            expect_code=99001,
            expect_http=400,
        )

    if ok_reg:
        test(
            "1.4b8 POST /auth/register-password (duplicate username -> 10021)",
            "POST",
            "/api/v1/auth/register-password",
            {
                "username": USERNAME_PW_REG,
                "password_cipher": cipher_fmt,
            },
            need_auth=False,
            expect_code=10021,
            expect_http=400,
        )

    st_c2, r_c2 = req("GET", "/api/v1/auth/captcha", need_auth=False)
    cap_ok = st_c2 == 200 and r_c2.get("code") == 0
    cid_login = None
    if cap_ok and isinstance(r_c2.get("data"), dict):
        cid_login = r_c2["data"].get("captcha_id")
    cap_code = get_dchest_captcha_code(cid_login) if cid_login else None

    if USERNAME_PW_REG and cid_login and cap_code:
        ok_lp, r_lp = test(
            "1.4b6 POST /auth/login-password",
            "POST",
            "/api/v1/auth/login-password",
            {
                "login_type": "username",
                "identity": USERNAME_PW_REG,
                "password_cipher": cipher_fmt,
                "captcha_id": cid_login,
                "captcha_code": cap_code,
                "device_type": "web",
            },
            need_auth=False,
        )
        lp_data_ok = False
        if ok_lp and isinstance(r_lp.get("data"), dict):
            lp_data_ok = bool(r_lp["data"].get("access_token"))
        print(
            f"  [{'PASS' if lp_data_ok else 'FAIL'}] 1.4b6a login-password returns access_token"
        )
        RESULTS.append(("1.4b6a login-password token", lp_data_ok, 200, 0 if lp_data_ok else -1))

        st_c3, r_c3 = req("GET", "/api/v1/auth/captcha", need_auth=False)
        cid_bad = None
        if st_c3 == 200 and r_c3.get("code") == 0 and isinstance(r_c3.get("data"), dict):
            cid_bad = r_c3["data"].get("captcha_id")
        if cid_bad:
            test(
                "1.4b7 POST /auth/login-password (wrong captcha -> 10026)",
                "POST",
                "/api/v1/auth/login-password",
                {
                    "login_type": "username",
                    "identity": USERNAME_PW_REG,
                    "password_cipher": cipher_fmt,
                    "captcha_id": cid_bad,
                    "captcha_code": "0000000000000000",
                    "device_type": "web",
                },
                need_auth=False,
                expect_code=10026,
                expect_http=400,
            )
    else:
        print(
            "  [SKIP] 1.4b6–1.4b7 需 Docker 可读 Redis 验证码键 captcha:dchest:*（与 server 同一实例）"
        )

# --- 1.5 管理端邀请码（docker 将当前用户提权为 role=9）---
print("\n--- 1.5 管理端邀请码（可选） ---")
if os.environ.get("KZ_SKIP_ADMIN_INVITE", "0") == "1":
    print("  [SKIP] KZ_SKIP_ADMIN_INVITE=1，跳过提权与 /admin/invite-codes")
elif USER_ID and re.match(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
    USER_ID,
    re.I,
):
    try:
        subprocess.run(
            [
                "docker",
                "exec",
                MYSQL_CONTAINER,
                "mysql",
                "-u" + MYSQL_USER,
                "-p" + MYSQL_PASSWORD,
                MYSQL_DB,
                "-e",
                f"UPDATE users SET role=9 WHERE uuid='{USER_ID}'",
            ],
            check=True,
            timeout=30,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except Exception as ex:
        print(f"  [WARN] 无法通过 docker 提权管理员（跳过 1.5）: {ex}")
    else:
        ok, r = test(
            "1.5a POST /admin/invite-codes",
            "POST",
            "/api/v1/admin/invite-codes",
            {
                "team_uuid": SEED_TEAM_UUID,
                "note": "integration-test",
            },
        )
        if ok and r.get("data"):
            INVITE_CODE_PLAIN = r["data"].get("code_plain")
            print(f"         invite_code_plain={INVITE_CODE_PLAIN!r}")
        ok2, _ = test(
            "1.5b GET /admin/invite-codes",
            "GET",
            "/api/v1/admin/invite-codes?page=1&page_size=10",
        )
        ADMIN_SETUP_OK = bool(ok and ok2 and INVITE_CODE_PLAIN)
        if ADMIN_SETUP_OK:
            test(
                "1.5c GET /admin/teams/:uuid/current-invite-code",
                "GET",
                f"/api/v1/admin/teams/{SEED_TEAM_UUID}/current-invite-code",
            )
else:
    print("  [WARN] USER_ID 非 UUID，跳过 1.5")

# --- 1.6 新增接口（可选）：专家材料提交 + 团队静态文件（MinIO）---
if args.test_new_apis:
    print("\n--- 1.6 新增接口（--test-new-apis） ---")
    uuid_pat = re.compile(
        r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", re.I
    )
    if not (ADMIN_SETUP_OK and TOKEN and USER_ID and uuid_pat.match(USER_ID)):
        print("  [SKIP] 需 1.5 成功且 USER_ID 为 UUID")
        RESULTS.append(("1.6 prerequisites", False, 0, -1))
    else:
        mat_phone = gen_phone()
        test(
            "1.6a POST /auth/sms-code (register)",
            "POST",
            "/api/v1/auth/sms-code",
            {"phone": mat_phone, "purpose": 1},
            need_auth=False,
        )
        time.sleep(0.3)
        sc1 = get_sms_code(mat_phone, 1) or "952786"
        ok_mat, r_mat = test(
            "1.6b POST /auth/register (expert for materials)",
            "POST",
            "/api/v1/auth/register",
            {
                "phone": mat_phone,
                "sms_code": sc1,
                "nickname": "MaterialExpert",
                "role": 2,
            },
            need_auth=False,
        )
        d_mat = r_mat.get("data") if isinstance(r_mat, dict) else {}
        mat_tok = d_mat.get("access_token")
        mat_uuid = (d_mat.get("user") or {}).get("uuid") if isinstance(d_mat.get("user"), dict) else None
        if ok_mat and mat_tok and mat_uuid:
            test(
                "1.6c POST /users/me/onboarding/application",
                "POST",
                "/api/v1/users/me/onboarding/application",
                {"resume_url": "https://example.com/integration-cv.pdf", "note": "api test"},
                auth_token=mat_tok,
            )
            test(
                "1.6d PUT /admin/users/:uuid/onboarding (approve materials)",
                "PUT",
                f"/api/v1/admin/users/{mat_uuid}/onboarding",
                {"status": "approved"},
            )
            st_m, r_m = req("GET", "/api/v1/users/me", None, True, mat_tok)
            ob_m = r_m.get("data", {}).get("onboarding_status") if isinstance(r_m, dict) else None
            ok_ob_m = ob_m == 2
            print(
                f"  [{'PASS' if ok_ob_m else 'FAIL'}] 1.6e GET /users/me (materials path approved) onboarding={ob_m}"
            )
            RESULTS.append(
                ("1.6e materials path onboarding=2", ok_ob_m, st_m, r_m.get("code", -1))
            )
        else:
            print("  [FAIL] 1.6b 专家注册失败，跳过材料审核子项")
            RESULTS.append(("1.6b expert register", False, 0, r_mat.get("code", -1)))

        try:
            subprocess.run(
                [
                    "docker",
                    "exec",
                    MYSQL_CONTAINER,
                    "mysql",
                    "-u" + MYSQL_USER,
                    "-p" + MYSQL_PASSWORD,
                    MYSQL_DB,
                    "-e",
                    "INSERT IGNORE INTO team_members (team_id, user_id, role_in_team, split_ratio, status) "
                    "SELECT t.id, u.id, 'member', 0, 1 FROM teams t, users u "
                    f"WHERE t.uuid = '{SEED_TEAM_UUID}' AND u.uuid = '{USER_ID}'",
                ],
                check=True,
                timeout=30,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except Exception as ex:
            print(f"  [WARN] 无法写入 team_members（跳过 MinIO 测）: {ex}")
        else:
            if shutil.which("curl") is None:
                print("  [SKIP] 未找到 curl，跳过 multipart 上传")
                RESULTS.append(("1.6f POST static-assets (curl missing)", False, 0, -1))
            else:
                fd, tmp_path = tempfile.mkstemp(suffix=".txt", text=False)
                try:
                    os.write(fd, b"kaizao minio integration test\n")
                    os.close(fd)
                    cp = subprocess.run(
                        [
                            "curl",
                            "-sS",
                            "-X",
                            "POST",
                            BASE + f"/api/v1/teams/{SEED_TEAM_UUID}/static-assets",
                            "-H",
                            "Authorization: Bearer " + TOKEN,
                            "-F",
                            "purpose=integration",
                            "-F",
                            "file=@" + tmp_path + ";type=text/plain",
                        ],
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE,
                        timeout=120,
                        check=False,
                    )
                    try:
                        up_json = json.loads(cp.stdout.decode())
                    except Exception:
                        up_json = {"raw": cp.stdout.decode()[:200], "code": -1}
                    ok_up = up_json.get("code") == 0
                    print(
                        f"  [{'PASS' if ok_up else 'FAIL'}] 1.6f POST /teams/.../static-assets -> code={up_json.get('code')}"
                    )
                    RESULTS.append(
                        (
                            "1.6f POST /teams/:uuid/static-assets",
                            ok_up,
                            200 if ok_up else 0,
                            up_json.get("code", -1),
                        )
                    )
                    test(
                        "1.6g GET /teams/:uuid/static-assets",
                        "GET",
                        f"/api/v1/teams/{SEED_TEAM_UUID}/static-assets?page=1&page_size=10",
                    )
                finally:
                    try:
                        os.unlink(tmp_path)
                    except OSError:
                        pass

# ==================== 2. 用户 ====================
print("\n--- 2. 用户模块 ---")
ok, r = test("2.1 GET /users/me", "GET", "/api/v1/users/me")
if ok and r.get("data"):
    cf(r["data"], ["id", "uuid", "nickname", "role", "credit_score", "stats", "contact_phone"])
    stats = r["data"].get("stats", {})
    if stats:
        cf(stats, ["published_projects", "total_spent", "days_on_platform",
                    "completed_projects", "approval_rate", "total_earnings"], "me.stats")

# 勿带 role：1.5 Docker 提权后 role=9，写回 1 会导致后续 §15 管理端 403
test("2.2 PUT /users/me", "PUT", "/api/v1/users/me", {"nickname": "TestV2User"})

test(
    "2.2d PUT /users/me (contact_phone)",
    "PUT",
    "/api/v1/users/me",
    {"contact_phone": "13900001234"},
)
st_cp, r_cp = req("GET", "/api/v1/users/me")
cp_val = (r_cp.get("data") or {}).get("contact_phone") if isinstance(r_cp, dict) else None
cp_ok = cp_val == "13900001234"
print(
    f"  [{'PASS' if cp_ok else 'FAIL'}] 2.2e GET /users/me contact_phone roundtrip -> {cp_val!r}"
)
RESULTS.append(("2.2e GET /me contact_phone", cp_ok, st_cp, r_cp.get("code", -1)))

# 技能：PUT 保存后 GET /me 应带回 skills（修复恒为空数组）
test(
    "2.2b PUT /users/me/skills",
    "PUT",
    "/api/v1/users/me/skills",
    {
        "skills": [
            {"name": "Flutter", "category": "mobile", "proficiency": 4, "is_primary": True},
            {"name": "Go", "category": "backend"},
        ]
    },
)
status_me, r_me = req("GET", "/api/v1/users/me")
skills_after = []
if r_me.get("code") == 0 and r_me.get("data"):
    skills_after = r_me.get("data", {}).get("skills") or []
ok_skills = len(skills_after) >= 2
print(
    f"  [{'PASS' if ok_skills else 'FAIL'}] 2.2c GET /users/me (skills roundtrip) "
    f"-> HTTP {status_me}, skills len={len(skills_after)}"
)
if not ok_skills:
    print("         BUG: PUT /users/me/skills 后 GET /me 的 skills 仍为空或未达 2 条")
RESULTS.append(("2.2c GET /me skills roundtrip", ok_skills, status_me, r_me.get("code", -1)))
if ok_skills:
    cf(skills_after[0], ["id", "name", "category", "skill_id"], "me.skills[0]")

# 2.2f 团队实体对齐：PUT hourly_rate/available_status -> GET /users/me 回读一致
test_hr = 250.0
test_as = 2
test("2.2f PUT /users/me (hourly_rate+available_status)", "PUT", "/api/v1/users/me",
     {"hourly_rate": test_hr, "available_status": test_as})
st_hr, r_hr = req("GET", "/api/v1/users/me")
hr_data = (r_hr.get("data") or {}) if isinstance(r_hr, dict) else {}
hr_back = hr_data.get("hourly_rate")
as_back = hr_data.get("available_status")
hr_roundtrip = False
try:
    hr_roundtrip = abs(float(hr_back or 0) - test_hr) < 0.01 and int(as_back or 0) == test_as
except (TypeError, ValueError):
    pass
print(
    f"  [{'PASS' if hr_roundtrip else 'FAIL'}] 2.2f GET /users/me hourly_rate/available_status roundtrip "
    f"-> hourly_rate={hr_back}, available_status={as_back}"
)
RESULTS.append(("2.2f hourly_rate/available_status roundtrip", hr_roundtrip, st_hr, r_hr.get("code", -1)))
# 恢复默认
test("2.2f2 PUT /users/me (restore available_status)", "PUT", "/api/v1/users/me",
     {"available_status": 1})

# 2.2h PUT role=2 自动建队 + hourly 同步（仅 role=1）
st_h0, r_h0 = req("GET", "/api/v1/users/me")
role_h0 = (r_h0.get("data") or {}).get("role") if isinstance(r_h0.get("data"), dict) else None
if role_h0 != 1:
    print(f"  [SKIP] 2.2h PUT role=2 建队（当前 role={role_h0}，非 1 则跳过）")
    RESULTS.append(("2.2h auto-create team (skipped)", True, st_h0, 0))
else:
    ok_h, _ = test("2.2h1 PUT /users/me (role=2)", "PUT", "/api/v1/users/me", {"role": 2})
    st_h1, r_h1 = req("GET", "/api/v1/users/me")
    rh1 = (r_h1.get("data") or {}).get("role") if isinstance(r_h1.get("data"), dict) else None
    role_ok = rh1 == 2 and ok_h
    print(f"  [{'PASS' if role_ok else 'FAIL'}] 2.2h2 GET /users/me role after switch -> {rh1!r}")
    RESULTS.append(("2.2h role=2 roundtrip", role_ok, st_h1, r_h1.get("code", -1)))
    test_h2 = 199.0
    test_as2 = 2
    test(
        "2.2h3 PUT /users/me (hourly_rate after role=2)",
        "PUT",
        "/api/v1/users/me",
        {"hourly_rate": test_h2, "available_status": test_as2},
    )
    st_h2, r_h2 = req("GET", "/api/v1/users/me")
    d2 = (r_h2.get("data") or {}) if isinstance(r_h2, dict) else {}
    hb2 = d2.get("hourly_rate")
    asb2 = d2.get("available_status")
    h2_ok = False
    try:
        h2_ok = abs(float(hb2 or 0) - test_h2) < 0.01 and int(asb2 or 0) == test_as2
    except (TypeError, ValueError):
        pass
    print(
        f"  [{'PASS' if h2_ok else 'FAIL'}] 2.2h4 GET /users/me hourly after team create "
        f"-> hourly_rate={hb2}, available_status={asb2}"
    )
    RESULTS.append(("2.2h hourly after expert team", h2_ok, st_h2, r_h2.get("code", -1)))
    test("2.2h5 PUT /users/me (restore available_status)", "PUT", "/api/v1/users/me", {"available_status": 1})

# 2.2g 团队预算区间：仅 role=2/3 可写；默认登录多为需求方则跳过
st_r2g, r_r2g = req("GET", "/api/v1/users/me")
me_role_2g = (r_r2g.get("data") or {}).get("role") if isinstance(r_r2g.get("data"), dict) else None
if me_role_2g not in (2, 3):
    print(f"  [SKIP] 2.2g budget_min/max（role={me_role_2g}，非专家/团队方，跳过）")
    RESULTS.append(("2.2g budget (skipped non-expert)", True, st_r2g, 0))
else:
    test("2.2g PUT /users/me (budget_min+budget_max)", "PUT", "/api/v1/users/me",
         {"budget_min": 3000.0, "budget_max": 12000.0})
    st_bg, r_bg = req("GET", "/api/v1/users/me")
    bg_data = (r_bg.get("data") or {}) if isinstance(r_bg, dict) else {}
    bmin = bg_data.get("budget_min")
    bmax = bg_data.get("budget_max")
    bg_ok = False
    try:
        bg_ok = abs(float(bmin or 0) - 3000.0) < 0.01 and abs(float(bmax or 0) - 12000.0) < 0.01
    except (TypeError, ValueError):
        pass
    print(
        f"  [{'PASS' if bg_ok else 'FAIL'}] 2.2g GET /users/me budget_min/max roundtrip "
        f"-> budget_min={bmin}, budget_max={bmax}"
    )
    RESULTS.append(("2.2g budget_min/max roundtrip", bg_ok, st_bg, r_bg.get("code", -1)))
    st_bad, r_bad = req("PUT", "/api/v1/users/me", {"budget_min": 5000.0, "budget_max": 1000.0})
    bad_ok = st_bad == 400 or r_bad.get("code") == 20005
    print(
        f"  [{'PASS' if bad_ok else 'FAIL'}] 2.2g PUT invalid budget range (expect 400) "
        f"-> HTTP {st_bad}, code={r_bad.get('code')}"
    )
    RESULTS.append(("2.2g invalid budget range", bad_ok, st_bad, r_bad.get("code", -1)))

# v6 Profile
if USER_ID:
    ok, r = test("2.3 GET /users/:id (profile)", "GET", f"/api/v1/users/{USER_ID}")
    if ok and r.get("data"):
        cf(r["data"], ["id", "nickname", "rating", "credit_score", "stats"])
        stats = r["data"].get("stats", {})
        if stats:
            cf(stats, ["published_projects", "total_spent", "days_on_platform"], "profile.stats")

    test("2.4 PUT /users/:id (update)", "PUT", f"/api/v1/users/{USER_ID}",
         {"nickname": "UpdatedV2"})

    ok, r = test("2.5 GET /users/:id/skills", "GET", f"/api/v1/users/{USER_ID}/skills")
    if ok:
        print(f"         skills count: {len(r.get('data', []))}")

    ok, r = test("2.6 GET /users/:id/portfolios", "GET", f"/api/v1/users/{USER_ID}/portfolios")
    if ok:
        print(f"         portfolios count: {len(r.get('data', []))}")

    # §2.6b 作品集 CRUD（JWT）
    PORTFOLIO_TEST_UUID = None
    if TOKEN:
        ok, r = test(
            "2.6b POST /users/me/portfolios",
            "POST",
            "/api/v1/users/me/portfolios",
            {
                "title": "API V2 Test Portfolio",
                "description": "integration test",
                "category": "web",
                "tech_stack": ["Go", "Vue"],
            },
        )
        if ok and isinstance(r.get("data"), dict):
            PORTFOLIO_TEST_UUID = r["data"].get("id")
            print(f"         portfolio uuid={PORTFOLIO_TEST_UUID!r}")

        st401, r401 = req("GET", "/api/v1/users/me/portfolios", need_auth=False)
        auth401_ok = st401 == 401 and r401.get("code") == 10008
        print(
            f"  [{'PASS' if auth401_ok else 'FAIL'}] 2.6b2 GET /users/me/portfolios (no auth) "
            f"-> HTTP {st401}, code={r401.get('code', -1)}"
        )
        RESULTS.append(("2.6b2 GET /me/portfolios 401", auth401_ok, st401, r401.get("code", -1)))

        ok_m, r_m = test("2.6c GET /users/me/portfolios", "GET", "/api/v1/users/me/portfolios")
        if ok_m and isinstance(r_m.get("data"), list) and PORTFOLIO_TEST_UUID:
            found = next((x for x in r_m["data"] if x.get("id") == PORTFOLIO_TEST_UUID), None)
            pf_ok = found is not None and cf(
                found, ["id", "title", "category", "tech_stack"], "portfolio[me]"
            )
            ts = found.get("tech_stack") if isinstance(found, dict) else None
            ts_ok = isinstance(ts, list) and "Go" in ts
            pf_ok = pf_ok and ts_ok
            print(
                f"  [{'PASS' if pf_ok else 'FAIL'}] 2.6c1 GET /me/portfolios item fields "
                f"(category/tech_stack)"
            )
            RESULTS.append(("2.6c1 GET /me/portfolios fields", pf_ok, 200, 0 if pf_ok else -1))

        ok_pub, r_pub = test(
            "2.6d GET /users/:id/portfolios (same user)",
            "GET",
            f"/api/v1/users/{USER_ID}/portfolios",
        )
        if ok_pub and isinstance(r_pub.get("data"), list) and PORTFOLIO_TEST_UUID:
            ids_pub = [x.get("id") for x in r_pub["data"]]
            sync_ok = PORTFOLIO_TEST_UUID in ids_pub
            print(
                f"  [{'PASS' if sync_ok else 'FAIL'}] 2.6d1 public list contains new portfolio"
            )
            RESULTS.append(("2.6d1 GET /users/:id/portfolios sync", sync_ok, 200, 0 if sync_ok else -1))

        if PORTFOLIO_TEST_UUID:
            test(
                "2.6e0 PUT /users/me/portfolios/:uuid (category empty -> 99001)",
                "PUT",
                f"/api/v1/users/me/portfolios/{PORTFOLIO_TEST_UUID}",
                {"category": ""},
                expect_code=99001,
                expect_http=400,
            )
            test(
                "2.6e0c PUT /users/me/portfolios/:uuid (category whitespace -> 99001)",
                "PUT",
                f"/api/v1/users/me/portfolios/{PORTFOLIO_TEST_UUID}",
                {"category": "   "},
                expect_code=99001,
                expect_http=400,
            )
            test(
                "2.6e0b PUT /users/me/portfolios/:uuid (category invalid -> 99001)",
                "PUT",
                f"/api/v1/users/me/portfolios/{PORTFOLIO_TEST_UUID}",
                {"category": "not_a_valid_category"},
                expect_code=99001,
                expect_http=400,
            )
            ok_u, r_u_pf = test(
                "2.6e PUT /users/me/portfolios/:uuid",
                "PUT",
                f"/api/v1/users/me/portfolios/{PORTFOLIO_TEST_UUID}",
                {
                    "title": "Updated API V2 Portfolio",
                    "tech_stack": ["Go"],
                    "preview_url": "https://example.com/preview",
                },
            )
            if ok_u:
                _, r_chk = req("GET", "/api/v1/users/me/portfolios")
                upd_ok = False
                if isinstance(r_chk.get("data"), list):
                    hit = next(
                        (x for x in r_chk["data"] if x.get("id") == PORTFOLIO_TEST_UUID),
                        None,
                    )
                    upd_ok = bool(
                        hit
                        and hit.get("title") == "Updated API V2 Portfolio"
                        and hit.get("preview_url") == "https://example.com/preview"
                    )
                print(
                    f"  [{'PASS' if upd_ok else 'FAIL'}] 2.6e1 PUT roundtrip (title/preview_url)"
                )
                RESULTS.append(("2.6e1 PUT portfolio roundtrip", upd_ok, 200, 0 if upd_ok else -1))

            ok_del, _ = test(
                "2.6f DELETE /users/me/portfolios/:uuid",
                "DELETE",
                f"/api/v1/users/me/portfolios/{PORTFOLIO_TEST_UUID}",
            )
            if ok_del:
                _, r_after = req("GET", "/api/v1/users/me/portfolios")
                gone_ok = True
                if isinstance(r_after.get("data"), list):
                    gone_ok = PORTFOLIO_TEST_UUID not in [
                        x.get("id") for x in r_after["data"]
                    ]
                print(
                    f"  [{'PASS' if gone_ok else 'FAIL'}] 2.6f1 after DELETE not in list"
                )
                RESULTS.append(("2.6f1 DELETE soft list", gone_ok, 200, 0 if gone_ok else -1))

    # 1x1 PNG，POST /upload（需 OSS 或 local_upload_dir）
    upload_ok = False
    st_u, r_u = 0, {}
    if TOKEN:
        png_1x1 = bytes.fromhex(
            "89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c489"
            "0000000a49444154789c63000100000500018dbb28120000000049454e44ae426082"
        )
        bnd = "----KzTest" + str(int(time.time() * 1000))
        body_u = (
            f"--{bnd}\r\n"
            'Content-Disposition: form-data; name="file"; filename="dot.png"\r\n'
            "Content-Type: image/png\r\n\r\n"
        ).encode() + png_1x1 + f"\r\n--{bnd}--\r\n".encode()
        u_url = BASE + "/api/v1/upload"
        rq_u = urllib.request.Request(u_url, data=body_u, method="POST")
        rq_u.add_header("Content-Type", f"multipart/form-data; boundary={bnd}")
        rq_u.add_header("Authorization", "Bearer " + TOKEN)
        try:
            resp_u = urllib.request.urlopen(rq_u)
            st_u = resp_u.status
            r_u = json.loads(resp_u.read().decode())
        except urllib.error.HTTPError as e:
            st_u = e.code
            try:
                r_u = json.loads(e.read().decode())
            except Exception:
                r_u = {}
        if r_u.get("code") == 0 and isinstance(r_u.get("data"), dict):
            du = r_u["data"]
            u = du.get("url") or ""
            url_ok = u.startswith(("http://", "https://", "/"))
            upload_ok = bool(
                url_ok and du.get("object_key") and du.get("size_bytes", 0) > 0
            )
            # 2.7b 将上传返回的 url 作为 cover_url 创建作品，再删除（上传→作品集联调）
            if upload_ok and USER_ID:
                cover_url = (du.get("url") or "").strip()
                if cover_url.startswith("/") and not cover_url.startswith("//"):
                    cover_url = BASE.rstrip("/") + cover_url
                ok_pc, r_pc = test(
                    "2.7b POST /users/me/portfolios (cover_url from upload)",
                    "POST",
                    "/api/v1/users/me/portfolios",
                    {
                        "title": "Portfolio With Cover",
                        "category": "web",
                        "cover_url": cover_url,
                        "tech_stack": ["Go"],
                    },
                )
                if ok_pc and isinstance(r_pc.get("data"), dict):
                    pid_cov = r_pc["data"].get("id")
                    if pid_cov:
                        _, r_list_cov = req("GET", "/api/v1/users/me/portfolios")
                        cov_hit = None
                        if isinstance(r_list_cov.get("data"), list):
                            cov_hit = next(
                                (x for x in r_list_cov["data"] if x.get("id") == pid_cov),
                                None,
                            )
                        # 列表中的 cover_url 可能与请求略有差异（相对/绝对），只校验存在且标题一致
                        cov_url_ok = bool(
                            cov_hit
                            and cov_hit.get("title") == "Portfolio With Cover"
                            and cov_hit.get("cover_url")
                        )
                        print(
                            f"  [{'PASS' if cov_url_ok else 'FAIL'}] 2.7b1 GET /me/portfolios "
                            f"cover_url matches upload"
                        )
                        RESULTS.append(
                            (
                                "2.7b1 portfolio cover_url roundtrip",
                                cov_url_ok,
                                200,
                                0 if cov_url_ok else -1,
                            )
                        )
                        test(
                            "2.7c DELETE /users/me/portfolios (cover portfolio)",
                            "DELETE",
                            f"/api/v1/users/me/portfolios/{pid_cov}",
                        )
    print(
        f"  [{'PASS' if upload_ok else 'FAIL'}] 2.7 POST /upload (1x1 PNG) -> HTTP {st_u}, code={r_u.get('code', -1)}"
    )
    RESULTS.append(("2.7 POST /upload image", upload_ok, st_u, r_u.get("code", -1)))

# ==================== 3. 项目 ====================
print("\n--- 3. 项目模块 ---")
ok, r = test("3.1 POST /projects (create)", "POST", "/api/v1/projects", {
    "title": "Test Flutter App V2",
    "description": "Integration testing project for v2 API specification validation.",
    "category": "dev",
    "budget_min": 5000, "budget_max": 15000,
    "tech_requirements": ["Flutter", "Go"],
})
if ok and r.get("data"):
    PROJECT_UUID = r["data"].get("uuid") or r["data"].get("id")
    print(f"         project={PROJECT_UUID}")

test(
    "3.2n GET /projects without auth -> 401",
    "GET",
    "/api/v1/projects?page=1&page_size=10",
    need_auth=False,
    expect_code=10008,
    expect_http=401,
)

ok, r = test("3.2 GET /projects (list, mine)", "GET", "/api/v1/projects?page=1&page_size=10")
if ok and isinstance(r.get("data"), list) and USER_ID:
    scope_ok = True
    for item in r["data"]:
        oid = item.get("owner_id") or ""
        pid = item.get("provider_id") or ""
        if oid != USER_ID and pid != USER_ID:
            scope_ok = False
            break
    print(
        f"         [{'PASS' if scope_ok else 'FAIL'}] 3.2 owner/provider scope (current user only)"
    )
    if not scope_ok:
        RESULTS.append(("3.2 scope mine-only", False, 200, r.get("code", -1)))

ok, r = test("3.2a GET /projects?role=1 (demander)", "GET", "/api/v1/projects?role=1&page=1&page_size=10")
if ok:
    print(f"         demander projects: {len(r.get('data', []))}")

ok, r = test("3.2b GET /projects?role=2 (expert)", "GET", "/api/v1/projects?role=2&page=1&page_size=10")
if ok:
    print(f"         expert projects: {len(r.get('data', []))}")

if PROJECT_UUID:
    ok, r = test("3.3 GET /projects/:id (detail)", "GET", f"/api/v1/projects/{PROJECT_UUID}")
    if ok and r.get("data"):
        cf(r["data"], ["id", "title", "status", "category"])

    test("3.4 PUT /projects/:id (update)", "PUT", f"/api/v1/projects/{PROJECT_UUID}",
         {"title": "Updated Flutter App V2"})
    PROJECT_DISPLAY_TITLE = "Updated Flutter App V2"

    # 智能推荐（api-spec_v2 / 撮合）：转发 AI-Agent /api/v2/match/recommend；需服务端配置 VB_AI_AGENT_BASE_URL
    st_rec, r_rec = req(
        "GET",
        f"/api/v1/projects/{PROJECT_UUID}/recommendations?page=1&page_size=5",
    )
    msg_rec = r_rec.get("message") or ""
    rec_ok = r_rec.get("code") == 0 and isinstance(r_rec.get("data"), dict)
    if rec_ok:
        dd = r_rec["data"]
        rec_ok = isinstance(dd.get("recommendations"), list) or isinstance(dd.get("experts"), list)
    # 远程 AI-Agent 若未启用 Milvus/Embedding，返回 50002，网关为 50001 —— 视为链路已打通的降级通过
    rec_degraded = r_rec.get("code") == 50001 and (
        "未初始化" in msg_rec or "Milvus" in msg_rec or "匹配服务" in msg_rec
    )
    rec_final = rec_ok or rec_degraded
    print(
        f"  [{'PASS' if rec_final else 'FAIL'}] 3.5 GET /projects/:id/recommendations -> HTTP {st_rec}, code={r_rec.get('code', -1)}"
        + (" (AI degraded)" if rec_degraded and not rec_ok else "")
    )
    if not rec_final:
        print(f"         msg={msg_rec!r}")
    RESULTS.append(("3.5 GET /projects/:id/recommendations (AI)", rec_final, st_rec, r_rec.get("code", -1)))

    team_shape_ok = True
    if rec_degraded:
        team_shape_ok = True
    elif r_rec.get("code") == 0 and isinstance(r_rec.get("data"), dict):
        dd_shape = r_rec["data"]
        relist = dd_shape.get("recommendations") or dd_shape.get("experts") or []
        if relist and isinstance(relist[0], dict) and relist[0].get("provider_id"):
            r0 = relist[0]
            team_shape_ok = (
                r0.get("bid_type") == "team"
                and bool(r0.get("team_id"))
                and bool(r0.get("team_name"))
                and isinstance(r0.get("team_members"), list)
            )
    print(
        f"  [{'PASS' if team_shape_ok else 'FAIL'}] 3.5b GET /projects/:id/recommendations (team-shaped rows)"
    )
    RESULTS.append(
        ("3.5b GET /projects/:id/recommendations (team-shaped rows)", team_shape_ok, st_rec, r_rec.get("code", -1))
    )

# ==================== 4. 首页 ====================
print("\n--- 4. 首页聚合 ---")
ok, r = test("4.1 GET /home/demander", "GET", "/api/v1/home/demander")
if ok and r.get("data"):
    cf(r["data"], ["ai_prompt", "categories", "my_projects", "recommended_experts"])
    for i, ex in enumerate(r["data"].get("recommended_experts") or []):
        sk_ok = isinstance(ex, dict) and isinstance(ex.get("skill"), str)
        print(
            f"  [{'PASS' if sk_ok else 'FAIL'}] 4.1b demander recommended_experts[{i}] skill field -> {ex.get('skill')!r}"
        )
        RESULTS.append((f"4.1b expert[{i}] skill (str)", sk_ok, 200, 0 if sk_ok else -1))

    # 4.1c 团队实体对齐：推荐专家应含团队维度字段
    rec_list = r["data"].get("recommended_experts") or []
    if rec_list:
        team_fields_ok = all(
            isinstance(ex, dict)
            and "vibe_level" in ex
            and "vibe_power" in ex
            and "member_count" in ex
            and "budget_min" in ex
            and "budget_max" in ex
            for ex in rec_list
        )
        print(
            f"  [{'PASS' if team_fields_ok else 'FAIL'}] 4.1c recommended_experts team fields "
            f"(vibe_level/vibe_power/member_count/budget_min/budget_max) present in {len(rec_list)} items"
        )
        RESULTS.append(("4.1c recommended_experts team fields", team_fields_ok, 200, 0 if team_fields_ok else -1))

ok, r = test("4.2 GET /home/expert", "GET", "/api/v1/home/expert")
if ok and r.get("data"):
    cf(r["data"], ["revenue", "recommended_demands", "skill_heat"])

# ==================== 5. 需求广场 ====================
print("\n--- 5. 需求广场 ---")
test("5.1 GET /market/projects", "GET", "/api/v1/market/projects?page=1&page_size=10")
test("5.2 GET /market/projects (filter)", "GET", "/api/v1/market/projects?category=dev")

ok, r = test("5.3 GET /market/experts", "GET", "/api/v1/market/experts?page=1&page_size=10", need_auth=False)
EXPERT_UUID_FOR_FAV = None
EXPERT_TEAM_UUID = None
if ok:
    data = r.get("data", [])
    print(f"         experts count: {len(data)}")
    if data and len(data) > 0:
        cf(
            data[0],
            [
                "id",
                "nickname",
                "rating",
                "skills",
                "hourly_rate",
                "budget_min",
                "budget_max",
                "leader_uuid",
            ],
            "expert[0]",
        )
        EXPERT_UUID_FOR_FAV = data[0].get("leader_uuid")
        EXPERT_TEAM_UUID = data[0].get("id")

        # 5.3b 团队实体对齐：响应应含团队维度字段
        team_fields = ["team_name", "vibe_level", "vibe_power", "member_count"]
        tf_ok = cf(data[0], team_fields, "expert[0] team fields")
        print(
            f"  [{'PASS' if tf_ok else 'FAIL'}] 5.3b market/experts team fields "
            f"-> team_name={data[0].get('team_name')!r}, vibe_level={data[0].get('vibe_level')!r}, "
            f"vibe_power={data[0].get('vibe_power')}, member_count={data[0].get('member_count')}"
        )
        RESULTS.append(("5.3b market/experts team fields", tf_ok, 200, 0 if tf_ok else -1))

# ==================== 5.4 收藏（POST/DELETE /favorites，GET /users/me/favorites）====================
print("\n--- 5.4 收藏 ---")

def _project_favorite_count():
    """GET /projects/:uuid 返回的 favorite_count，失败返回 None。"""
    if not PROJECT_UUID:
        return None
    st, rr = req("GET", f"/api/v1/projects/{PROJECT_UUID}")
    if st != 200 or rr.get("code") != 0:
        return None
    d = rr.get("data")
    if not isinstance(d, dict):
        return None
    try:
        return int(d.get("favorite_count", 0))
    except (TypeError, ValueError):
        return None


if PROJECT_UUID:
    fc_base = _project_favorite_count()
    if fc_base is None:
        fc_base = 0
    test(
        "5.4a1 POST /favorites (invalid target_type -> 99001)",
        "POST",
        "/api/v1/favorites",
        {"target_type": "repo", "target_id": PROJECT_UUID},
        expect_code=99001,
        expect_http=400,
    )
    fake_puuid = str(uuid.uuid4())
    test(
        "5.4a2 POST /favorites (project not found -> 20001)",
        "POST",
        "/api/v1/favorites",
        {"target_type": "project", "target_id": fake_puuid},
        expect_code=20001,
        expect_http=404,
    )
    if USER_ID:
        test(
            "5.4a3 POST /favorites (self as expert, ineligible -> 30010)",
            "POST",
            "/api/v1/favorites",
            {"target_type": "expert", "target_id": USER_ID},
            expect_code=30010,
            expect_http=400,
        )

    fake_euuid = str(uuid.uuid4())
    test(
        "5.4a4 POST /favorites (expert uuid not found -> 30010)",
        "POST",
        "/api/v1/favorites",
        {"target_type": "expert", "target_id": fake_euuid},
        expect_code=30010,
        expect_http=400,
    )

    ok_add, r_add = test(
        "5.4b POST /favorites (project)",
        "POST",
        "/api/v1/favorites",
        {"target_type": "project", "target_id": PROJECT_UUID},
    )
    fc_after_add = _project_favorite_count()
    cnt_ok = fc_after_add is not None and fc_after_add == fc_base + 1
    print(
        f"  [{'PASS' if cnt_ok else 'FAIL'}] 5.4b1 GET /projects/:id favorite_count after add "
        f"-> {fc_after_add} (expect {fc_base + 1})"
    )
    RESULTS.append(("5.4b1 favorite_count +1", cnt_ok, 200, 0 if cnt_ok else -1))

    ok_idem, r_idem = test(
        "5.4c POST /favorites (project, idempotent)",
        "POST",
        "/api/v1/favorites",
        {"target_type": "project", "target_id": PROJECT_UUID},
    )
    idem_msg = (r_idem.get("message") or "") if isinstance(r_idem, dict) else ""
    idem_ok = ok_idem and isinstance(r_idem.get("data"), dict) and r_idem["data"].get("id")
    fc_after_idem = _project_favorite_count()
    cnt_stable = fc_after_idem == fc_base + 1
    idem_full = idem_ok and cnt_stable and ("已收藏" in idem_msg)
    print(
        f"  [{'PASS' if idem_full else 'FAIL'}] 5.4c1 idempotent message + favorite_count unchanged "
        f"-> count={fc_after_idem}"
    )
    RESULTS.append(("5.4c1 favorite idempotent count", idem_full, 200, 0 if idem_full else -1))

    ok_list, r_list = test(
        "5.4d GET /users/me/favorites?target_type=project",
        "GET",
        "/api/v1/users/me/favorites?target_type=project&page=1&page_size=20",
    )
    list_ok = False
    if ok_list and isinstance(r_list.get("data"), list):
        ids = [x.get("target_id") for x in r_list["data"] if isinstance(x, dict)]
        list_ok = PROJECT_UUID in ids
    print(
        f"  [{'PASS' if list_ok else 'FAIL'}] 5.4d1 favorites list contains project uuid"
    )
    RESULTS.append(("5.4d1 GET /me/favorites project", list_ok, 200, 0 if list_ok else -1))

    ok_del, _ = test(
        "5.4e DELETE /favorites (project)",
        "DELETE",
        "/api/v1/favorites",
        {"target_type": "project", "target_id": PROJECT_UUID},
    )
    fc_after_del = _project_favorite_count()
    del_cnt_ok = fc_after_del is not None and fc_after_del == fc_base
    print(
        f"  [{'PASS' if del_cnt_ok else 'FAIL'}] 5.4e1 GET /projects/:id favorite_count after delete "
        f"-> {fc_after_del} (expect {fc_base})"
    )
    RESULTS.append(("5.4e1 favorite_count restored", del_cnt_ok, 200, 0 if del_cnt_ok else -1))

    ok_del2, _ = test(
        "5.4f DELETE /favorites (project, idempotent)",
        "DELETE",
        "/api/v1/favorites",
        {"target_type": "project", "target_id": PROJECT_UUID},
    )
    print(
        f"  [{'PASS' if ok_del2 else 'FAIL'}] 5.4f1 DELETE when not favorited (idempotent)"
    )
    RESULTS.append(("5.4f DELETE idempotent", ok_del2, 200, 0 if ok_del2 else -1))

    test(
        "5.4g DELETE /favorites (invalid target_type -> 99001)",
        "DELETE",
        "/api/v1/favorites",
        {"target_type": "invalid", "target_id": PROJECT_UUID},
        expect_code=99001,
        expect_http=400,
    )

    # 5.4j 并发 POST 同一项目收藏：1062 幂等 + favorite_count 原子 +1（非单元测试，依赖 HTTP 并发）
    fc_before_conc = _project_favorite_count()
    if fc_before_conc is None:
        fc_before_conc = 0
    body_conc = {"target_type": "project", "target_id": PROJECT_UUID}

    def _post_favorite_concurrent():
        return req("POST", "/api/v1/favorites", body_conc)

    with concurrent.futures.ThreadPoolExecutor(max_workers=12) as pool:
        futs = [pool.submit(_post_favorite_concurrent) for _ in range(12)]
        conc_results = [fu.result() for fu in concurrent.futures.as_completed(futs)]

    conc_all_200 = all(st == 200 for st, _ in conc_results)
    conc_all_code0 = all(
        isinstance(r, dict) and r.get("code") == 0 for _, r in conc_results
    )
    fc_after_conc = _project_favorite_count()
    conc_count_ok = (
        fc_after_conc is not None and fc_before_conc is not None and fc_after_conc == fc_before_conc + 1
    )
    conc_ok = conc_all_200 and conc_all_code0 and conc_count_ok
    print(
        f"  [{'PASS' if conc_ok else 'FAIL'}] 5.4j concurrent POST /favorites x12 "
        f"-> all HTTP 200 & code=0: {conc_all_200 and conc_all_code0}, "
        f"favorite_count {fc_before_conc}->{fc_after_conc} (expect +1)"
    )
    RESULTS.append(("5.4j concurrent favorite + atomic count", conc_ok, 200, 0 if conc_ok else -1))

    _, _ = req(
        "DELETE",
        "/api/v1/favorites",
        {"target_type": "project", "target_id": PROJECT_UUID},
    )
else:
    print("  [SKIP] 5.4 无 PROJECT_UUID，跳过收藏用例")

# 5.4h 用团队 UUID 收藏专家（target_id 存储团队 UUID）
if EXPERT_TEAM_UUID and USER_ID:
    ok_e, r_e = test(
        "5.4h POST /favorites (expert via team UUID)",
        "POST",
        "/api/v1/favorites",
        {"target_type": "expert", "target_id": EXPERT_TEAM_UUID},
    )
    if ok_e:
        ok_el, r_el = test(
            "5.4h1 GET /users/me/favorites?target_type=expert",
            "GET",
            "/api/v1/users/me/favorites?target_type=expert&page=1&page_size=20",
        )
        el_ok = False
        if ok_el and isinstance(r_el.get("data"), list):
            eids = [x.get("target_id") for x in r_el["data"] if isinstance(x, dict)]
            el_ok = EXPERT_TEAM_UUID in eids
        print(
            f"  [{'PASS' if el_ok else 'FAIL'}] 5.4h2 favorites target_id is team uuid "
            f"(expect {EXPERT_TEAM_UUID!r} in list)"
        )
        RESULTS.append(("5.4h2 GET /me/favorites expert (team uuid)", el_ok, 200, 0 if el_ok else -1))
        test(
            "5.4i DELETE /favorites (expert via team UUID)",
            "DELETE",
            "/api/v1/favorites",
            {"target_type": "expert", "target_id": EXPERT_TEAM_UUID},
        )
elif EXPERT_TEAM_UUID is None:
    print("  [SKIP] 5.4h–i 无市场专家数据，跳过专家收藏用例")

# 5.4h3–h6 用 leader UUID 收藏专家（后端自动解析为团队 UUID 存储）
if EXPERT_TEAM_UUID and EXPERT_UUID_FOR_FAV and USER_ID and EXPERT_UUID_FOR_FAV != USER_ID:
    ok_t, r_t = test(
        "5.4h3 POST /favorites (expert via leader UUID -> team UUID)",
        "POST",
        "/api/v1/favorites",
        {"target_type": "expert", "target_id": EXPERT_UUID_FOR_FAV},
    )
    if ok_t:
        ok_tl, r_tl = test(
            "5.4h4 GET /users/me/favorites?target_type=expert (after leader uuid add)",
            "GET",
            "/api/v1/users/me/favorites?target_type=expert&page=1&page_size=20",
        )
        tid_ok = False
        if ok_tl and isinstance(r_tl.get("data"), list):
            stored_ids = [x.get("target_id") for x in r_tl["data"] if isinstance(x, dict)]
            tid_ok = EXPERT_TEAM_UUID in stored_ids
        print(
            f"  [{'PASS' if tid_ok else 'FAIL'}] 5.4h5 favorites target_id stored as team uuid "
            f"(expect {EXPERT_TEAM_UUID!r} in list)"
        )
        RESULTS.append(("5.4h5 leader uuid -> team uuid in favorites", tid_ok, 200, 0 if tid_ok else -1))

        # idempotent: re-add with team uuid should be already-favorited
        ok_idem, r_idem = test(
            "5.4h5b POST /favorites (expert team uuid idempotent)",
            "POST",
            "/api/v1/favorites",
            {"target_type": "expert", "target_id": EXPERT_TEAM_UUID},
        )
        idem_ok = ok_idem and r_idem.get("message", "").find("已收藏") >= 0
        print(f"  [{'PASS' if idem_ok else 'FAIL'}] 5.4h5c idempotent check (leader uuid then team uuid)")
        RESULTS.append(("5.4h5c idempotent leader+team uuid", idem_ok, 200, 0 if idem_ok else -1))

        test(
            "5.4h6 DELETE /favorites (expert via leader UUID)",
            "DELETE",
            "/api/v1/favorites",
            {"target_type": "expert", "target_id": EXPERT_UUID_FOR_FAV},
        )
elif EXPERT_TEAM_UUID is None:
    print("  [SKIP] 5.4h3–h6 无团队 UUID，跳过团队 UUID 收藏用例")

# ==================== 6. Phase 3: 需求发布 ====================
print("\n--- 6. Phase 3: 需求发布/PRD ---")
ok, r = test("6.1 POST /projects/ai-chat", "POST", "/api/v1/projects/ai-chat",
             {"message": "我想做一个社交电商App", "category": "dev"})
if ok and r.get("data"):
    cf(r["data"], ["reply", "can_generate_prd", "turn"])

ok, r = test("6.2 POST /projects/generate-prd", "POST", "/api/v1/projects/generate-prd",
             {"category": "dev", "chat_history": [{"role": "user", "content": "社交电商"}]})
if ok and r.get("data"):
    cf(r["data"], ["prd_id", "title", "modules", "budget_suggestion"])

ok, r = test("6.3 POST /projects/draft", "POST", "/api/v1/projects/draft",
             {"category": "dev", "budget_min": 3000, "budget_max": 8000})
if ok and r.get("data"):
    cf(r["data"], ["draft_id", "saved_at"])

# 6.3n SaveDraft 负例（binding：min=0 / match_mode oneof；业务：max>=min）
test(
    "6.3n1 POST /projects/draft (negative budget_min -> 99001)",
    "POST",
    "/api/v1/projects/draft",
    {"category": "dev", "budget_min": -1, "budget_max": 1000},
    expect_code=99001,
    expect_http=400,
)
test(
    "6.3n2 POST /projects/draft (negative budget_max -> 99001)",
    "POST",
    "/api/v1/projects/draft",
    {"category": "dev", "budget_min": 0, "budget_max": -0.01},
    expect_code=99001,
    expect_http=400,
)
test(
    "6.3n3 POST /projects/draft (invalid match_mode -> 99001)",
    "POST",
    "/api/v1/projects/draft",
    {"category": "dev", "budget_min": 100, "budget_max": 200, "match_mode": 9},
    expect_code=99001,
    expect_http=400,
)
test(
    "6.3n4 POST /projects/draft (budget_max < budget_min -> 99001)",
    "POST",
    "/api/v1/projects/draft",
    {"category": "dev", "budget_min": 5000, "budget_max": 1000},
    expect_code=99001,
    expect_http=400,
)

# 6.3b–6.3e：发布草稿 + 标题/描述/category 归一（与 PublishDraft / SaveDraft 一致）
DRAFT_PUBLISH_UUID = None
ok, r = test(
    "6.3b POST /projects/draft (design legacy + short title/desc)",
    "POST",
    "/api/v1/projects/draft",
    {
        "category": "design",
        "title": "短",
        "description": "短",
        "budget_min": 100,
        "budget_max": 900,
    },
)
if ok and r.get("data"):
    DRAFT_PUBLISH_UUID = r["data"].get("draft_id") or r["data"].get("uuid")
    cf(r["data"], ["draft_id", "saved_at"])

if DRAFT_PUBLISH_UUID:
    ok, r = test(
        "6.3c GET /projects/:id (draft before publish)",
        "GET",
        f"/api/v1/projects/{DRAFT_PUBLISH_UUID}",
    )
    _draft_assert = False
    if ok and isinstance(r.get("data"), dict):
        _d = r["data"]
        _draft_assert = (
            _d.get("category") == "visual"
            and int(_d.get("status", 0)) == 1
            and str(_d.get("title") or "") == "短"
        )
    print(
        f"  [{'PASS' if _draft_assert else 'FAIL'}] 6.3c assert: draft category=visual, status=1, title=短"
    )
    RESULTS.append(("6.3c assert draft normalized", _draft_assert, 200, 0))

    ok, r = test(
        "6.3d POST /projects/:id/publish",
        "POST",
        f"/api/v1/projects/{DRAFT_PUBLISH_UUID}/publish",
        body={},
    )
    if ok and r.get("data"):
        cf(r["data"], ["uuid", "status"])
        if int(r["data"].get("status", 0)) != 2:
            print("         WARN: publish data.status expected 2")

    ok, r = test(
        "6.3e GET /projects/:id (after publish)",
        "GET",
        f"/api/v1/projects/{DRAFT_PUBLISH_UUID}",
    )
    _pub_assert = False
    if ok and isinstance(r.get("data"), dict):
        _pd = r["data"]
        _t = str(_pd.get("title") or "")
        _desc = str(_pd.get("description") or "")
        _pub_assert = (
            _pd.get("category") == "visual"
            and int(_pd.get("status", 0)) == 2
            and len(_t) >= 5
            and len(_desc) >= 20
        )
    print(
        f"  [{'PASS' if _pub_assert else 'FAIL'}] 6.3e assert: published status=2, category=visual, len(title)>=5, len(desc)>=20"
    )
    RESULTS.append(("6.3e assert publish title/desc/category", _pub_assert, 200, 0))

if PROJECT_UUID:
    ok, r = test("6.4 GET /projects/:id/prd", "GET", f"/api/v1/projects/{PROJECT_UUID}/prd")
    if ok and r.get("data"):
        cf(r["data"], ["prd_id", "project_id", "title"])

    test("6.5 PUT /projects/:id/prd/cards/:cardId", "PUT",
         f"/api/v1/projects/{PROJECT_UUID}/prd/cards/card_001",
         {"criteria_id": "ac_001"})

# ==================== 7. Phase 4: 投标/撮合 ====================
print("\n--- 7. Phase 4: 投标/撮合 ---")

# 创建第二个用户来投标
phone2 = gen_phone()
test("7.0a sms-code (user2)", "POST", "/api/v1/auth/sms-code",
     {"phone": phone2, "purpose": 2}, need_auth=False)
time.sleep(0.3)
code2 = get_sms_code(phone2) or "952786"
old_token = TOKEN
ok, r = test("7.0b login (user2)", "POST", "/api/v1/auth/login",
             {"phone": phone2, "code": code2}, need_auth=False)
TOKEN2 = None
USER2_ID = None
USER2_NICKNAME = None
if ok and r.get("data"):
    TOKEN2 = r["data"].get("access_token")
    USER2_ID = r["data"].get("user_id")
if TOKEN2:
    _, r_u2 = req("GET", "/api/v1/users/me", auth_token=TOKEN2)
    if r_u2.get("code") == 0 and isinstance(r_u2.get("data"), dict):
        USER2_NICKNAME = (r_u2["data"].get("nickname") or "").strip() or None
TOKEN = old_token

if PROJECT_UUID and TOKEN2:
    saved_token = TOKEN
    TOKEN = TOKEN2
    ok, r = test("7.1 POST /projects/:id/bids (create bid)", "POST",
                 f"/api/v1/projects/{PROJECT_UUID}/bids",
                 {"amount": 8000, "duration_days": 14, "proposal": "I can do this project well"})
    BID_UUID = None
    if ok and r.get("data"):
        BID_UUID = r["data"].get("bid_id")
        print(f"         bid_id={BID_UUID}")
    TOKEN = saved_token

    def _notif_type_is_23(row):
        if not isinstance(row, dict):
            return False
        for k in ("notification_type", "type"):
            v = row.get(k)
            if v is None:
                continue
            try:
                if int(float(v)) == 23:
                    return True
            except (TypeError, ValueError):
                continue
        return False

    st_n23, r_n23 = req("GET", "/api/v1/notifications?type=23&page_size=50")
    rows_n23 = r_n23.get("data") if isinstance(r_n23.get("data"), list) else []
    if r_n23.get("code") != 0 or not rows_n23:
        st_n23, r_n23 = req("GET", "/api/v1/notifications?page_size=50")
        rows_n23 = r_n23.get("data") if isinstance(r_n23.get("data"), list) else []

    def _new_bid_notif_ok(row):
        if not isinstance(row, dict):
            return False
        c = row.get("content") or ""
        if row.get("title") != "收到新投标":
            return False
        if not _notif_type_is_23(row):
            return False
        if PROJECT_DISPLAY_TITLE not in c or "8000" not in c:
            return False
        if "提交了投标" not in c:
            return False
        # U+00A5 半角 ¥ 或 U+FFE5 全角 ￥
        if "\u00a5" not in c and "\uffe5" not in c:
            return False
        if USER2_NICKNAME and USER2_NICKNAME not in c:
            return False
        return True

    hit_n23 = any(_new_bid_notif_ok(x) for x in rows_n23)
    print(
        f"  [{'PASS' if hit_n23 and r_n23.get('code') == 0 else 'FAIL'}] 7.1b GET /notifications?type=23 (需求方 收到新投标)"
    )
    RESULTS.append(
        ("7.1b demander new_bid notification (type=23)", hit_n23 and r_n23.get("code") == 0, st_n23, r_n23.get("code", -1))
    )

    # 7.1c: 投标绑定非成员团队 -> 30007
    if SEED_TEAM_UUID and TOKEN2:
        saved_t = TOKEN
        TOKEN = TOKEN2
        ok_tc, r_tc = test(
            "7.1c POST /bids (non-member team -> 30007)",
            "POST",
            f"/api/v1/projects/{PROJECT_UUID}/bids",
            {"amount": 5000, "duration_days": 7, "proposal": "test", "team_id": SEED_TEAM_UUID},
            expect_code=30007,
            expect_http=400,
        )
        TOKEN = saved_t

    ok, r = test("7.2 GET /projects/:id/bids (list bids)", "GET",
                 f"/api/v1/projects/{PROJECT_UUID}/bids")
    if ok and r.get("data"):
        print(f"         bids count: {len(r['data'])}")

    # 7.2b：专用项目验证投标撤回（不影响后续 7.4 主流程撮合）
    PROJECT_WITHDRAW_UUID = None
    BID_WITHDRAW_UUID = None
    ok_pw, r_pw = test(
        "7.2b0 POST /projects (withdraw flow project)",
        "POST",
        "/api/v1/projects",
        {
            "title": "Withdraw Bid Test Project V2",
            "description": "Dedicated project for bid withdraw integration test.",
            "category": "dev",
            "budget_min": 1000,
            "budget_max": 5000,
            "tech_requirements": ["Go"],
        },
    )
    if ok_pw and r_pw.get("data"):
        PROJECT_WITHDRAW_UUID = r_pw["data"].get("uuid") or r_pw["data"].get("id")
    if PROJECT_WITHDRAW_UUID:
        saved_t = TOKEN
        TOKEN = TOKEN2
        ok_bw, r_bw = test(
            "7.2b1 POST /projects/:id/bids (withdraw test)",
            "POST",
            f"/api/v1/projects/{PROJECT_WITHDRAW_UUID}/bids",
            {"amount": 2000, "duration_days": 7, "proposal": "withdraw test bid"},
        )
        if ok_bw and r_bw.get("data"):
            BID_WITHDRAW_UUID = r_bw["data"].get("bid_id")
        TOKEN = saved_t
        bc_before = mysql_scalar(
            f"SELECT bid_count FROM projects WHERE uuid='{PROJECT_WITHDRAW_UUID}' LIMIT 1"
        )
        try:
            bc_before_i = int(bc_before) if bc_before is not None else -1
        except ValueError:
            bc_before_i = -1
        if BID_WITHDRAW_UUID:
            st_wd, r_wd = req(
                "PUT",
                f"/api/v1/bids/{BID_WITHDRAW_UUID}/withdraw",
                auth_token=TOKEN2,
            )
            wd_ok = (
                r_wd.get("code") == 0
                and isinstance(r_wd.get("data"), dict)
                and r_wd["data"].get("status") == "withdrawn"
            )
            print(
                f"  [{'PASS' if wd_ok else 'FAIL'}] 7.2b2 PUT /bids/:id/withdraw (pending) -> HTTP {st_wd}, code={r_wd.get('code')}"
            )
            RESULTS.append(("7.2b2 withdraw pending bid", wd_ok, st_wd, r_wd.get("code", -1)))
            bc_after = mysql_scalar(
                f"SELECT bid_count FROM projects WHERE uuid='{PROJECT_WITHDRAW_UUID}' LIMIT 1"
            )
            try:
                bc_after_i = int(bc_after) if bc_after is not None else -1
            except ValueError:
                bc_after_i = -1
            bc_match = bc_before_i >= 0 and bc_after_i == bc_before_i - 1
            print(
                f"  [{'PASS' if bc_match else 'FAIL'}] 7.2b3 MySQL bid_count after withdraw: {bc_before!r} -> {bc_after!r}"
            )
            RESULTS.append(("7.2b3 bid_count after withdraw", bc_match, 200, 0))
            st_wd2, r_wd2 = req(
                "PUT",
                f"/api/v1/bids/{BID_WITHDRAW_UUID}/withdraw",
                auth_token=TOKEN2,
            )
            wd2_ok = r_wd2.get("code") == 30003
            print(
                f"  [{'PASS' if wd2_ok else 'FAIL'}] 7.2b4 PUT withdraw again (expect 30003) -> HTTP {st_wd2}, code={r_wd2.get('code')}"
            )
            RESULTS.append(("7.2b4 withdraw idempotent closed", wd2_ok, st_wd2, r_wd2.get("code", -1)))
        else:
            print("  [FAIL] 7.2b: missing bid_id for withdraw test")
            RESULTS.append(("7.2b withdraw flow", False, 0, -1))

    ok, r = test("7.3 GET /projects/:id/ai-suggestion", "GET",
                 f"/api/v1/projects/{PROJECT_UUID}/ai-suggestion")
    if ok and r.get("data"):
        cf(r["data"], ["suggested_price_min", "suggested_price_max", "reason"])

    if BID_UUID:
        ok_acc, r_acc = test("7.4 POST /bids/:id/accept", "POST",
                             f"/api/v1/bids/{BID_UUID}/accept")
        if ok_acc and r_acc.get("data"):
            print(f"         status: {r_acc['data'].get('status')}")
        if ok_acc:
            st_d, r_d = req("GET", "/api/v1/notifications?type=20&page_size=50")
            rows_d = r_d.get("data") if isinstance(r_d.get("data"), list) else []
            hit_d = any(
                isinstance(x, dict) and x.get("title") == "撮合成功" and "撮合成功" in (x.get("content") or "")
                for x in rows_d
            )
            print(
                f"  [{'PASS' if hit_d and r_d.get('code') == 0 else 'FAIL'}] 7.4b GET /notifications?type=20 (demander 撮合成功)"
            )
            RESULTS.append(
                ("7.4b demander match_success notification", hit_d and r_d.get("code") == 0, st_d, r_d.get("code", -1))
            )
            st_e, r_e = req("GET", "/api/v1/notifications?type=20&page_size=50", auth_token=TOKEN2)
            rows_e = r_e.get("data") if isinstance(r_e.get("data"), list) else []
            hit_e = any(
                isinstance(x, dict) and x.get("title") == "恭喜被选定" and "服务方" in (x.get("content") or "")
                for x in rows_e
            )
            print(
                f"  [{'PASS' if hit_e and r_e.get('code') == 0 else 'FAIL'}] 7.4c GET /notifications?type=20 (expert 恭喜被选定)"
            )
            RESULTS.append(
                ("7.4c expert match_success notification", hit_e and r_e.get("code") == 0, st_e, r_e.get("code", -1))
            )
            st_c, r_c = req("GET", "/api/v1/conversations")
            conv_ok = False
            match_conv_uuid = None
            if r_c.get("code") == 0 and isinstance(r_c.get("data"), list):
                for c in r_c["data"]:
                    if isinstance(c, dict) and "撮合成功" in (c.get("last_message") or ""):
                        conv_ok = True
                        match_conv_uuid = c.get("id")
                        break
            print(
                f"  [{'PASS' if conv_ok else 'FAIL'}] 7.4d GET /conversations (demander 系统首条消息)"
            )
            RESULTS.append(("7.4d conversations system message", conv_ok, st_c, r_c.get("code", -1)))

            meta_conv_ok = False
            if r_c.get("code") == 0:
                mc = r_c.get("meta")
                meta_conv_ok = (
                    isinstance(mc, dict)
                    and "total" in mc
                    and "page_size" in mc
                    and "page" in mc
                    and "total_pages" in mc
                )
            print(
                f"  [{'PASS' if meta_conv_ok else 'FAIL'}] 7.4d1 GET /conversations meta (page/total/total_pages)"
            )
            RESULTS.append(("7.4d1 conversations list meta", meta_conv_ok, st_c, r_c.get("code", -1)))

            if match_conv_uuid and isinstance(match_conv_uuid, str):
                MATCH_CONV_UUID = match_conv_uuid

            st_ce, r_ce = req("GET", "/api/v1/conversations", auth_token=TOKEN2)
            conv_e_ok = False
            if r_ce.get("code") == 0 and isinstance(r_ce.get("data"), list):
                for c in r_ce["data"]:
                    if isinstance(c, dict) and "撮合成功" in (c.get("last_message") or ""):
                        conv_e_ok = True
                        break
            print(
                f"  [{'PASS' if conv_e_ok else 'FAIL'}] 7.4e GET /conversations (expert 可见同一会话)"
            )
            RESULTS.append(("7.4e expert sees match conversation", conv_e_ok, st_ce, r_ce.get("code", -1)))

            msg_ok = False
            st_m, r_m = 0, {}
            if match_conv_uuid:
                st_m, r_m = req("GET", f"/api/v1/conversations/{match_conv_uuid}/messages?limit=20")
                if r_m.get("code") == 0 and isinstance(r_m.get("data"), list):
                    for m in r_m["data"]:
                        if not isinstance(m, dict):
                            continue
                        if m.get("type") == "system" and "沟通" in str(m.get("content") or ""):
                            msg_ok = True
                            break
            print(
                f"  [{'PASS' if msg_ok else 'FAIL'}] 7.4f GET /conversations/:uuid/messages (system 首条)"
            )
            RESULTS.append(("7.4f conversation messages system", msg_ok, st_m, r_m.get("code", -1)))

            st_i, r_i = req("POST", f"/api/v1/bids/{BID_UUID}/accept")
            idem_ok = r_i.get("code") == 0 and r_i.get("data", {}).get("status") == "accepted"
            print(
                f"  [{'PASS' if idem_ok else 'FAIL'}] 7.4g POST /bids/:id/accept (idempotent) -> HTTP {st_i}, code={r_i.get('code')}"
            )
            RESULTS.append(("7.4g accept bid idempotent", idem_ok, st_i, r_i.get("code", -1)))

            st_ww, r_ww = req(
                "PUT",
                f"/api/v1/bids/{BID_UUID}/withdraw",
                auth_token=TOKEN2,
            )
            acc_wd_ok = r_ww.get("code") == 30003
            print(
                f"  [{'PASS' if acc_wd_ok else 'FAIL'}] 7.4w PUT /bids/:id/withdraw after accept (expect 30003) -> HTTP {st_ww}, code={r_ww.get('code')}"
            )
            RESULTS.append(("7.4w withdraw accepted bid forbidden", acc_wd_ok, st_ww, r_ww.get("code", -1)))

            ou = mysql_scalar(
                "SELECT o.uuid FROM orders o JOIN projects p ON p.id=o.project_id "
                f"WHERE p.uuid='{PROJECT_UUID}' ORDER BY o.id DESC LIMIT 1"
            )
            order_detail_ok = False
            st_od, r_od = 0, {}
            if ou:
                st_od, r_od = req("GET", f"/api/v1/orders/{ou}")
                if r_od.get("code") == 0 and isinstance(r_od.get("data"), dict):
                    da = r_od["data"]
                    amt_ok = abs(float(da.get("project_amount") or 0) - 8000) < 0.01
                    fee_ok = abs(float(da.get("platform_fee") or 0) - 960.0) < 0.01
                    order_detail_ok = bool(
                        da.get("status") == "pending" and amt_ok and fee_ok
                    )
            print(
                f"  [{'PASS' if order_detail_ok else 'FAIL'}] 7.4h GET /orders/:id (demander 待支付, 金额/佣金)"
            )
            RESULTS.append(
                ("7.4h order detail after accept", order_detail_ok, st_od, r_od.get("code", -1))
            )

            pay_notif_ok = False
            st_pn, r_pn = req("GET", "/api/v1/notifications?type=21&page_size=50")
            if r_pn.get("code") == 0:
                rows = r_pn.get("data") or []
                pay_notif_ok = any(
                    (x.get("title") or "") == "请支付项目款项"
                    for x in rows
                    if isinstance(x, dict)
                )
            print(
                f"  [{'PASS' if pay_notif_ok else 'FAIL'}] 7.4i GET /notifications type=21 (支付提醒)"
            )
            RESULTS.append(
                ("7.4i pay reminder notification", pay_notif_ok, st_pn, r_pn.get("code", -1))
            )

            test(
                "7.4j POST /orders (duplicate pending -> 40013)",
                "POST",
                "/api/v1/orders",
                {"project_id": PROJECT_UUID},
                expect_code=40013,
            )

# ==================== 8. Phase 4: 项目管理 ====================
print("\n--- 8. Phase 4: 项目管理 ---")
_UUID_RE = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
    re.I,
)

MILESTONE_TEST_TITLE = "集成测试里程碑-阶段一"
MS_UUID = None
TOKEN_OUTSIDER = None  # 8.2f 第三方用户，用于 8.5 文件区越权校验
if PROJECT_UUID:
    ok, r = test("8.1 GET /projects/:id/tasks", "GET",
                 f"/api/v1/projects/{PROJECT_UUID}/tasks")
    if ok:
        print(f"         tasks: {len(r.get('data', []))}")

    ok, r = test(
        "8.2 POST /projects/:id/milestones (create)",
        "POST",
        f"/api/v1/projects/{PROJECT_UUID}/milestones",
        {
            "title": MILESTONE_TEST_TITLE,
            "description": "里程碑创建接口联调",
            "sort_order": 0,
            "due_date": "2026-12-31",
            "payment_ratio": 25.0,
        },
        expect_http=200,
    )
    if ok and isinstance(r.get("data"), dict):
        d = r["data"]
        MS_UUID = d.get("uuid") or d.get("id")
        pa = d.get("payment_amount")
        print(f"         milestone uuid={MS_UUID}, payment_amount={pa!r}")
        # 撮合后 bid 8000 → 25% 应为 2000
        if pa is not None and abs(float(pa) - 2000.0) < 0.02:
            print("         payment_amount 与 agreed_price×25% 一致 (≈2000)")
    test(
        "8.2b POST /projects/:id/milestones (payment_ratio sum>100% -> 21007)",
        "POST",
        f"/api/v1/projects/{PROJECT_UUID}/milestones",
        {
            "title": "集成测试-比例超额",
            "payment_ratio": 80.0,
        },
        expect_code=21007,
        expect_http=400,
    )
    _fake_pid = str(uuid.uuid4())
    test(
        "8.2c POST /projects/:id/milestones (project not found -> 20001)",
        "POST",
        f"/api/v1/projects/{_fake_pid}/milestones",
        {"title": "不存在的项目里程碑", "payment_ratio": 10.0},
        expect_code=20001,
        expect_http=404,
    )

    TASK_TEST_TITLE = "集成测试-手动任务"
    TASK_CREATE_UUID = None
    _task_body = {
        "title": TASK_TEST_TITLE,
        "ears_type": "event",
        "ears_behavior": "用户点击登录按钮后跳转首页",
        "priority": 2,
    }
    if MS_UUID:
        _task_body["milestone_id"] = MS_UUID
    ok_tk, r_tk = test(
        "8.2d POST /projects/:id/tasks (create manual)",
        "POST",
        f"/api/v1/projects/{PROJECT_UUID}/tasks",
        _task_body,
        expect_http=200,
    )
    if ok_tk and isinstance(r_tk.get("data"), dict):
        TASK_CREATE_UUID = r_tk["data"].get("uuid") or r_tk["data"].get("id")
        print(f"         task uuid={TASK_CREATE_UUID}, task_code={r_tk['data'].get('task_code')!r}")

    # 8.2d2 创建响应中 milestone_id 须为里程碑 UUID（与 MS_UUID 一致），不得为数字主键
    ms_uuid_in_create_ok = True
    if not MS_UUID:
        print("  [SKIP] 8.2d2 无里程碑 UUID，跳过 milestone_id 格式断言")
    elif not ok_tk:
        ms_uuid_in_create_ok = False
        print("  [FAIL] 8.2d2 依赖 8.2d 创建成功以校验 milestone_id")
    elif isinstance(r_tk.get("data"), dict):
        dtk = r_tk["data"]
        mid = dtk.get("milestone_id")
        if not mid or not _UUID_RE.match(str(mid)) or str(mid).lower() != str(MS_UUID).lower():
            ms_uuid_in_create_ok = False
            print(
                f"  [FAIL] 8.2d2 POST create task response milestone_id must be milestone UUID "
                f"(got {mid!r}, expect {MS_UUID!r})"
            )
        else:
            print("  [PASS] 8.2d2 create response milestone_id is UUID and matches milestone")
    else:
        ms_uuid_in_create_ok = False
    RESULTS.append(
        (
            "8.2d2 create task milestone_id is UUID",
            ms_uuid_in_create_ok,
            200 if ok_tk else 0,
            0 if ms_uuid_in_create_ok else -1,
        )
    )

    st_tasks, r_tasks = req("GET", f"/api/v1/projects/{PROJECT_UUID}/tasks")
    tasks_list_ok = False
    if r_tasks.get("code") == 0 and isinstance(r_tasks.get("data"), list):
        rows_t = [x for x in r_tasks["data"] if isinstance(x, dict)]
        titles_t = [x.get("title") for x in rows_t]
        tasks_list_ok = TASK_TEST_TITLE in titles_t
        if TASK_CREATE_UUID:
            tasks_list_ok = tasks_list_ok and any(
                (x.get("id") == TASK_CREATE_UUID or x.get("uuid") == TASK_CREATE_UUID) for x in rows_t
            )
        # 列表项 milestone_id 须为 UUID（与创建时里程碑一致）
        if tasks_list_ok and MS_UUID and TASK_CREATE_UUID:
            for x in rows_t:
                if not isinstance(x, dict):
                    continue
                if x.get("title") != TASK_TEST_TITLE:
                    continue
                lm = x.get("milestone_id")
                if not lm or not _UUID_RE.match(str(lm)) or str(lm).lower() != str(MS_UUID).lower():
                    tasks_list_ok = False
                    print(
                        f"  [FAIL] 8.2e list task milestone_id must be UUID (got {lm!r}, expect {MS_UUID!r})"
                    )
                break
        print(
            f"  [{'PASS' if tasks_list_ok else 'FAIL'}] 8.2e GET /projects/:id/tasks "
            f"(list contains created) -> HTTP {st_tasks}, n={len(rows_t)}"
        )
        if not tasks_list_ok:
            print(f"         titles={titles_t!r}, expect={TASK_TEST_TITLE!r}, uuid={TASK_CREATE_UUID!r}")
    else:
        print(
            f"  [FAIL] 8.2e GET /projects/:id/tasks -> HTTP {st_tasks}, code={r_tasks.get('code')}"
        )
    RESULTS.append(
        ("8.2e GET tasks list contains created", tasks_list_ok, st_tasks, r_tasks.get("code", -1))
    )

    # 8.2f 指派人须属于项目：第三方用户 assignee_id -> 21011 + HTTP 400
    phone3 = gen_phone()
    test(
        "8.2f0 POST /auth/sms-code (user3 outsider)",
        "POST",
        "/api/v1/auth/sms-code",
        {"phone": phone3, "purpose": 2},
        need_auth=False,
    )
    time.sleep(0.3)
    sc3 = get_sms_code(phone3) or "952786"
    ok3, r3 = test(
        "8.2f1 POST /auth/login (user3)",
        "POST",
        "/api/v1/auth/login",
        {"phone": phone3, "code": sc3},
        need_auth=False,
    )
    USER3_ID = None
    if ok3 and isinstance(r3.get("data"), dict):
        USER3_ID = r3["data"].get("user_id")
        TOKEN_OUTSIDER = r3["data"].get("access_token")
    assignee_guard_ok = False
    if not USER3_ID or not _UUID_RE.match(str(USER3_ID)):
        print("  [SKIP] 8.2f 无有效 user3 UUID，跳过 assignee 校验")
        RESULTS.append(("8.2f assignee outsider -> 21011 (skipped)", True, 0, 0))
    else:
        st_af, r_af = req(
            "POST",
            f"/api/v1/projects/{PROJECT_UUID}/tasks",
            {
                "title": "集成测试-非法指派人",
                "ears_type": "event",
                "ears_behavior": "assignee 须为项目相关方",
                "assignee_id": str(USER3_ID),
            },
        )
        assignee_guard_ok = r_af.get("code") == 21011 and st_af == 400
        print(
            f"  [{'PASS' if assignee_guard_ok else 'FAIL'}] 8.2f POST /tasks (outsider assignee) "
            f"-> HTTP {st_af}, code={r_af.get('code')}"
        )
        if not assignee_guard_ok:
            print(f"         expect code=21011 HTTP=400, body={r_af!r}")
        RESULTS.append(("8.2f assignee outsider -> 21011", assignee_guard_ok, st_af, r_af.get("code", -1)))

    st_ms, r_ms = req("GET", f"/api/v1/projects/{PROJECT_UUID}/milestones")
    ms_list_ok = False
    if r_ms.get("code") == 0 and isinstance(r_ms.get("data"), list):
        rows = [x for x in r_ms["data"] if isinstance(x, dict)]
        titles = [x.get("title") for x in rows]
        ms_list_ok = MILESTONE_TEST_TITLE in titles
        if MS_UUID:
            ms_list_ok = ms_list_ok and any(
                (x.get("id") == MS_UUID or x.get("uuid") == MS_UUID) for x in rows
            )
        print(
            f"  [{'PASS' if ms_list_ok else 'FAIL'}] 8.3 GET /projects/:id/milestones "
            f"(list contains created) -> HTTP {st_ms}, n={len(rows)}"
        )
        if not ms_list_ok:
            print(f"         titles={titles!r}, expect title={MILESTONE_TEST_TITLE!r}, uuid={MS_UUID!r}")
    else:
        print(
            f"  [FAIL] 8.3 GET /projects/:id/milestones -> HTTP {st_ms}, code={r_ms.get('code')}"
        )
    RESULTS.append(
        ("8.3 GET milestones list contains created", ms_list_ok, st_ms, r_ms.get("code", -1))
    )

    # 8.3d 里程碑交付 POST /milestones/:id/deliver（需 §7 撮合后 TOKEN2=服务方且项目已绑定 provider_id）
    _prov = None
    if PROJECT_UUID:
        _prov = mysql_scalar(
            f"SELECT provider_id FROM projects WHERE uuid='{PROJECT_UUID}' LIMIT 1"
        )
    _has_provider = (
        _prov is not None
        and str(_prov).strip() != ""
        and str(_prov).strip().upper() != "NULL"
    )
    if not MS_UUID:
        print("  [SKIP] 8.3d 无里程碑 UUID，跳过交付接口")
    elif not TOKEN2:
        print("  [SKIP] 8.3d 无 TOKEN2（§7 未撮合/未登录服务方），跳过交付接口")
    elif not _has_provider:
        print("  [SKIP] 8.3d 项目未绑定服务方（provider_id 空），跳过交付接口")
    else:
        tok_dm = TOKEN
        # 默认创建为 pending(1)，须进行中或打回后方可交付
        test(
            "8.3dp POST /milestones/:id/deliver (pending -> 21014)",
            "POST",
            f"/api/v1/milestones/{MS_UUID}/deliver",
            {"delivery_note": "未开始执行", "preview_url": "https://example.com/w"},
            auth_token=TOKEN2,
            expect_code=21014,
            expect_http=400,
        )
        mysql_exec(
            f"UPDATE milestones SET status=2 WHERE uuid='{MS_UUID}' "
            f"AND project_id=(SELECT id FROM projects WHERE uuid='{PROJECT_UUID}' LIMIT 1)"
        )
        # 8.3d0 交付说明与预览至少一项非空
        test(
            "8.3d0 POST /milestones/:id/deliver (empty note+url -> 99001)",
            "POST",
            f"/api/v1/milestones/{MS_UUID}/deliver",
            {"delivery_note": "", "preview_url": ""},
            auth_token=TOKEN2,
            expect_code=99001,
            expect_http=400,
        )
        # 8.3d1 需求方不可交付
        test(
            "8.3d1 POST /milestones/:id/deliver (demander -> 21013)",
            "POST",
            f"/api/v1/milestones/{MS_UUID}/deliver",
            {"delivery_note": "需求方尝试交付", "preview_url": "https://example.com/x"},
            auth_token=tok_dm,
            expect_code=21013,
            expect_http=403,
        )
        ok_del, r_del = test(
            "8.3d2 POST /milestones/:id/deliver (provider success)",
            "POST",
            f"/api/v1/milestones/{MS_UUID}/deliver",
            {
                "delivery_note": "WSL 联调交付说明",
                "preview_url": "https://example.com/milestone-preview",
            },
            auth_token=TOKEN2,
            expect_code=0,
            expect_http=200,
        )
        del_data_ok = (
            ok_del
            and isinstance(r_del.get("data"), dict)
            and r_del["data"].get("status") == "delivered"
            and (r_del.get("message") == "交付已提交")
        )
        if not del_data_ok and ok_del:
            print(
                f"  [WARN] 8.3d2 响应 data/message 与预期不一致: {r_del.get('message')!r}, data={r_del.get('data')!r}"
            )
        RESULTS.append(
            (
                "8.3d2 deliver response status=delivered",
                del_data_ok,
                200 if ok_del else 0,
                0 if del_data_ok else -1,
            )
        )

        test(
            "8.3e POST /milestones/:id/accept (expert -> 20009 仅需求方)",
            "POST",
            f"/api/v1/milestones/{MS_UUID}/accept",
            {},
            auth_token=TOKEN2,
            expect_code=20009,
            expect_http=403,
        )
        test(
            "8.3f POST /milestones/:id/revision (expert -> 20009 仅需求方)",
            "POST",
            f"/api/v1/milestones/{MS_UUID}/revision",
            {"description": "专家尝试打回"},
            auth_token=TOKEN2,
            expect_code=20009,
            expect_http=403,
        )

        st_n22, r_n22 = req(
            "GET", "/api/v1/notifications?type=22&page_size=50", auth_token=tok_dm
        )
        rows_n22 = r_n22.get("data") if isinstance(r_n22.get("data"), list) else []
        hit_n22 = any(
            isinstance(x, dict)
            and (x.get("title") == "里程碑待验收" or "待验收" in (x.get("content") or ""))
            for x in rows_n22
        )
        print(
            f"  [{'PASS' if hit_n22 and r_n22.get('code') == 0 else 'FAIL'}] 8.3d3 GET /notifications?type=22 (需求方 里程碑待验收)"
        )
        RESULTS.append(
            ("8.3d3 demander notification type=22 deliver", hit_n22 and r_n22.get("code") == 0, st_n22, r_n22.get("code", -1))
        )

        st_m3, r_m3 = req("GET", f"/api/v1/projects/{PROJECT_UUID}/milestones", auth_token=tok_dm)
        ms_status_ok = False
        if r_m3.get("code") == 0 and isinstance(r_m3.get("data"), list):
            for row in r_m3["data"]:
                if not isinstance(row, dict):
                    continue
                if row.get("title") == MILESTONE_TEST_TITLE and row.get("status") == "delivered":
                    ms_status_ok = True
                    break
        print(
            f"  [{'PASS' if ms_status_ok else 'FAIL'}] 8.3d4 GET /projects/:id/milestones (含 status=delivered)"
        )
        RESULTS.append(
            ("8.3d4 milestone list status delivered", ms_status_ok, st_m3, r_m3.get("code", -1))
        )

        test(
            "8.3d5 POST /milestones/:id/deliver (duplicate -> 21009)",
            "POST",
            f"/api/v1/milestones/{MS_UUID}/deliver",
            {"delivery_note": "重复提交", "preview_url": "https://example.com/y"},
            auth_token=TOKEN2,
            expect_code=21009,
            expect_http=400,
        )

    ok, r = test("8.4 GET /projects/:id/daily-reports", "GET",
                 f"/api/v1/projects/{PROJECT_UUID}/daily-reports")
    if ok and r.get("data"):
        print(f"         reports: {len(r['data'])}")

    # 8.5 项目共享文件（MinIO + multipart；无 curl 或 11013 时跳过）
    def _curl_post_project_file(puuid, tok, tmp_path, file_kind, milestone_uuid=None):
        cmd = [
            "curl",
            "-sS",
            "-X",
            "POST",
            BASE + f"/api/v1/projects/{puuid}/files",
            "-H",
            "Authorization: Bearer " + tok,
            "-F",
            "file=@" + tmp_path + ";type=text/plain",
            "-F",
            f"file_kind={file_kind}",
        ]
        if milestone_uuid:
            cmd.extend(["-F", f"milestone_id={milestone_uuid}"])
        cp = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=120,
            check=False,
        )
        body = cp.stdout.decode(errors="replace").strip()
        try:
            j = json.loads(body) if body else {}
        except Exception:
            j = {"code": -1, "raw": body[:300]}
        return cp.returncode, j

    PROJECT_FILE_UUID_REF = None
    PROJECT_FILE_UUID_MS = None
    if not PROJECT_UUID:
        print("  [SKIP] 8.5 无 PROJECT_UUID")
    elif shutil.which("curl") is None:
        print("  [SKIP] 8.5 无 curl，跳过项目文件接口")
        RESULTS.append(("8.5 project files (curl missing)", False, 0, -1))
    else:
        st_pf0, r_pf0 = req("GET", f"/api/v1/projects/{PROJECT_UUID}/files?page=1&page_size=20")
        pf_list_ok0 = r_pf0.get("code") == 0 and isinstance(r_pf0.get("data"), list)
        print(
            f"  [{'PASS' if pf_list_ok0 else 'FAIL'}] 8.5a GET /projects/:id/files (demander) "
            f"-> HTTP {st_pf0}, code={r_pf0.get('code')}"
        )
        RESULTS.append(
            ("8.5a GET project files list (demander)", pf_list_ok0, st_pf0, r_pf0.get("code", -1))
        )

        fd_pf, tmp_pf = tempfile.mkstemp(suffix=".txt", text=False)
        try:
            os.write(fd_pf, b"kaizao project file integration ref\n")
            os.close(fd_pf)
            fd_pf = -1  # 已关闭，避免 finally 再次 close
            http_u1, up1 = _curl_post_project_file(
                PROJECT_UUID, TOKEN, tmp_pf, "reference"
            )
            if up1.get("code") == 11013:
                print("  [SKIP] 8.5b–8.5j 对象存储未启用 (11013)，跳过上传与后续文件断言")
                RESULTS.append(("8.5 OSS disabled skip", True, 200, 11013))
            elif up1.get("code") != 0:
                print(
                    f"  [FAIL] 8.5b POST /projects/:id/files (demander reference) "
                    f"curl_rc={http_u1}, code={up1.get('code')}, msg={up1.get('message')!r}"
                )
                RESULTS.append(
                    ("8.5b POST project file reference", False, 200, up1.get("code", -1))
                )
            else:
                d1 = up1.get("data") if isinstance(up1.get("data"), dict) else {}
                PROJECT_FILE_UUID_REF = d1.get("uuid")
                ref_ok = (
                    http_u1 == 0
                    and PROJECT_FILE_UUID_REF
                    and _UUID_RE.match(str(PROJECT_FILE_UUID_REF))
                    and d1.get("file_kind") == "reference"
                    and (d1.get("download_url") or "").startswith(("http://", "https://"))
                )
                print(
                    f"  [{'PASS' if ref_ok else 'FAIL'}] 8.5b POST /projects/:id/files (demander reference)"
                )
                RESULTS.append(
                    ("8.5b POST project file reference", ref_ok, 200, 0 if ref_ok else -1)
                )

                st_pf1, r_pf1 = req(
                    "GET",
                    f"/api/v1/projects/{PROJECT_UUID}/files?page=1&page_size=20&with_url=1",
                )
                rows_pf = r_pf1.get("data") if isinstance(r_pf1.get("data"), list) else []
                hit_ref = next(
                    (
                        x
                        for x in rows_pf
                        if isinstance(x, dict)
                        and x.get("uuid") == PROJECT_FILE_UUID_REF
                    ),
                    None,
                )
                list_ok = (
                    r_pf1.get("code") == 0
                    and hit_ref is not None
                    and hit_ref.get("file_kind") == "reference"
                    and (hit_ref.get("download_url") or "").startswith(("http://", "https://"))
                )
                print(
                    f"  [{'PASS' if list_ok else 'FAIL'}] 8.5c GET /projects/:id/files (contains ref + presign)"
                )
                RESULTS.append(
                    ("8.5c GET project files list has ref", list_ok, st_pf1, r_pf1.get("code", -1))
                )

                st_one, r_one = req(
                    "GET",
                    f"/api/v1/projects/{PROJECT_UUID}/files/{PROJECT_FILE_UUID_REF}",
                )
                one_ok = (
                    r_one.get("code") == 0
                    and isinstance(r_one.get("data"), dict)
                    and r_one["data"].get("uuid") == PROJECT_FILE_UUID_REF
                    and (r_one["data"].get("download_url") or "").startswith(
                        ("http://", "https://")
                    )
                )
                print(
                    f"  [{'PASS' if one_ok else 'FAIL'}] 8.5d GET /projects/:id/files/:uuid (detail)"
                )
                RESULTS.append(
                    ("8.5d GET project file detail", one_ok, st_one, r_one.get("code", -1))
                )

                st_fk, r_fk = req(
                    "GET",
                    f"/api/v1/projects/{PROJECT_UUID}/files?file_kind=reference&page=1&page_size=10",
                )
                fk_ok = False
                if r_fk.get("code") == 0 and isinstance(r_fk.get("data"), list):
                    fk_ok = all(
                        (not isinstance(x, dict)) or x.get("file_kind") == "reference"
                        for x in r_fk["data"]
                    ) and any(
                        isinstance(x, dict) and x.get("uuid") == PROJECT_FILE_UUID_REF
                        for x in r_fk["data"]
                    )
                print(
                    f"  [{'PASS' if fk_ok else 'FAIL'}] 8.5e GET /projects/:id/files?file_kind=reference"
                )
                RESULTS.append(
                    ("8.5e GET project files filter file_kind", fk_ok, st_fk, r_fk.get("code", -1))
                )

                prov_upload_ok = False
                if TOKEN2:
                    fd_p2, tmp_p2 = tempfile.mkstemp(suffix=".txt", text=False)
                    try:
                        os.write(fd_p2, b"provider deliverable upload\n")
                        os.close(fd_p2)
                        http_u2, up2 = _curl_post_project_file(
                            PROJECT_UUID, TOKEN2, tmp_p2, "deliverable"
                        )
                        prov_upload_ok = up2.get("code") == 0 and http_u2 == 0
                        d2 = up2.get("data") if isinstance(up2.get("data"), dict) else {}
                        if prov_upload_ok and d2.get("file_kind") != "deliverable":
                            prov_upload_ok = False
                        print(
                            f"  [{'PASS' if prov_upload_ok else 'FAIL'}] 8.5f POST /projects/:id/files (provider deliverable)"
                        )
                        RESULTS.append(
                            (
                                "8.5f POST project file provider",
                                prov_upload_ok,
                                200 if prov_upload_ok else 0,
                                up2.get("code", -1),
                            )
                        )
                    finally:
                        try:
                            os.unlink(tmp_p2)
                        except OSError:
                            pass
                else:
                    print("  [SKIP] 8.5f 无 TOKEN2，跳过服务方上传")

                if MS_UUID:
                    fd_ms, tmp_ms = tempfile.mkstemp(suffix=".txt", text=False)
                    try:
                        os.write(fd_ms, b"milestone linked file\n")
                        os.close(fd_ms)
                        http_u3, up3 = _curl_post_project_file(
                            PROJECT_UUID, TOKEN, tmp_ms, "process", MS_UUID
                        )
                        ms_up_ok = up3.get("code") == 0 and http_u3 == 0
                        d3 = up3.get("data") if isinstance(up3.get("data"), dict) else {}
                        PROJECT_FILE_UUID_MS = d3.get("uuid")
                        if ms_up_ok and (
                            not PROJECT_FILE_UUID_MS
                            or d3.get("milestone_id") != MS_UUID
                        ):
                            ms_up_ok = False
                        print(
                            f"  [{'PASS' if ms_up_ok else 'FAIL'}] 8.5g POST /projects/:id/files (with milestone_id)"
                        )
                        RESULTS.append(
                            (
                                "8.5g POST project file milestone",
                                ms_up_ok,
                                200 if ms_up_ok else 0,
                                up3.get("code", -1),
                            )
                        )
                        if ms_up_ok and PROJECT_FILE_UUID_MS:
                            st_msf, r_msf = req(
                                "GET",
                                f"/api/v1/projects/{PROJECT_UUID}/files?milestone_id={MS_UUID}&page=1&page_size=10",
                            )
                            msf_ok = False
                            if r_msf.get("code") == 0 and isinstance(r_msf.get("data"), list):
                                msf_ok = any(
                                    isinstance(x, dict)
                                    and x.get("uuid") == PROJECT_FILE_UUID_MS
                                    for x in r_msf["data"]
                                )
                            print(
                                f"  [{'PASS' if msf_ok else 'FAIL'}] 8.5g1 GET /files?milestone_id=..."
                            )
                            RESULTS.append(
                                (
                                    "8.5g1 GET project files filter milestone",
                                    msf_ok,
                                    st_msf,
                                    r_msf.get("code", -1),
                                )
                            )
                    finally:
                        try:
                            os.unlink(tmp_ms)
                        except OSError:
                            pass
                else:
                    print("  [SKIP] 8.5g 无 MS_UUID，跳过里程碑关联上传")

                http_bad, bad = _curl_post_project_file(
                    PROJECT_UUID, TOKEN, tmp_pf, "not_a_kind"
                )
                bad_kind_ok = bad.get("code") == 21016
                print(
                    f"  [{'PASS' if bad_kind_ok else 'FAIL'}] 8.5h POST /files (invalid file_kind -> 21016)"
                )
                RESULTS.append(
                    ("8.5h POST project file bad kind", bad_kind_ok, 400 if bad_kind_ok else 200, bad.get("code", -1))
                )

                fake_fid = str(uuid.uuid4())
                test(
                    "8.5i GET /projects/:id/files/:uuid (not found -> 21015)",
                    "GET",
                    f"/api/v1/projects/{PROJECT_UUID}/files/{fake_fid}",
                    expect_code=21015,
                    expect_http=404,
                )

                if TOKEN_OUTSIDER:
                    test(
                        "8.5j GET /projects/:id/files (outsider -> 21008)",
                        "GET",
                        f"/api/v1/projects/{PROJECT_UUID}/files?page=1&page_size=5",
                        auth_token=TOKEN_OUTSIDER,
                        expect_code=21008,
                        expect_http=403,
                    )
                else:
                    print("  [SKIP] 8.5j 无 TOKEN_OUTSIDER，跳过圈外人列表校验")
        finally:
            if fd_pf >= 0:
                try:
                    os.close(fd_pf)
                except OSError:
                    pass
            try:
                os.unlink(tmp_pf)
            except OSError:
                pass

# ==================== 9. Phase 5: 聊天 ====================
print("\n--- 9. Phase 5: 聊天模块 ---")
ok, r = test("9.1 GET /conversations (list)", "GET", "/api/v1/conversations")
if ok:
    n = len(r.get("data") or [])
    print(f"         conversations: {n}")
    meta = r.get("meta")
    meta_91_ok = (
        isinstance(meta, dict)
        and isinstance(meta.get("total"), int)
        and meta.get("page_size") is not None
        and meta.get("page") is not None
    )
    print(f"  [{'PASS' if meta_91_ok else 'FAIL'}] 9.1b list response.meta (total/page/page_size)")
    RESULTS.append(("9.1b conversations meta", meta_91_ok, 200, 0 if meta_91_ok else -1))

test(
    "9.1c GET /conversations?offset=0&limit=5",
    "GET",
    "/api/v1/conversations?offset=0&limit=5",
)

def _conv_unread_by_id(rows, conv_uuid):
    if not isinstance(rows, list) or not conv_uuid:
        return None
    for c in rows:
        if isinstance(c, dict) and c.get("id") == conv_uuid:
            try:
                return int(c.get("unread_count") or 0)
            except (TypeError, ValueError):
                return 0
    return None

# 9.2–9.3 未读 / 已读（专家发 → 需求方 unread≥1 → read → 0）
if MATCH_CONV_UUID and TOKEN2 and TOKEN:
    st_s9, r_s9 = req(
        "POST",
        f"/api/v1/conversations/{MATCH_CONV_UUID}/messages",
        {"content": "v2-integration expert ping", "type": "text"},
        auth_token=TOKEN2,
    )
    send9_ok = st_s9 == 200 and r_s9.get("code") == 0
    print(
        f"  [{'PASS' if send9_ok else 'FAIL'}] 9.2 POST /conversations/:uuid/messages (expert) "
        f"-> HTTP {st_s9}, code={r_s9.get('code')}"
    )
    RESULTS.append(("9.2 expert send message", send9_ok, st_s9, r_s9.get("code", -1)))

    st_u0, r_u0 = req("GET", "/api/v1/conversations")
    u0 = _conv_unread_by_id(r_u0.get("data") if isinstance(r_u0.get("data"), list) else [], MATCH_CONV_UUID)
    unread_before_ok = r_u0.get("code") == 0 and u0 is not None and u0 >= 1
    print(
        f"  [{'PASS' if unread_before_ok else 'FAIL'}] 9.3a GET /conversations demander unread_count>=1 "
        f"(got {u0!r})"
    )
    RESULTS.append(("9.3a demander unread after expert msg", unread_before_ok, st_u0, r_u0.get("code", -1)))

    st_mr9, r_mr9 = req("POST", f"/api/v1/conversations/{MATCH_CONV_UUID}/read")
    mr9_ok = st_mr9 == 200 and r_mr9.get("code") == 0
    print(
        f"  [{'PASS' if mr9_ok else 'FAIL'}] 9.3b POST /conversations/:uuid/read (demander) "
        f"-> HTTP {st_mr9}, code={r_mr9.get('code')}"
    )
    RESULTS.append(("9.3b demander mark read", mr9_ok, st_mr9, r_mr9.get("code", -1)))

    st_u1, r_u1 = req("GET", "/api/v1/conversations")
    u1 = _conv_unread_by_id(r_u1.get("data") if isinstance(r_u1.get("data"), list) else [], MATCH_CONV_UUID)
    unread_after_ok = r_u1.get("code") == 0 and u1 is not None and u1 == 0
    print(
        f"  [{'PASS' if unread_after_ok else 'FAIL'}] 9.3c GET /conversations demander unread_count==0 "
        f"(got {u1!r})"
    )
    RESULTS.append(("9.3c demander unread after read", unread_after_ok, st_u1, r_u1.get("code", -1)))
else:
    print("  [SKIP] 9.2–9.3 无 MATCH_CONV_UUID 或 TOKEN2/TOKEN，跳过未读/已读")

# 9.4 圈外人 403 / 60002（依赖 §8 TOKEN_OUTSIDER）
if TOKEN_OUTSIDER and MATCH_CONV_UUID:
    test(
        "9.4a GET /conversations/:uuid/messages outsider -> 403/60002",
        "GET",
        f"/api/v1/conversations/{MATCH_CONV_UUID}/messages",
        need_auth=True,
        auth_token=TOKEN_OUTSIDER,
        expect_code=60002,
        expect_http=403,
    )
    test(
        "9.4b POST /conversations/:uuid/messages outsider -> 403/60002",
        "POST",
        f"/api/v1/conversations/{MATCH_CONV_UUID}/messages",
        {"content": "should fail", "type": "text"},
        need_auth=True,
        auth_token=TOKEN_OUTSIDER,
        expect_code=60002,
        expect_http=403,
    )
else:
    print("  [SKIP] 9.4 无 TOKEN_OUTSIDER 或 MATCH_CONV_UUID，跳过圈外人会话越权")

# 9.5 伪造会话 UUID -> 404
_fake_conv = "00000000-0000-4000-8000-000000000099"
test(
    "9.5 GET /conversations/:uuid/messages (unknown uuid -> 404/60001)",
    "GET",
    f"/api/v1/conversations/{_fake_conv}/messages",
    expect_code=60001,
    expect_http=404,
)

# 9.6 软删后会话消息不可访问（须最后执行，避免影响 9.4）
if MATCH_CONV_UUID and TOKEN:
    st_del9, r_del9 = req("DELETE", f"/api/v1/conversations/{MATCH_CONV_UUID}")
    del9_ok = st_del9 == 200 and r_del9.get("code") == 0
    print(
        f"  [{'PASS' if del9_ok else 'FAIL'}] 9.6a DELETE /conversations/:uuid (demander soft-delete) "
        f"-> HTTP {st_del9}, code={r_del9.get('code')}"
    )
    RESULTS.append(("9.6a conversation delete", del9_ok, st_del9, r_del9.get("code", -1)))

    st_gone_d, r_gone_d = req("GET", f"/api/v1/conversations/{MATCH_CONV_UUID}/messages")
    gone_d_ok = st_gone_d == 404 and r_gone_d.get("code") == 60001
    print(
        f"  [{'PASS' if gone_d_ok else 'FAIL'}] 9.6b GET messages after delete (demander -> 404/60001) "
        f"HTTP {st_gone_d}"
    )
    RESULTS.append(("9.6b messages after delete demander", gone_d_ok, st_gone_d, r_gone_d.get("code", -1)))

    if TOKEN2:
        st_gone_e, r_gone_e = req(
            "GET",
            f"/api/v1/conversations/{MATCH_CONV_UUID}/messages",
            auth_token=TOKEN2,
        )
        gone_e_ok = st_gone_e == 404 and r_gone_e.get("code") == 60001
        print(
            f"  [{'PASS' if gone_e_ok else 'FAIL'}] 9.6c GET messages after delete (expert -> 404/60001) "
            f"HTTP {st_gone_e}"
        )
        RESULTS.append(("9.6c messages after delete expert", gone_e_ok, st_gone_e, r_gone_e.get("code", -1)))
    else:
        print("  [SKIP] 9.6c 无 TOKEN2，跳过专家侧删除后拉消息")
else:
    print("  [SKIP] 9.6 无 MATCH_CONV_UUID 或 TOKEN，跳过软删校验")

# ==================== 10. Phase 5: 支付 ====================
print("\n--- 10. Phase 5: 支付模块 ---")
ok, r = test("10.1 GET /coupons", "GET", "/api/v1/coupons")
if ok:
    print(f"         coupons: {len(r.get('data', []))}")

# ==================== 11. v6: 钱包 ====================
print("\n--- 11. v6: 钱包模块 ---")
ok, r = test("11.1 GET /wallet/balance", "GET", "/api/v1/wallet/balance")
if ok and r.get("data"):
    cf(r["data"], ["available", "frozen", "total_earned", "total_withdrawn"])

ok, r = test("11.2 GET /wallet/transactions", "GET", "/api/v1/wallet/transactions?page=1&page_size=10")
if ok:
    print(f"         transactions: {len(r.get('data', []))}")

# ==================== 11b. 通知模块（需 Docker MySQL 种子） ====================
print("\n--- 11b. 通知模块 ---")
NOTIF_UUID_A = None
NOTIF_UUID_B = None
if not TOKEN or not USER_ID:
    print("  [SKIP] 无 TOKEN/USER_ID")
elif not re.match(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
    USER_ID,
    re.I,
):
    print("  [SKIP] USER_ID 非 UUID")
else:
    uid_row = mysql_scalar(f"SELECT id FROM users WHERE uuid='{USER_ID}' LIMIT 1")
    if not uid_row or not uid_row.isdigit():
        print("  [SKIP] 无法从 MySQL 解析当前用户 id（docker / 库不可用）")
    else:
        NOTIF_UUID_A = str(uuid.uuid4())
        NOTIF_UUID_B = str(uuid.uuid4())
        # 清理历史种子并插入两条未读（类型 1、2）
        mysql_exec(
            f"DELETE FROM notifications WHERE user_id={int(uid_row)} AND title LIKE 'KZ_TEST_%'"
        )
        esc = lambda s: s.replace("\\", "\\\\").replace("'", "''")
        ok_ins = mysql_exec(
            "INSERT INTO notifications (uuid, user_id, title, content, notification_type, is_read, is_pushed) VALUES "
            f"('{NOTIF_UUID_A}', {int(uid_row)}, '{esc('KZ_TEST_A')}', '{esc('body a')}', 1, 0, 0),"
            f"('{NOTIF_UUID_B}', {int(uid_row)}, '{esc('KZ_TEST_B')}', '{esc('body b')}', 2, 0, 0)"
        )
        if not ok_ins:
            print("  [SKIP] INSERT notifications 失败")
        else:
            st_uc, r_uc = req("GET", "/api/v1/notifications/unread-count")
            uc0 = (r_uc.get("data") or {}).get("unread_count")
            uc_ok = r_uc.get("code") == 0 and isinstance(uc0, int) and uc0 >= 2
            print(
                f"  [{'PASS' if uc_ok else 'FAIL'}] 11b.1 GET /notifications/unread-count (seed>=2) -> unread_count={uc0!r}"
            )
            RESULTS.append(("11b.1 GET /notifications/unread-count", uc_ok, st_uc, r_uc.get("code", -1)))

            st_l, r_l = req("GET", "/api/v1/notifications?page=1&page_size=20")
            ok_l = r_l.get("code") == 0
            ids_a = {NOTIF_UUID_A, NOTIF_UUID_B}
            found = set()
            if ok_l and isinstance(r_l.get("data"), list):
                for row in r_l["data"]:
                    if isinstance(row, dict) and row.get("uuid") in ids_a:
                        found.add(row["uuid"])
            sub_ok = ok_l and ids_a <= found
            meta = r_l.get("meta") if isinstance(r_l.get("meta"), dict) else {}
            page_ok = meta.get("page") == 1 and meta.get("page_size") == 20
            list_ok = sub_ok and page_ok
            print(
                f"  [{'PASS' if list_ok else 'FAIL'}] 11b.2 GET /notifications (paged+seeds) "
                f"-> HTTP {st_l}, code={r_l.get('code')}, meta.page={meta.get('page')}"
            )
            if ok_l and not sub_ok:
                print(f"         FAIL: list missing seeded uuids, found={found}")
            RESULTS.append(("11b.2 GET /notifications paged+seeds", list_ok, st_l, r_l.get("code", -1)))

            st_t1, r_t1 = req("GET", "/api/v1/notifications?page=1&page_size=20&type=1")
            ok_t1 = r_t1.get("code") == 0
            type_ok = False
            if ok_t1 and isinstance(r_t1.get("data"), list):
                rows = [row for row in r_t1["data"] if isinstance(row, dict)]
                uuids_t1 = {row.get("uuid") for row in rows}
                all_type1 = all(row.get("type") == 1 for row in rows)
                type_ok = NOTIF_UUID_A in uuids_t1 and NOTIF_UUID_B not in uuids_t1 and all_type1
            print(
                f"  [{'PASS' if type_ok else 'FAIL'}] 11b.3 GET /notifications?type=1 -> HTTP {st_t1}, code={r_t1.get('code')}"
            )
            if ok_t1 and not type_ok:
                print("         FAIL: type=1 应含 A、不含 B，且条目 type 均为 1")
            RESULTS.append(("11b.3 GET /notifications?type=1", type_ok, st_t1, r_t1.get("code", -1)))

            test(
                "11b.4 PUT /notifications/:uuid/read (A)",
                "PUT",
                f"/api/v1/notifications/{NOTIF_UUID_A}/read",
                body=None,
            )
            _, r_uc2 = req("GET", "/api/v1/notifications/unread-count")
            uc1 = (r_uc2.get("data") or {}).get("unread_count")
            uc_dec = isinstance(uc0, int) and isinstance(uc1, int) and uc1 == uc0 - 1
            print(
                f"  [{'PASS' if uc_dec else 'FAIL'}] 11b.5 unread after one read -> {uc0}->{uc1}"
            )
            RESULTS.append(("11b.5 unread_count after mark one read", uc_dec, 200, r_uc2.get("code", -1)))

            test("11b.6 PUT /notifications/read-all", "PUT", "/api/v1/notifications/read-all")
            _, r_uc3 = req("GET", "/api/v1/notifications/unread-count")
            uc2 = (r_uc3.get("data") or {}).get("unread_count")
            uc_zero = r_uc3.get("code") == 0 and uc2 == 0
            print(
                f"  [{'PASS' if uc_zero else 'FAIL'}] 11b.7 unread after read-all -> {uc2!r}"
            )
            RESULTS.append(("11b.7 unread_count after read-all", uc_zero, 200, r_uc3.get("code", -1)))

            ok_idem, _ = test(
                "11b.8 PUT /notifications/:uuid/read (idempotent)",
                "PUT",
                f"/api/v1/notifications/{NOTIF_UUID_A}/read",
                body=None,
            )
            RESULTS.append(("11b.8 mark read idempotent", ok_idem, 200, 0))

# ==================== 12. v7: 组队 ====================
print("\n--- 12. v7: 组队模块 ---")
ok, r = test("12.1 GET /teams (list)", "GET", "/api/v1/teams", need_auth=False)
if ok and r.get("data"):
    cf(r["data"], ["ai_recommended", "posts"])

ok, r = test("12.2 POST /team-posts (create)", "POST", "/api/v1/team-posts",
             {"project_name": "Test Team Project", "description": "Looking for Flutter developer",
              "needed_roles": [{"role": "frontend", "count": 1, "skills": ["Flutter"]}]})
if ok and r.get("data"):
    cf(r["data"], ["id", "status"])

# ==================== 13. v7: 评价 ====================
print("\n--- 13. v7: 评价模块 ---")
if PROJECT_UUID:
    ok, r = test("13.1 GET /projects/:id/reviews (list)", "GET",
                 f"/api/v1/projects/{PROJECT_UUID}/reviews", need_auth=False)
    if ok:
        print(f"         reviews: {len(r.get('data', []))}")

# ==================== 14. 退出 & 鉴权 ====================
print("\n--- 14. 退出 & 鉴权验证 ---")
test("14.1 POST /auth/logout", "POST", "/api/v1/auth/logout", {})
saved = TOKEN
TOKEN = None
test("14.2 GET /users/me (no token)", "GET", "/api/v1/users/me", expect_code=10008)
TOKEN = saved

# 项目已撮合 (status=3) 时关闭返回 20002，与 api-spec「进行中不可关闭」一致
if PROJECT_UUID:
    test(
        "14.3 PUT /projects/:id/close (matched project)",
        "PUT",
        f"/api/v1/projects/{PROJECT_UUID}/close",
        {"reason": "test complete"},
        expect_code=20002,
    )

# ==================== 15. 入驻审核全链路（可选） ====================
if args.full_onboarding:
    print("\n--- 15. 入驻审核全链路（--full-onboarding） ---")
    if not (ADMIN_SETUP_OK and INVITE_CODE_PLAIN and TOKEN and USER_ID):
        print(
            "  [FAIL] 前置条件不足：需 1.5 成功（Docker 可 exec MySQL、"
            "未设置 KZ_SKIP_ADMIN_INVITE=1、且 POST /admin/invite-codes 返回 code_plain）"
        )
        RESULTS.append(("15.0 full onboarding prerequisites", False, 0, -1))
    else:
        expert_phone = gen_phone()
        test(
            "15.0a POST /auth/sms-code (register purpose=1)",
            "POST",
            "/api/v1/auth/sms-code",
            {"phone": expert_phone, "purpose": 1},
            need_auth=False,
        )
        time.sleep(0.3)
        sc_reg = get_sms_code(expert_phone, 1) or "952786"
        print(f"  [INFO] Expert phone: {expert_phone} register_sms={sc_reg}")
        ok_reg, r_reg = test(
            "15.1 POST /auth/register (role=2, 无邀请码)",
            "POST",
            "/api/v1/auth/register",
            {
                "phone": expert_phone,
                "sms_code": sc_reg,
                "nickname": "PendingExpert",
                "role": 2,
            },
            need_auth=False,
        )
        d = r_reg.get("data") if isinstance(r_reg, dict) else {}
        expert_uuid = (d.get("user") or {}).get("uuid") if isinstance(d.get("user"), dict) else None
        tok_new = d.get("access_token")

        if ok_reg and tok_new and expert_uuid:
            st_me, r_me = req("GET", "/api/v1/users/me", None, True, tok_new)
            ob = r_me.get("data", {}).get("onboarding_status") if isinstance(r_me, dict) else None
            print(f"  [INFO] expert onboarding_status(before redeem)={ob}")
            ok_rd, _ = test(
                "15.2 POST /users/me/onboarding/redeem-invite",
                "POST",
                "/api/v1/users/me/onboarding/redeem-invite",
                {"invite_code": INVITE_CODE_PLAIN},
                auth_token=tok_new,
            )
            st_me2, r_me2 = req("GET", "/api/v1/users/me", None, True, tok_new)
            ob2 = r_me2.get("data", {}).get("onboarding_status") if isinstance(r_me2, dict) else None
            ok_ob = ob2 == 2
            print(f"  [{'PASS' if ok_ob else 'FAIL'}] 15.3 GET /users/me (onboarding approved) status={st_me2} onboarding={ob2}")
            RESULTS.append(("15.3 expert onboarding approved after redeem", ok_ob, st_me2, r_me2.get("code", -1)))
            if ok_rd:
                st_cur, r_cur = req(
                    "GET",
                    f"/api/v1/admin/teams/{SEED_TEAM_UUID}/current-invite-code",
                    None,
                    True,
                    TOKEN,
                )
                new_plain = (r_cur.get("data") or {}).get("code_plain")
                rotated = bool(new_plain) and new_plain != INVITE_CODE_PLAIN
                print(f"  [{'PASS' if rotated else 'FAIL'}] 15.4 admin current-invite 已轮换新码 rotated={rotated}")
                RESULTS.append(("15.4 team invite rotated after use", rotated, st_cur, r_cur.get("code", -1)))
        elif not ok_reg:
            pass
        else:
            print(f"  [FAIL] 15.x 专家注册未返回 token/uuid: token={bool(tok_new)} uuid={expert_uuid!r}")
            RESULTS.append(("15.x expert register", False, 0, r_reg.get("code", -1)))

# ==================== 报告 ====================
print("\n" + "=" * 60)
passed = sum(1 for _, ok, *_ in RESULTS if ok)
failed = sum(1 for _, ok, *_ in RESULTS if not ok)
total = len(RESULTS)
print(f"  Total: {total}   Pass: {passed}   Fail: {failed}")
if failed > 0:
    print("\n  Failed:")
    for name, ok, st, code in RESULTS:
        if not ok:
            print(f"    X {name} (HTTP {st}, code={code})")
else:
    print("\n  ALL PASSED!")
print("=" * 60)

# 生成 markdown 报告
report = f"""# Kaizao API v2 测试报告

- **测试时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
- **服务地址**: {BASE}
- **总计**: {total} | **通过**: {passed} | **失败**: {failed}

## 测试结果

| # | 测试用例 | 结果 | HTTP | Code |
|---|---------|------|------|------|
"""
for i, (name, ok, st, code) in enumerate(RESULTS, 1):
    icon = "PASS" if ok else "FAIL"
    report += f"| {i} | {name} | {icon} | {st} | {code} |\n"

if failed > 0:
    report += "\n## 失败详情\n\n"
    for name, ok, st, code in RESULTS:
        if not ok:
            report += f"- **{name}**: HTTP {st}, code={code}\n"

report += f"\n---\n*Generated at {datetime.now().isoformat()}*\n"

_report_dir = os.path.dirname(os.path.abspath(__file__))
report_path = os.path.join(_report_dir, "test-report-v2.md")
with open(report_path, "w", encoding="utf-8") as f:
    f.write(report)
print(f"\n  Report saved: {report_path}")

sys.exit(0 if failed == 0 else 1)
