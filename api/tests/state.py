"""Global mutable state shared across all test modules."""

# CLI args (set by runner)
BASE = "http://localhost:8080"
REDIS_CONTAINER = "kaizao-redis"
REDIS_PASSWORD = "redis123"
MYSQL_CONTAINER = "kaizao-mysql"
MYSQL_USER = "kaizao"
MYSQL_PASSWORD = "kaizao123"
MYSQL_DB = "kaizao"
FULL_ONBOARDING = False
TEST_NEW_APIS = False

# Auth state
TOKEN = None
REFRESH_TOKEN = None
USER_ID = None
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
