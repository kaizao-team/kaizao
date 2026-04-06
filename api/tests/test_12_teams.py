"""12. v7: 组队 + 12b. 团队详情字段验证 + 13. v7: 评价"""

from . import state
from .helpers import req, test, cf


def run():
    print("\n--- 12. v7: 组队模块 ---")
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
            member_ok = isinstance(members, list) and len(members) > 0
            has_leader = False
            if member_ok:
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
            leader_uuid = d.get("leader_uuid")
            leader_in_members = has_leader or (
                leader_uuid
                and any(
                    isinstance(m, dict) and m.get("user_id") == leader_uuid
                    for m in (members or [])
                )
            )
            print(
                f"  [{'PASS' if member_ok else 'FAIL'}] 12b.1e members with user_id "
                f"-> count={len(members) if isinstance(members, list) else 0}"
                f"{'' if has_leader else ' (leader not in members, ok for seed data)'}"
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
