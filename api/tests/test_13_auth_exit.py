"""14. 退出 & 鉴权"""

from . import state
from .helpers import req, test, cf


def run():
    print("\n--- 14. 退出 & 鉴权验证 ---")
    test("14.1 POST /auth/logout", "POST", "/api/v1/auth/logout", {})
    saved = state.TOKEN
    state.TOKEN = None
    test("14.2 GET /users/me (no token)", "GET", "/api/v1/users/me", expect_code=10008)
    state.TOKEN = saved

    # 项目已撮合 (status=3) 时关闭返回 20002；未撮合时关闭可能成功 (code=0)，与 §7.4 是否跑通有关
    if state.PROJECT_UUID:
        st_p, r_p = req("GET", f"/api/v1/projects/{state.PROJECT_UUID}")
        pstatus = None
        if r_p.get("code") == 0 and isinstance(r_p.get("data"), dict):
            pstatus = r_p["data"].get("status")
        if pstatus == 3:
            test(
                "14.3 PUT /projects/:id/close (matched project)",
                "PUT",
                f"/api/v1/projects/{state.PROJECT_UUID}/close",
                {"reason": "test complete"},
                expect_code=20002,
            )
        else:
            print(
                f"  [SKIP] 14.3 close matched project（当前 status={pstatus}，非已撮合则不测 20002）"
            )
            state.RESULTS.append(("14.3 close matched (skipped)", True, st_p, r_p.get("code", -1)))
