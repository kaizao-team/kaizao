"""§4 首页聚合：需求方/专家首页。"""

from . import state
from .helpers import cf, test


def run():
    print("\n--- 4. 首页聚合 ---")
    ok, r = test("4.1 GET /home/demander", "GET", "/api/v1/home/demander")
    if ok and r.get("data"):
        cf(r["data"], ["ai_prompt", "categories", "my_projects", "recommended_experts"])
        for i, ex in enumerate(r["data"].get("recommended_experts") or []):
            sk_ok = isinstance(ex, dict) and isinstance(ex.get("skill"), str)
            print(
                f"  [{'PASS' if sk_ok else 'FAIL'}] 4.1b demander recommended_experts[{i}] skill field -> {ex.get('skill')!r}"
            )
            state.RESULTS.append((f"4.1b expert[{i}] skill (str)", sk_ok, 200, 0 if sk_ok else -1))

        # 4.1c 团队实体对齐：推荐专家应含团队维度字段
        rec_list = r["data"].get("recommended_experts") or []
        if rec_list:
            team_fields_ok = all(
                isinstance(ex, dict)
                and "vibe_level" in ex
                and "vibe_power" in ex
                and "member_count" in ex
                and "budget_min" in ex
                and "budget_max" in ex
                for ex in rec_list
            )
            print(
                f"  [{'PASS' if team_fields_ok else 'FAIL'}] 4.1c recommended_experts team fields "
                f"(vibe_level/vibe_power/member_count) present in {len(rec_list)} items"
            )
            state.RESULTS.append(
                ("4.1c recommended_experts team fields", team_fields_ok, 200, 0 if team_fields_ok else -1)
            )

    ok, r = test("4.2 GET /home/expert", "GET", "/api/v1/home/expert")
    if ok and r.get("data"):
        cf(r["data"], ["revenue", "recommended_demands", "skill_heat"])
