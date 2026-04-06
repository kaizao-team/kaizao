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

    # 项目已撮合 (status=3) 时关闭返回 20002，与 api-spec「进行中不可关闭」一致
    if state.PROJECT_UUID:
        test(
            "14.3 PUT /projects/:id/close (matched project)",
            "PUT",
            f"/api/v1/projects/{state.PROJECT_UUID}/close",
            {"reason": "test complete"},
            expect_code=20002,
        )
