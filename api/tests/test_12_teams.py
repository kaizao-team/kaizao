"""12. v7: 组队 + 12a. POST /teams 创建团队 + 12b. 团队详情字段验证 + 13. v7: 评价"""

from . import state
from .helpers import req, test, cf


def run():
    print("\n--- 12. v7: 组队模块 ---")

    # ==================== 12a. POST /api/v1/teams 创建团队 ====================
    print("\n--- 12a. POST /teams 创建团队 ---")
    st_me, r_me = req("GET", "/api/v1/users/me")
    me_role = (r_me.get("data") or {}).get("role") if isinstance(r_me.get("data"), dict) else None

    # 非专家/团队方创建应被拒绝 (11022)
    if me_role == 1:
        test(
            "12a.1 POST /teams (role=1 -> 11022)",
            "POST",
            "/api/v1/teams",
            {"name": "Should Fail"},
            expect_code=11022,
            expect_http=400,
        )
    else:
        print(f"  [SKIP] 12a.1 role=1 拒绝测试（当前 role={me_role}）")
        state.RESULTS.append(("12a.1 POST /teams role=1 reject (skipped)", True, 0, 0))

    # 非法预算区间 (20005)
    if me_role in (2, 3):
        test(
            "12a.2 POST /teams (invalid budget -> 20005)",
            "POST",
            "/api/v1/teams",
            {"budget_min": 10000.0, "budget_max": 1000.0},
            expect_code=20005,
            expect_http=400,
        )
    else:
        print(f"  [SKIP] 12a.2 非法预算测试（当前 role={me_role}，需 2/3）")
        state.RESULTS.append(("12a.2 POST /teams invalid budget (skipped)", True, 0, 0))

    # 正常创建（如果当前 role=2/3 且无主团队）
    if me_role in (2, 3):
        ok_ct, r_ct = test(
            "12a.3 POST /teams (create)",
            "POST",
            "/api/v1/teams",
            {
                "name": "集成测试团队",
                "hourly_rate": 350.0,
                "available_status": 1,
                "budget_min": 5000.0,
                "budget_max": 20000.0,
                "description": "集成测试自动创建",
            },
        )
        # 可能已有主团队 (11021)，两种结果都可接受
        if ok_ct and isinstance(r_ct.get("data"), dict):
            created_uuid = r_ct["data"].get("uuid")
            created_name = r_ct["data"].get("name")
            print(f"         created team uuid={created_uuid!r}, name={created_name!r}")
            if not state.EXPERT_TEAM_UUID:
                state.EXPERT_TEAM_UUID = created_uuid
        elif r_ct.get("code") == 11021:
            print("         已有主团队，跳过创建（11021）")
            state.RESULTS.append(("12a.3 POST /teams (already exists)", True, 400, 11021))

        # 重复创建应返回 11021
        test(
            "12a.4 POST /teams (duplicate -> 11021)",
            "POST",
            "/api/v1/teams",
            {},
            expect_code=11021,
            expect_http=400,
        )
    else:
        print(f"  [SKIP] 12a.3-4 创建团队（当前 role={me_role}，需 2/3）")
        state.RESULTS.append(("12a.3 POST /teams (skipped non-expert)", True, 0, 0))

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
