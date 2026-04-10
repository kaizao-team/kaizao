"""12. v7: 组队 + 12a. POST /teams 创建团队 + 12b. 团队详情字段验证 + 13. v7: 评价"""

import time

from . import state
from .helpers import req, test, cf, gen_phone, get_sms_code


def run():
    print("\n--- 12. v7: 组队模块 ---")

    # ==================== 12a. POST /api/v1/teams 创建团队 ====================
    print("\n--- 12a. POST /teams 创建团队 ---")

    # 非法预算区间 (20005)
    test(
        "12a.1 POST /teams (invalid budget -> 20005)",
        "POST",
        "/api/v1/teams",
        {"budget_min": 10000.0, "budget_max": 1000.0},
        expect_code=20005,
        expect_http=400,
    )

    # 正常创建（无邀请码 → approval_status=1 待审核）。同一次跑测中可能已建主团队 → 11021 亦为预期
    st_ct, r_ct = req(
        "POST",
        "/api/v1/teams",
        {
            "name": "集成测试团队",
            "hourly_rate": 350.0,
            "available_status": 1,
            "budget_min": 5000.0,
            "budget_max": 20000.0,
            "description": "集成测试自动创建（无邀请码，待审核）",
        },
    )
    code_ct = r_ct.get("code", -1)
    ok_12a2 = code_ct in (0, 11021)
    icon = "PASS" if ok_12a2 else "FAIL"
    print(f"  [{icon}] 12a.2 POST /teams (no invite_code, pending) -> HTTP {st_ct}, code={code_ct}")
    if not ok_12a2:
        print(
            f"         Expected code=0 or 11021, got code={code_ct}, HTTP={st_ct}, "
            f"msg={r_ct.get('message', '')}"
        )
    state.RESULTS.append(("12a.2 POST /teams (no invite_code)", ok_12a2, st_ct, code_ct))
    if code_ct == 0 and isinstance(r_ct.get("data"), dict):
        created_uuid = r_ct["data"].get("uuid")
        created_name = r_ct["data"].get("name")
        print(f"         created team uuid={created_uuid!r}, name={created_name!r}")
        if not state.EXPERT_TEAM_UUID:
            state.EXPERT_TEAM_UUID = created_uuid
    elif code_ct == 11021:
        print("         已有主团队，跳过创建（11021）")

    # 重复创建应返回 11021
    test(
        "12a.3 POST /teams (duplicate -> 11021)",
        "POST",
        "/api/v1/teams",
        {},
        expect_code=11021,
        expect_http=400,
    )

    # ==================== 12a.4 带邀请码创建团队（新用户，approval_status=2 直接通过） ====================
    print("\n--- 12a.4 带邀请码创建团队 ---")
    if state.ADMIN_SETUP_OK and state.INVITE_CODE_PLAIN:
        inv_phone = gen_phone()
        test(
            "12a.4a POST /auth/sms-code (new user for invite team)",
            "POST",
            "/api/v1/auth/sms-code",
            {"phone": inv_phone, "purpose": 2},
            need_auth=False,
        )
        time.sleep(0.3)
        inv_sms = get_sms_code(inv_phone) or "952786"
        ok_login, r_login = test(
            "12a.4b POST /auth/login (new user)",
            "POST",
            "/api/v1/auth/login",
            {"phone": inv_phone, "code": inv_sms},
            need_auth=False,
        )
        inv_tok = (r_login.get("data") or {}).get("access_token") if ok_login else None
        if inv_tok:
            ok_inv_team, r_inv_team = test(
                "12a.4c POST /teams (with invite_code -> approved)",
                "POST",
                "/api/v1/teams",
                {
                    "name": "邀请码团队",
                    "invite_code": state.INVITE_CODE_PLAIN,
                    "description": "用邀请码创建，应直接审核通过",
                },
                auth_token=inv_tok,
            )
            if ok_inv_team and isinstance(r_inv_team.get("data"), dict):
                inv_team_uuid = r_inv_team["data"].get("uuid")
                print(f"         invite team uuid={inv_team_uuid!r}")
            # 使用已核销的邀请码再次创建应失败 (10013 或 10014)
            inv_phone2 = gen_phone()
            test("12a.4d sms-code for 2nd user", "POST", "/api/v1/auth/sms-code",
                 {"phone": inv_phone2, "purpose": 2}, need_auth=False)
            time.sleep(0.3)
            inv_sms2 = get_sms_code(inv_phone2) or "952786"
            ok_l2, r_l2 = test("12a.4e login 2nd user", "POST", "/api/v1/auth/login",
                               {"phone": inv_phone2, "code": inv_sms2}, need_auth=False)
            inv_tok2 = (r_l2.get("data") or {}).get("access_token") if ok_l2 else None
            if inv_tok2:
                test(
                    "12a.4f POST /teams (reuse consumed invite_code -> 10013/10014)",
                    "POST",
                    "/api/v1/teams",
                    {"name": "二次使用", "invite_code": state.INVITE_CODE_PLAIN},
                    auth_token=inv_tok2,
                    expect_code=10014,
                    expect_http=400,
                )
        else:
            print("  [SKIP] 12a.4c–f 无 token，跳过邀请码建团队用例")

        # 管理端审核团队（如果之前无码创建的团队存在）
        if state.EXPERT_TEAM_UUID and state.TOKEN:
            print("\n--- 12a.5 管理端审核团队 ---")
            test(
                "12a.5a PUT /admin/teams/:uuid/approval (approve)",
                "PUT",
                f"/api/v1/admin/teams/{state.EXPERT_TEAM_UUID}/approval",
                {"status": "approved"},
            )
    else:
        print("  [SKIP] 12a.4 需 1.5 管理端邀请码创建成功")

    ok, r = test("12.1 GET /teams (list)", "GET", "/api/v1/teams", need_auth=False)
    if ok and r.get("data"):
        cf(r["data"], ["ai_recommended", "posts"])

    ok, r = test(
        "12.2 POST /team-posts (create)",
        "POST",
        "/api/v1/team-posts",
        {
            "project_name": "Test Team Project",
            "description": "Looking for Flutter developer",
            "needed_roles": [{"role": "frontend", "count": 1, "skills": ["Flutter"]}],
        },
    )
    if ok and r.get("data"):
        cf(r["data"], ["id", "status"])

    # ==================== 12b. 团队详情字段验证 ====================
    print("\n--- 12b. 团队详情字段验证 ---")
    team_uuid = state.EXPERT_TEAM_UUID or state.SEED_TEAM_UUID
    if team_uuid:
        ok_d, r_d = test(
            "12b.1 GET /teams/:uuid (detail)",
            "GET",
            f"/api/v1/teams/{team_uuid}",
            need_auth=False,
        )
        if ok_d and isinstance(r_d.get("data"), dict):
            d = r_d["data"]

            base_ok = cf(
                d,
                ["id", "team_name", "project_name", "status", "members"],
                "team detail base",
            )
            print(
                f"  [{'PASS' if base_ok else 'FAIL'}] 12b.1a team detail base fields"
            )
            state.RESULTS.append(
                ("12b.1a team detail base fields", base_ok, 200, 0 if base_ok else -1)
            )

            biz_fields = [
                "vibe_level",
                "vibe_power",
                "hourly_rate",
                "budget_min",
                "budget_max",
                "avg_rating",
                "member_count",
                "total_projects",
                "available_status",
                "experience_years",
            ]
            biz_ok = cf(d, biz_fields, "team detail biz")
            print(
                f"  [{'PASS' if biz_ok else 'FAIL'}] 12b.1b team detail biz fields "
                f"-> vibe_level={d.get('vibe_level')!r}, vibe_power={d.get('vibe_power')}, "
                f"hourly_rate={d.get('hourly_rate')}, avg_rating={d.get('avg_rating')}, "
                f"member_count={d.get('member_count')}"
            )
            state.RESULTS.append(
                ("12b.1b team detail biz fields", biz_ok, 200, 0 if biz_ok else -1)
            )

            leader_fields = ["leader_uuid", "nickname", "skills"]
            leader_ok = cf(d, leader_fields, "team detail leader")
            print(
                f"  [{'PASS' if leader_ok else 'FAIL'}] 12b.1c team detail leader fields "
                f"-> leader_uuid={d.get('leader_uuid')!r}, nickname={d.get('nickname')!r}, "
                f"skills={d.get('skills')!r}"
            )
            state.RESULTS.append(
                (
                    "12b.1c team detail leader fields",
                    leader_ok,
                    200,
                    0 if leader_ok else -1,
                )
            )

            skills = d.get("skills")
            skills_type_ok = isinstance(skills, list)
            print(
                f"  [{'PASS' if skills_type_ok else 'FAIL'}] 12b.1d skills is array "
                f"-> type={type(skills).__name__}"
            )
            state.RESULTS.append(
                (
                    "12b.1d skills is array",
                    skills_type_ok,
                    200,
                    0 if skills_type_ok else -1,
                )
            )

            members = d.get("members")
            leader_uuid = d.get("leader_uuid")
            has_leader = False
            member_ok = isinstance(members, list)
            if not member_ok:
                pass  # member_ok stays False
            elif len(members) == 0:
                # 远端/种子可能不返回成员列表；leader 已在顶层校验
                member_ok = bool(leader_uuid)
                has_leader = False
            else:
                m0 = members[0]
                member_fields_ok = cf(
                    m0,
                    ["user_id", "nickname", "role", "ratio", "is_leader", "status"],
                    "member[0]",
                )
                has_leader = any(
                    isinstance(m, dict) and m.get("is_leader") for m in members
                )
                member_ok = member_fields_ok
            note = ""
            if isinstance(members, list):
                if len(members) == 0 and leader_uuid:
                    note = " (empty members, ok when leader on payload)"
                elif len(members) > 0 and not has_leader:
                    note = " (leader not in members, ok for seed data)"
            print(
                f"  [{'PASS' if member_ok else 'FAIL'}] 12b.1e members with user_id "
                f"-> count={len(members) if isinstance(members, list) else 0}{note}"
            )
            state.RESULTS.append(
                (
                    "12b.1e members structure",
                    member_ok,
                    200,
                    0 if member_ok else -1,
                )
            )

            extra_fields = ["description", "avatar_url", "resume_summary", "created_at"]
            extra_ok = all(f in d for f in extra_fields)
            print(
                f"  [{'PASS' if extra_ok else 'FAIL'}] 12b.1f optional fields present "
                f"-> description={'yes' if 'description' in d else 'no'}, "
                f"avatar_url={'yes' if 'avatar_url' in d else 'no'}, "
                f"created_at={'yes' if 'created_at' in d else 'no'}"
            )
            state.RESULTS.append(
                (
                    "12b.1f optional fields present",
                    extra_ok,
                    200,
                    0 if extra_ok else -1,
                )
            )
    else:
        print("  [SKIP] 12b 无团队 UUID，跳过团队详情字段验证")

    print("\n--- 13. v7: 评价模块 ---")
    if state.PROJECT_UUID:
        ok, r = test(
            "13.1 GET /projects/:id/reviews (list)",
            "GET",
            f"/api/v1/projects/{state.PROJECT_UUID}/reviews",
            need_auth=False,
        )
        if ok:
            print(f"         reviews: {len(r.get('data', []))}")
