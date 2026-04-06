"""15. 入驻审核全链路（可选）"""

import time

from . import state
from .helpers import req, test, gen_phone, get_sms_code


def run():
    if state.FULL_ONBOARDING:
        print("\n--- 15. 入驻审核全链路（--full-onboarding） ---")
        if not (state.ADMIN_SETUP_OK and state.INVITE_CODE_PLAIN and state.TOKEN and state.USER_ID):
            print(
                "  [FAIL] 前置条件不足：需 1.5 成功（Docker 可 exec MySQL、"
                "未设置 KZ_SKIP_ADMIN_INVITE=1、且 POST /admin/invite-codes 返回 code_plain）"
            )
            state.RESULTS.append(("15.0 full onboarding prerequisites", False, 0, -1))
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
                    {"invite_code": state.INVITE_CODE_PLAIN},
                    auth_token=tok_new,
                )
                st_me2, r_me2 = req("GET", "/api/v1/users/me", None, True, tok_new)
                ob2 = r_me2.get("data", {}).get("onboarding_status") if isinstance(r_me2, dict) else None
                ok_ob = ob2 == 2
                print(
                    f"  [{'PASS' if ok_ob else 'FAIL'}] 15.3 GET /users/me (onboarding approved) status={st_me2} onboarding={ob2}"
                )
                state.RESULTS.append(
                    ("15.3 expert onboarding approved after redeem", ok_ob, st_me2, r_me2.get("code", -1))
                )
                if ok_rd:
                    st_cur, r_cur = req(
                        "GET",
                        f"/api/v1/admin/teams/{state.SEED_TEAM_UUID}/current-invite-code",
                        None,
                        True,
                        state.TOKEN,
                    )
                    new_plain = (r_cur.get("data") or {}).get("code_plain")
                    rotated = bool(new_plain) and new_plain != state.INVITE_CODE_PLAIN
                    print(f"  [{'PASS' if rotated else 'FAIL'}] 15.4 admin current-invite 已轮换新码 rotated={rotated}")
                    state.RESULTS.append(("15.4 team invite rotated after use", rotated, st_cur, r_cur.get("code", -1)))
            elif not ok_reg:
                pass
            else:
                print(f"  [FAIL] 15.x 专家注册未返回 token/uuid: token={bool(tok_new)} uuid={expert_uuid!r}")
                state.RESULTS.append(("15.x expert register", False, 0, r_reg.get("code", -1)))
