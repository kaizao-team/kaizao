"""10. Phase 5: 支付 + 11. v6: 钱包"""

from . import state
from .helpers import req, test, cf


def run():
    print("\n--- 10. Phase 5: 支付模块 ---")
    ok, r = test("10.1 GET /coupons", "GET", "/api/v1/coupons")
    if ok:
        print(f"         coupons: {len(r.get('data', []))}")

    print("\n--- 11. v6: 钱包模块 ---")
    ok, r = test("11.1 GET /wallet/balance", "GET", "/api/v1/wallet/balance")
    if ok and r.get("data"):
        cf(r["data"], ["available", "frozen", "total_earned", "total_withdrawn"])

    ok, r = test("11.2 GET /wallet/transactions", "GET", "/api/v1/wallet/transactions?page=1&page_size=10")
    if ok:
        print(f"         transactions: {len(r.get('data', []))}")
