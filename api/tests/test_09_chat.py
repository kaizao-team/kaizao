"""9. Phase 5: 聊天"""

from . import state
from .helpers import req, test, cf


def run():
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
        state.RESULTS.append(("9.1b conversations meta", meta_91_ok, 200, 0 if meta_91_ok else -1))

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
    if state.MATCH_CONV_UUID and state.TOKEN2 and state.TOKEN:
        st_s9, r_s9 = req(
            "POST",
            f"/api/v1/conversations/{state.MATCH_CONV_UUID}/messages",
            {"content": "v2-integration expert ping", "type": "text"},
            auth_token=state.TOKEN2,
        )
        send9_ok = st_s9 == 200 and r_s9.get("code") == 0
        print(
            f"  [{'PASS' if send9_ok else 'FAIL'}] 9.2 POST /conversations/:uuid/messages (expert) "
            f"-> HTTP {st_s9}, code={r_s9.get('code')}"
        )
        state.RESULTS.append(("9.2 expert send message", send9_ok, st_s9, r_s9.get("code", -1)))

        st_u0, r_u0 = req("GET", "/api/v1/conversations")
        u0 = _conv_unread_by_id(
            r_u0.get("data") if isinstance(r_u0.get("data"), list) else [], state.MATCH_CONV_UUID
        )
        unread_before_ok = r_u0.get("code") == 0 and u0 is not None and u0 >= 1
        print(
            f"  [{'PASS' if unread_before_ok else 'FAIL'}] 9.3a GET /conversations demander unread_count>=1 "
            f"(got {u0!r})"
        )
        state.RESULTS.append(("9.3a demander unread after expert msg", unread_before_ok, st_u0, r_u0.get("code", -1)))

        st_mr9, r_mr9 = req("POST", f"/api/v1/conversations/{state.MATCH_CONV_UUID}/read")
        mr9_ok = st_mr9 == 200 and r_mr9.get("code") == 0
        print(
            f"  [{'PASS' if mr9_ok else 'FAIL'}] 9.3b POST /conversations/:uuid/read (demander) "
            f"-> HTTP {st_mr9}, code={r_mr9.get('code')}"
        )
        state.RESULTS.append(("9.3b demander mark read", mr9_ok, st_mr9, r_mr9.get("code", -1)))

        st_u1, r_u1 = req("GET", "/api/v1/conversations")
        u1 = _conv_unread_by_id(
            r_u1.get("data") if isinstance(r_u1.get("data"), list) else [], state.MATCH_CONV_UUID
        )
        unread_after_ok = r_u1.get("code") == 0 and u1 is not None and u1 == 0
        print(
            f"  [{'PASS' if unread_after_ok else 'FAIL'}] 9.3c GET /conversations demander unread_count==0 "
            f"(got {u1!r})"
        )
        state.RESULTS.append(("9.3c demander unread after read", unread_after_ok, st_u1, r_u1.get("code", -1)))
    else:
        print("  [SKIP] 9.2–9.3 无 MATCH_CONV_UUID 或 TOKEN2/TOKEN，跳过未读/已读")

    # 9.4 圈外人 403 / 60002（依赖 §8 TOKEN_OUTSIDER）
    if state.TOKEN_OUTSIDER and state.MATCH_CONV_UUID:
        test(
            "9.4a GET /conversations/:uuid/messages outsider -> 403/60002",
            "GET",
            f"/api/v1/conversations/{state.MATCH_CONV_UUID}/messages",
            need_auth=True,
            auth_token=state.TOKEN_OUTSIDER,
            expect_code=60002,
            expect_http=403,
        )
        test(
            "9.4b POST /conversations/:uuid/messages outsider -> 403/60002",
            "POST",
            f"/api/v1/conversations/{state.MATCH_CONV_UUID}/messages",
            {"content": "should fail", "type": "text"},
            need_auth=True,
            auth_token=state.TOKEN_OUTSIDER,
            expect_code=60002,
            expect_http=403,
        )
    else:
        print("  [SKIP] 9.4 无 TOKEN_OUTSIDER 或 MATCH_CONV_UUID，跳过圈外人会话越权")

    # 9.5 伪造会话 UUID -> 404
    fake_conv = "00000000-0000-4000-8000-000000000099"
    test(
        "9.5 GET /conversations/:uuid/messages (unknown uuid -> 404/60001)",
        "GET",
        f"/api/v1/conversations/{fake_conv}/messages",
        expect_code=60001,
        expect_http=404,
    )

    # 9.6 软删后会话消息不可访问（须最后执行，避免影响 9.4）
    if state.MATCH_CONV_UUID and state.TOKEN:
        st_del9, r_del9 = req("DELETE", f"/api/v1/conversations/{state.MATCH_CONV_UUID}")
        del9_ok = st_del9 == 200 and r_del9.get("code") == 0
        print(
            f"  [{'PASS' if del9_ok else 'FAIL'}] 9.6a DELETE /conversations/:uuid (demander soft-delete) "
            f"-> HTTP {st_del9}, code={r_del9.get('code')}"
        )
        state.RESULTS.append(("9.6a conversation delete", del9_ok, st_del9, r_del9.get("code", -1)))

        st_gone_d, r_gone_d = req("GET", f"/api/v1/conversations/{state.MATCH_CONV_UUID}/messages")
        gone_d_ok = st_gone_d == 404 and r_gone_d.get("code") == 60001
        print(
            f"  [{'PASS' if gone_d_ok else 'FAIL'}] 9.6b GET messages after delete (demander -> 404/60001) "
            f"HTTP {st_gone_d}"
        )
        state.RESULTS.append(("9.6b messages after delete demander", gone_d_ok, st_gone_d, r_gone_d.get("code", -1)))

        if state.TOKEN2:
            st_gone_e, r_gone_e = req(
                "GET",
                f"/api/v1/conversations/{state.MATCH_CONV_UUID}/messages",
                auth_token=state.TOKEN2,
            )
            gone_e_ok = st_gone_e == 404 and r_gone_e.get("code") == 60001
            print(
                f"  [{'PASS' if gone_e_ok else 'FAIL'}] 9.6c GET messages after delete (expert -> 404/60001) "
                f"HTTP {st_gone_e}"
            )
            state.RESULTS.append(("9.6c messages after delete expert", gone_e_ok, st_gone_e, r_gone_e.get("code", -1)))
        else:
            print("  [SKIP] 9.6c 无 TOKEN2，跳过专家侧删除后拉消息")
    else:
        print("  [SKIP] 9.6 无 MATCH_CONV_UUID 或 TOKEN，跳过软删校验")
