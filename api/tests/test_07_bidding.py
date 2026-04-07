import re
import time
import uuid

from . import state
from .helpers import cf, gen_phone, get_sms_code, mysql_scalar, req, test


def run():
    print("\n--- 7. Phase 4: 投标/撮合 ---")

    # 创建第二个用户来投标（须与主账号手机号不同，避免撞号登录成同一人 -> 30002）
    phone2 = gen_phone()
    for _ in range(30):
        if phone2 != (state.LOGIN_PHONE or ""):
            break
        phone2 = gen_phone()
    test(
        "7.0a sms-code (user2)",
        "POST",
        "/api/v1/auth/sms-code",
        {"phone": phone2, "purpose": 2},
        need_auth=False,
    )
    time.sleep(0.3)
    code2 = get_sms_code(phone2) or "952786"
    old_token = state.TOKEN
    ok, r = test(
        "7.0b login (user2)",
        "POST",
        "/api/v1/auth/login",
        {"phone": phone2, "code": code2},
        need_auth=False,
    )
    state.TOKEN2 = None
    state.USER2_ID = None
    state.USER2_NICKNAME = None
    if ok and r.get("data"):
        state.TOKEN2 = r["data"].get("access_token")
        state.USER2_ID = r["data"].get("user_id")
    if state.TOKEN2:
        _, r_u2 = req("GET", "/api/v1/users/me", auth_token=state.TOKEN2)
        if r_u2.get("code") == 0 and isinstance(r_u2.get("data"), dict):
            state.USER2_NICKNAME = (r_u2["data"].get("nickname") or "").strip() or None
    state.TOKEN = old_token

    if state.PROJECT_UUID and state.TOKEN2:
        saved_token = state.TOKEN
        state.TOKEN = state.TOKEN2
        ok, r = test(
            "7.1 POST /projects/:id/bids (create bid)",
            "POST",
            f"/api/v1/projects/{state.PROJECT_UUID}/bids",
            {"amount": 8000, "duration_days": 14, "proposal": "I can do this project well"},
        )
        state.BID_UUID = None
        if ok and r.get("data"):
            state.BID_UUID = r["data"].get("bid_id")
            print(f"         bid_id={state.BID_UUID}")
        state.TOKEN = saved_token

        # 7.1a1: 投标方查看项目详情，应包含 my_bid_status="pending"
        if state.BID_UUID:
            st_bs, r_bs = req(
                "GET",
                f"/api/v1/projects/{state.PROJECT_UUID}",
                auth_token=state.TOKEN2,
            )
            bid_st = None
            if r_bs.get("code") == 0 and isinstance(r_bs.get("data"), dict):
                bid_st = r_bs["data"].get("my_bid_status")
            bs_ok = bid_st == "pending"
            print(
                f"  [{'PASS' if bs_ok else 'FAIL'}] 7.1a1 GET /projects/:id my_bid_status (bidder) "
                f"-> {bid_st!r} (expect 'pending')"
            )
            state.RESULTS.append(
                ("7.1a1 my_bid_status pending", bs_ok, st_bs, r_bs.get("code", -1))
            )

            # 7.1a2: 需求方（非投标方）查看同一项目，不应有 my_bid_status
            st_no, r_no = req("GET", f"/api/v1/projects/{state.PROJECT_UUID}")
            no_bid = None
            if r_no.get("code") == 0 and isinstance(r_no.get("data"), dict):
                no_bid = r_no["data"].get("my_bid_status")
            no_ok = no_bid is None
            print(
                f"  [{'PASS' if no_ok else 'FAIL'}] 7.1a2 GET /projects/:id my_bid_status (owner, no bid) "
                f"-> {no_bid!r} (expect None/absent)"
            )
            state.RESULTS.append(
                ("7.1a2 my_bid_status absent for owner", no_ok, st_no, r_no.get("code", -1))
            )

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
            if state.PROJECT_DISPLAY_TITLE not in c or "8000" not in c:
                return False
            if "提交了投标" not in c:
                return False
            # U+00A5 半角 ¥ 或 U+FFE5 全角 ￥
            if "\u00a5" not in c and "\uffe5" not in c:
                return False
            if state.USER2_NICKNAME and state.USER2_NICKNAME not in c:
                return False
            return True

        hit_n23 = any(_new_bid_notif_ok(x) for x in rows_n23)
        print(
            f"  [{'PASS' if hit_n23 and r_n23.get('code') == 0 else 'FAIL'}] 7.1b GET /notifications?type=23 (需求方 收到新投标)"
        )
        state.RESULTS.append(
            (
                "7.1b demander new_bid notification (type=23)",
                hit_n23 and r_n23.get("code") == 0,
                st_n23,
                r_n23.get("code", -1),
            )
        )

        # 7.1c: 投标绑定非成员团队 -> 30007
        if state.SEED_TEAM_UUID and state.TOKEN2:
            saved_t = state.TOKEN
            state.TOKEN = state.TOKEN2
            ok_tc, r_tc = test(
                "7.1c POST /bids (non-member team -> 30007)",
                "POST",
                f"/api/v1/projects/{state.PROJECT_UUID}/bids",
                {
                    "amount": 5000,
                    "duration_days": 7,
                    "proposal": "test",
                    "team_id": state.SEED_TEAM_UUID,
                },
                expect_code=30007,
                expect_http=400,
            )
            state.TOKEN = saved_t

        ok, r = test(
            "7.2 GET /projects/:id/bids (list bids)",
            "GET",
            f"/api/v1/projects/{state.PROJECT_UUID}/bids",
        )
        if ok and r.get("data"):
            print(f"         bids count: {len(r['data'])}")

        # 7.2b：专用项目验证投标撤回（不影响后续 7.4 主流程撮合）
        state.PROJECT_WITHDRAW_UUID = None
        state.BID_WITHDRAW_UUID = None
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
            state.PROJECT_WITHDRAW_UUID = r_pw["data"].get("uuid") or r_pw["data"].get("id")
        if state.PROJECT_WITHDRAW_UUID:
            saved_t = state.TOKEN
            state.TOKEN = state.TOKEN2
            ok_bw, r_bw = test(
                "7.2b1 POST /projects/:id/bids (withdraw test)",
                "POST",
                f"/api/v1/projects/{state.PROJECT_WITHDRAW_UUID}/bids",
                {"amount": 2000, "duration_days": 7, "proposal": "withdraw test bid"},
            )
            if ok_bw and r_bw.get("data"):
                state.BID_WITHDRAW_UUID = r_bw["data"].get("bid_id")
            state.TOKEN = saved_t
            bc_before = mysql_scalar(
                f"SELECT bid_count FROM projects WHERE uuid='{state.PROJECT_WITHDRAW_UUID}' LIMIT 1"
            )
            try:
                bc_before_i = int(bc_before) if bc_before is not None else -1
            except ValueError:
                bc_before_i = -1
            if state.BID_WITHDRAW_UUID:
                st_wd, r_wd = req(
                    "PUT",
                    f"/api/v1/bids/{state.BID_WITHDRAW_UUID}/withdraw",
                    auth_token=state.TOKEN2,
                )
                wd_ok = (
                    r_wd.get("code") == 0
                    and isinstance(r_wd.get("data"), dict)
                    and r_wd["data"].get("status") == "withdrawn"
                )
                print(
                    f"  [{'PASS' if wd_ok else 'FAIL'}] 7.2b2 PUT /bids/:id/withdraw (pending) -> HTTP {st_wd}, code={r_wd.get('code')}"
                )
                state.RESULTS.append(("7.2b2 withdraw pending bid", wd_ok, st_wd, r_wd.get("code", -1)))
                bc_after = mysql_scalar(
                    f"SELECT bid_count FROM projects WHERE uuid='{state.PROJECT_WITHDRAW_UUID}' LIMIT 1"
                )
                try:
                    bc_after_i = int(bc_after) if bc_after is not None else -1
                except ValueError:
                    bc_after_i = -1
                bc_match = bc_before_i >= 0 and bc_after_i == bc_before_i - 1
                print(
                    f"  [{'PASS' if bc_match else 'FAIL'}] 7.2b3 MySQL bid_count after withdraw: {bc_before!r} -> {bc_after!r}"
                )
                state.RESULTS.append(("7.2b3 bid_count after withdraw", bc_match, 200, 0))
                st_wd2, r_wd2 = req(
                    "PUT",
                    f"/api/v1/bids/{state.BID_WITHDRAW_UUID}/withdraw",
                    auth_token=state.TOKEN2,
                )
                wd2_ok = r_wd2.get("code") == 30003
                print(
                    f"  [{'PASS' if wd2_ok else 'FAIL'}] 7.2b4 PUT withdraw again (expect 30003) -> HTTP {st_wd2}, code={r_wd2.get('code')}"
                )
                state.RESULTS.append(
                    ("7.2b4 withdraw idempotent closed", wd2_ok, st_wd2, r_wd2.get("code", -1))
                )

                # 7.2b5: 撤回后 my_bid_status 应为 "withdrawn"
                st_bw, r_bw = req(
                    "GET",
                    f"/api/v1/projects/{state.PROJECT_WITHDRAW_UUID}",
                    auth_token=state.TOKEN2,
                )
                bid_st_wd = None
                if r_bw.get("code") == 0 and isinstance(r_bw.get("data"), dict):
                    bid_st_wd = r_bw["data"].get("my_bid_status")
                bw_ok = bid_st_wd == "withdrawn"
                print(
                    f"  [{'PASS' if bw_ok else 'FAIL'}] 7.2b5 GET /projects/:id my_bid_status after withdraw "
                    f"-> {bid_st_wd!r} (expect 'withdrawn')"
                )
                state.RESULTS.append(
                    ("7.2b5 my_bid_status withdrawn", bw_ok, st_bw, r_bw.get("code", -1))
                )
            else:
                print("  [FAIL] 7.2b: missing bid_id for withdraw test")
                state.RESULTS.append(("7.2b withdraw flow", False, 0, -1))

        ok, r = test(
            "7.3 GET /projects/:id/ai-suggestion",
            "GET",
            f"/api/v1/projects/{state.PROJECT_UUID}/ai-suggestion",
        )
        if ok and r.get("data"):
            cf(r["data"], ["suggested_price_min", "suggested_price_max", "reason"])

        if state.BID_UUID:
            ok_acc, r_acc = test(
                "7.4 POST /bids/:id/accept",
                "POST",
                f"/api/v1/bids/{state.BID_UUID}/accept",
            )
            if ok_acc and r_acc.get("data"):
                print(f"         status: {r_acc['data'].get('status')}")

                # 7.4a1: 投标方查看项目详情，应包含 my_bid_status="accepted"
                st_ba, r_ba = req(
                    "GET",
                    f"/api/v1/projects/{state.PROJECT_UUID}",
                    auth_token=state.TOKEN2,
                )
                bid_st_acc = None
                if r_ba.get("code") == 0 and isinstance(r_ba.get("data"), dict):
                    bid_st_acc = r_ba["data"].get("my_bid_status")
                ba_ok = bid_st_acc == "accepted"
                print(
                    f"  [{'PASS' if ba_ok else 'FAIL'}] 7.4a1 GET /projects/:id my_bid_status after accept "
                    f"-> {bid_st_acc!r} (expect 'accepted')"
                )
                state.RESULTS.append(
                    ("7.4a1 my_bid_status accepted", ba_ok, st_ba, r_ba.get("code", -1))
                )

            if ok_acc:
                st_d, r_d = req("GET", "/api/v1/notifications?type=20&page_size=50")
                rows_d = r_d.get("data") if isinstance(r_d.get("data"), list) else []
                hit_d = any(
                    isinstance(x, dict)
                    and x.get("title") == "撮合成功"
                    and "撮合成功" in (x.get("content") or "")
                    for x in rows_d
                )
                print(
                    f"  [{'PASS' if hit_d and r_d.get('code') == 0 else 'FAIL'}] 7.4b GET /notifications?type=20 (demander 撮合成功)"
                )
                state.RESULTS.append(
                    (
                        "7.4b demander match_success notification",
                        hit_d and r_d.get("code") == 0,
                        st_d,
                        r_d.get("code", -1),
                    )
                )
                st_e, r_e = req(
                    "GET",
                    "/api/v1/notifications?type=20&page_size=50",
                    auth_token=state.TOKEN2,
                )
                rows_e = r_e.get("data") if isinstance(r_e.get("data"), list) else []
                hit_e = any(
                    isinstance(x, dict)
                    and x.get("title") == "恭喜被选定"
                    and "服务方" in (x.get("content") or "")
                    for x in rows_e
                )
                print(
                    f"  [{'PASS' if hit_e and r_e.get('code') == 0 else 'FAIL'}] 7.4c GET /notifications?type=20 (expert 恭喜被选定)"
                )
                state.RESULTS.append(
                    (
                        "7.4c expert match_success notification",
                        hit_e and r_e.get("code") == 0,
                        st_e,
                        r_e.get("code", -1),
                    )
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
                state.RESULTS.append(
                    ("7.4d conversations system message", conv_ok, st_c, r_c.get("code", -1))
                )

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
                state.RESULTS.append(
                    ("7.4d1 conversations list meta", meta_conv_ok, st_c, r_c.get("code", -1))
                )

                if match_conv_uuid and isinstance(match_conv_uuid, str):
                    state.MATCH_CONV_UUID = match_conv_uuid

                st_ce, r_ce = req("GET", "/api/v1/conversations", auth_token=state.TOKEN2)
                conv_e_ok = False
                if r_ce.get("code") == 0 and isinstance(r_ce.get("data"), list):
                    for c in r_ce["data"]:
                        if isinstance(c, dict) and "撮合成功" in (c.get("last_message") or ""):
                            conv_e_ok = True
                            break
                print(
                    f"  [{'PASS' if conv_e_ok else 'FAIL'}] 7.4e GET /conversations (expert 可见同一会话)"
                )
                state.RESULTS.append(
                    ("7.4e expert sees match conversation", conv_e_ok, st_ce, r_ce.get("code", -1))
                )

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
                state.RESULTS.append(
                    ("7.4f conversation messages system", msg_ok, st_m, r_m.get("code", -1))
                )

                st_i, r_i = req("POST", f"/api/v1/bids/{state.BID_UUID}/accept")
                idem_ok = r_i.get("code") == 0 and r_i.get("data", {}).get("status") == "accepted"
                print(
                    f"  [{'PASS' if idem_ok else 'FAIL'}] 7.4g POST /bids/:id/accept (idempotent) -> HTTP {st_i}, code={r_i.get('code')}"
                )
                state.RESULTS.append(
                    ("7.4g accept bid idempotent", idem_ok, st_i, r_i.get("code", -1))
                )

                st_ww, r_ww = req(
                    "PUT",
                    f"/api/v1/bids/{state.BID_UUID}/withdraw",
                    auth_token=state.TOKEN2,
                )
                acc_wd_ok = r_ww.get("code") == 30003
                print(
                    f"  [{'PASS' if acc_wd_ok else 'FAIL'}] 7.4w PUT /bids/:id/withdraw after accept (expect 30003) -> HTTP {st_ww}, code={r_ww.get('code')}"
                )
                state.RESULTS.append(
                    ("7.4w withdraw accepted bid forbidden", acc_wd_ok, st_ww, r_ww.get("code", -1))
                )

                ou = mysql_scalar(
                    "SELECT o.uuid FROM orders o JOIN projects p ON p.id=o.project_id "
                    f"WHERE p.uuid='{state.PROJECT_UUID}' ORDER BY o.id DESC LIMIT 1"
                )
                order_detail_ok = False
                st_od, r_od = 0, {}
                if ou:
                    st_od, r_od = req("GET", f"/api/v1/orders/{ou}")
                    if r_od.get("code") == 0 and isinstance(r_od.get("data"), dict):
                        da = r_od["data"]
                        amt_ok = abs(float(da.get("project_amount") or 0) - 8000) < 0.01
                        fee_ok = abs(float(da.get("platform_fee") or 0) - 960.0) < 0.01
                        order_detail_ok = bool(da.get("status") == "pending" and amt_ok and fee_ok)
                print(
                    f"  [{'PASS' if order_detail_ok else 'FAIL'}] 7.4h GET /orders/:id (demander 待支付, 金额/佣金)"
                )
                state.RESULTS.append(
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
                state.RESULTS.append(
                    ("7.4i pay reminder notification", pay_notif_ok, st_pn, r_pn.get("code", -1))
                )

                test(
                    "7.4j POST /orders (duplicate pending -> 40013)",
                    "POST",
                    "/api/v1/orders",
                    {"project_id": state.PROJECT_UUID},
                    expect_code=40013,
                )
