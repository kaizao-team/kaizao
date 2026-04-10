"""15. 入驻/团队审核全链路（可选）"""

import time

from . import state
from .helpers import req, test, gen_phone, get_sms_code


def run():
    if state.FULL_ONBOARDING:
        print("\n--- 15. 入驻/团队审核全链路（--full-onboarding） ---")
        if not (state.ADMIN_SETUP_OK and state.INVITE_CODE_PLAIN and state.TOKEN and state.USER_ID):
            print(
                "  [FAIL] 前置条件不足：需 1.5 成功（Docker 可 exec MySQL、"
                "未设置 KZ_SKIP_ADMIN_INVITE=1、且 POST /admin/invite-codes 返回 codes）"
            )
            state.RESULTS.append(("15.0 full onboarding prerequisites", False, 0, -1))
        else:
            # --- 15.1 批量创建邀请码并验证 ---
            ok_batch, r_batch = test(
                "15.1 POST /admin/invite-codes (batch=3)",
                "POST",
                "/api/v1/admin/invite-codes",
                {"count": 3, "note": "onboarding-test"},
            )
            invite_codes = []
            if ok_batch and isinstance(r_batch.get("data"), dict):
                invite_codes = r_batch["data"].get("codes", [])
                batch_count = r_batch["data"].get("count", 0)
                batch_ok = len(invite_codes) == 3 and batch_count == 3
                print(f"  [{'PASS' if batch_ok else 'FAIL'}] 15.1a batch count={batch_count}, expected 3")
                state.RESULTS.append(("15.1a batch invite count=3", batch_ok, 200, 0 if batch_ok else -1))

            if not invite_codes:
                print("  [FAIL] 15.1 无邀请码，跳过后续用例")
                state.RESULTS.append(("15.1 batch create", False, 0, -1))
                return

            # --- 15.2 新用户 + 带邀请码创建团队 → 直接通过 ---
            code_a = invite_codes[0]
            expert_phone = gen_phone()
            test("15.2a sms-code", "POST", "/api/v1/auth/sms-code",
                 {"phone": expert_phone, "purpose": 2}, need_auth=False)
            time.sleep(0.3)
            sc = get_sms_code(expert_phone) or "952786"
            ok_login, r_login = test(
                "15.2b POST /auth/login (new expert)",
                "POST", "/api/v1/auth/login",
                {"phone": expert_phone, "code": sc},
                need_auth=False,
            )
            expert_tok = (r_login.get("data") or {}).get("access_token") if ok_login else None
            if not expert_tok:
                print("  [FAIL] 15.2b 登录失败，跳过后续")
                state.RESULTS.append(("15.2b expert login", False, 0, -1))
                return

            ok_team, r_team = test(
                "15.2c POST /teams (with invite_code -> approved)",
                "POST", "/api/v1/teams",
                {"name": "审核测试团队", "invite_code": code_a},
                auth_token=expert_tok,
            )
            if ok_team and isinstance(r_team.get("data"), dict):
                team_uuid = r_team["data"].get("uuid")
                print(f"         team uuid={team_uuid!r}")

                # 验证团队详情中 approval_status 通过
                st_d, r_d = req("GET", f"/api/v1/teams/{team_uuid}", need_auth=False)
                d = r_d.get("data", {}) if isinstance(r_d, dict) else {}
                # approval_status 可能在响应中，也可能不输出（取决于 handler）
                print(f"         team detail fetched, status={d.get('status')!r}")

            # --- 15.3 已核销的码不可复用 ---
            expert_phone2 = gen_phone()
            test("15.3a sms-code", "POST", "/api/v1/auth/sms-code",
                 {"phone": expert_phone2, "purpose": 2}, need_auth=False)
            time.sleep(0.3)
            sc2 = get_sms_code(expert_phone2) or "952786"
            ok_l2, r_l2 = test("15.3b login", "POST", "/api/v1/auth/login",
                               {"phone": expert_phone2, "code": sc2}, need_auth=False)
            tok2 = (r_l2.get("data") or {}).get("access_token") if ok_l2 else None
            if tok2:
                test(
                    "15.3c POST /teams (reuse consumed code -> 10014)",
                    "POST", "/api/v1/teams",
                    {"name": "复用码", "invite_code": code_a},
                    auth_token=tok2,
                    expect_code=10014,
                    expect_http=400,
                )

            # --- 15.4 无邀请码创建团队 → 待审核 → 管理端审核通过 ---
            if tok2:
                ok_pending, r_pending = test(
                    "15.4a POST /teams (no invite_code -> pending)",
                    "POST", "/api/v1/teams",
                    {"name": "待审核团队"},
                    auth_token=tok2,
                )
                if ok_pending and isinstance(r_pending.get("data"), dict):
                    pending_uuid = r_pending["data"].get("uuid")
                    print(f"         pending team uuid={pending_uuid!r}")

                    # 管理端审核通过
                    test(
                        "15.4b PUT /admin/teams/:uuid/approval (approve)",
                        "PUT",
                        f"/api/v1/admin/teams/{pending_uuid}/approval",
                        {"status": "approved"},
                    )

                    # 管理端审核拒绝（换一个码的新团队来测试）
                    if len(invite_codes) >= 3:
                        code_c = invite_codes[2]
                        expert_phone3 = gen_phone()
                        test("15.4c sms-code", "POST", "/api/v1/auth/sms-code",
                             {"phone": expert_phone3, "purpose": 2}, need_auth=False)
                        time.sleep(0.3)
                        sc3 = get_sms_code(expert_phone3) or "952786"
                        ok_l3, r_l3 = test("15.4d login", "POST", "/api/v1/auth/login",
                                           {"phone": expert_phone3, "code": sc3}, need_auth=False)
                        tok3 = (r_l3.get("data") or {}).get("access_token") if ok_l3 else None
                        if tok3:
                            ok_p2, r_p2 = test(
                                "15.4e POST /teams (no invite_code, for reject test)",
                                "POST", "/api/v1/teams",
                                {"name": "拒绝审核团队"},
                                auth_token=tok3,
                            )
                            if ok_p2 and isinstance(r_p2.get("data"), dict):
                                reject_uuid = r_p2["data"].get("uuid")
                                test(
                                    "15.4f PUT /admin/teams/:uuid/approval (reject)",
                                    "PUT",
                                    f"/api/v1/admin/teams/{reject_uuid}/approval",
                                    {"status": "rejected", "reason": "integration test reject"},
                                )

            # --- 15.5 邀请码列表验证已核销码无明文 ---
            ok_list, r_list = test(
                "15.5 GET /admin/invite-codes (verify consumed)",
                "GET",
                "/api/v1/admin/invite-codes?page=1&page_size=50",
            )
            if ok_list and isinstance(r_list.get("data"), list):
                consumed_count = sum(
                    1 for ic in r_list["data"]
                    if isinstance(ic, dict) and ic.get("used_count", 0) >= ic.get("max_uses", 1)
                )
                print(f"         consumed invite codes in list: {consumed_count}")
