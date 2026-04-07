"""Global mutable state shared across all test modules."""

import os

def _env(key: str, default: str) -> str:
    v = os.environ.get(key)
    return (v.strip() if v else "") or default


# CLI args（由 runner 覆盖；默认值与 docker-compose.wsl.yml / wsl_deploy_test.sh 一致）
BASE = "http://localhost:8080"
REDIS_CONTAINER = _env("KAIZAO_REDIS_CONTAINER", "kaizao-wsl-redis")
REDIS_PASSWORD = _env("KAIZAO_REDIS_PASSWORD", "redis123")
MYSQL_CONTAINER = _env("KAIZAO_MYSQL_CONTAINER", "kaizao-wsl-mysql")
MYSQL_USER = "kaizao"
MYSQL_PASSWORD = _env("KAIZAO_MYSQL_PASSWORD", "kaizao_prod_2026")
MYSQL_DB = "kaizao"
FULL_ONBOARDING = False
TEST_NEW_APIS = False

# Auth state
TOKEN = None
REFRESH_TOKEN = None
USER_ID = None
# 主账号登录手机号（§7 第二用户须不同号，避免撞号导致同用户投标 30002）
LOGIN_PHONE = None
TOKEN2 = None
USER2_ID = None
USER2_NICKNAME = None
TOKEN_OUTSIDER = None

# Test results
RESULTS = []

# Project state
PROJECT_UUID = None
PROJECT_DISPLAY_TITLE = "Test Flutter App V2"
DRAFT_PUBLISH_UUID = None
PROJECT_WITHDRAW_UUID = None

# Bidding state
BID_UUID = None
BID_WITHDRAW_UUID = None

# Conversation state
MATCH_CONV_UUID = None

# Admin/onboarding state
INVITE_CODE_PLAIN = None
ADMIN_SETUP_OK = False
SEED_TEAM_UUID = "11111111-1111-1111-1111-111111111111"

# Expert/market state
EXPERT_UUID_FOR_FAV = None
EXPERT_TEAM_UUID = None

# Milestone/task state
MS_UUID = None
MILESTONE_TEST_TITLE = "集成测试里程碑-阶段一"
TASK_TEST_TITLE = "集成测试-手动任务"
TASK_CREATE_UUID = None

# Portfolio state
PORTFOLIO_TEST_UUID = None

# Notification state
NOTIF_UUID_A = None
NOTIF_UUID_B = None

# Password auth state
PW_FLOW_PASSWORD = "Abcd1234"
USERNAME_PW_REG = None

# Project file state
PROJECT_FILE_UUID_REF = None
PROJECT_FILE_UUID_MS = None
