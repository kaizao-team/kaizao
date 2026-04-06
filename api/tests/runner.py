#!/usr/bin/env python3
"""
Kaizao API v2 集成测试 — 顺序运行入口

用法（与原 test_api_v2.py 等价）：
  python -m tests.runner --base http://localhost:8080
  python -m tests.runner --full-onboarding
  python -m tests.runner --test-new-apis

也可通过顶层兼容脚本调用：
  python test_api_v2.py [原有参数]
"""
import argparse
import os
import sys
from datetime import datetime

from . import state
from .test_01_auth import run as run_auth
from .test_02_users import run as run_users
from .test_03_projects import run as run_projects
from .test_04_home import run as run_home
from .test_05_market import run as run_market
from .test_06_publish import run as run_publish
from .test_07_bidding import run as run_bidding
from .test_08_pm import run as run_pm
from .test_09_chat import run as run_chat
from .test_10_pay_wallet import run as run_pay_wallet
from .test_11_notif import run as run_notif
from .test_12_teams import run as run_teams
from .test_13_auth_exit import run as run_auth_exit
from .test_14_onboarding import run as run_onboarding


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", default="http://localhost:8080")
    parser.add_argument("--redis-container", default="kaizao-redis")
    parser.add_argument("--redis-password", default="redis123")
    parser.add_argument("--server-container", default="kaizao-server")
    parser.add_argument("--mysql-container", default="kaizao-mysql")
    parser.add_argument("--mysql-user", default="kaizao")
    parser.add_argument("--mysql-password", default="kaizao123")
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
    return parser.parse_args()


def init_state(args):
    state.BASE = args.base
    state.REDIS_CONTAINER = args.redis_container
    state.REDIS_PASSWORD = args.redis_password
    state.MYSQL_CONTAINER = args.mysql_container
    state.MYSQL_USER = args.mysql_user
    state.MYSQL_PASSWORD = args.mysql_password
    state.MYSQL_DB = args.mysql_db
    state.FULL_ONBOARDING = args.full_onboarding
    state.TEST_NEW_APIS = args.test_new_apis


def print_report():
    print("\n" + "=" * 60)
    passed = sum(1 for _, ok, *_ in state.RESULTS if ok)
    failed = sum(1 for _, ok, *_ in state.RESULTS if not ok)
    total = len(state.RESULTS)
    print(f"  Total: {total}   Pass: {passed}   Fail: {failed}")
    if failed > 0:
        print("\n  Failed:")
        for name, ok, st, code in state.RESULTS:
            if not ok:
                print(f"    X {name} (HTTP {st}, code={code})")
    else:
        print("\n  ALL PASSED!")
    print("=" * 60)

    report = f"""# Kaizao API v2 测试报告

- **测试时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
- **服务地址**: {state.BASE}
- **总计**: {total} | **通过**: {passed} | **失败**: {failed}

## 测试结果

| # | 测试用例 | 结果 | HTTP | Code |
|---|---------|------|------|------|
"""
    for i, (name, ok, st, code) in enumerate(state.RESULTS, 1):
        icon = "PASS" if ok else "FAIL"
        report += f"| {i} | {name} | {icon} | {st} | {code} |\n"

    if failed > 0:
        report += "\n## 失败详情\n\n"
        for name, ok, st, code in state.RESULTS:
            if not ok:
                report += f"- **{name}**: HTTP {st}, code={code}\n"

    report += f"\n---\n*Generated at {datetime.now().isoformat()}*\n"

    _report_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    report_path = os.path.join(_report_dir, "test-report-v2.md")
    with open(report_path, "w", encoding="utf-8") as f:
        f.write(report)
    print(f"\n  Report saved: {report_path}")

    return failed


def main():
    args = parse_args()
    init_state(args)

    run_auth()
    run_users()
    run_projects()
    run_home()
    run_market()
    run_publish()
    run_bidding()
    run_pm()
    run_chat()
    run_pay_wallet()
    run_notif()
    run_teams()
    run_auth_exit()
    run_onboarding()

    failed = print_report()
    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()
