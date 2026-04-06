"""§6 Phase 3：需求发布 / PRD。"""

from . import state
from .helpers import cf, test


def run():
    print("\n--- 6. Phase 3: 需求发布/PRD ---")
    ok, r = test(
        "6.1 POST /projects/ai-chat",
        "POST",
        "/api/v1/projects/ai-chat",
        {"message": "我想做一个社交电商App", "category": "dev"},
    )
    if ok and r.get("data"):
        cf(r["data"], ["reply", "can_generate_prd", "turn"])

    ok, r = test(
        "6.2 POST /projects/generate-prd",
        "POST",
        "/api/v1/projects/generate-prd",
        {"category": "dev", "chat_history": [{"role": "user", "content": "社交电商"}]},
    )
    if ok and r.get("data"):
        cf(r["data"], ["prd_id", "title", "modules", "budget_suggestion"])

    ok, r = test(
        "6.3 POST /projects/draft",
        "POST",
        "/api/v1/projects/draft",
        {"category": "dev", "budget_min": 3000, "budget_max": 8000},
    )
    if ok and r.get("data"):
        cf(r["data"], ["draft_id", "saved_at"])

    # 6.3n SaveDraft 负例（binding：min=0 / match_mode oneof；业务：max>=min）
    test(
        "6.3n1 POST /projects/draft (negative budget_min -> 99001)",
        "POST",
        "/api/v1/projects/draft",
        {"category": "dev", "budget_min": -1, "budget_max": 1000},
        expect_code=99001,
        expect_http=400,
    )
    test(
        "6.3n2 POST /projects/draft (negative budget_max -> 99001)",
        "POST",
        "/api/v1/projects/draft",
        {"category": "dev", "budget_min": 0, "budget_max": -0.01},
        expect_code=99001,
        expect_http=400,
    )
    test(
        "6.3n3 POST /projects/draft (invalid match_mode -> 99001)",
        "POST",
        "/api/v1/projects/draft",
        {"category": "dev", "budget_min": 100, "budget_max": 200, "match_mode": 9},
        expect_code=99001,
        expect_http=400,
    )
    test(
        "6.3n4 POST /projects/draft (budget_max < budget_min -> 99001)",
        "POST",
        "/api/v1/projects/draft",
        {"category": "dev", "budget_min": 5000, "budget_max": 1000},
        expect_code=99001,
        expect_http=400,
    )

    # 6.3b–6.3e：发布草稿 + 标题/描述/category 归一（与 PublishDraft / SaveDraft 一致）
    state.DRAFT_PUBLISH_UUID = None
    ok, r = test(
        "6.3b POST /projects/draft (design legacy + short title/desc)",
        "POST",
        "/api/v1/projects/draft",
        {
            "category": "design",
            "title": "短",
            "description": "短",
            "budget_min": 100,
            "budget_max": 900,
        },
    )
    if ok and r.get("data"):
        state.DRAFT_PUBLISH_UUID = r["data"].get("draft_id") or r["data"].get("uuid")
        cf(r["data"], ["draft_id", "saved_at"])

    if state.DRAFT_PUBLISH_UUID:
        ok, r = test(
            "6.3c GET /projects/:id (draft before publish)",
            "GET",
            f"/api/v1/projects/{state.DRAFT_PUBLISH_UUID}",
        )
        _draft_assert = False
        if ok and isinstance(r.get("data"), dict):
            _d = r["data"]
            _draft_assert = (
                _d.get("category") == "visual"
                and int(_d.get("status", 0)) == 1
                and str(_d.get("title") or "") == "短"
            )
        print(
            f"  [{'PASS' if _draft_assert else 'FAIL'}] 6.3c assert: draft category=visual, status=1, title=短"
        )
        state.RESULTS.append(("6.3c assert draft normalized", _draft_assert, 200, 0))

        ok, r = test(
            "6.3d POST /projects/:id/publish",
            "POST",
            f"/api/v1/projects/{state.DRAFT_PUBLISH_UUID}/publish",
            body={},
        )
        if ok and r.get("data"):
            cf(r["data"], ["uuid", "status"])
            if int(r["data"].get("status", 0)) != 2:
                print("         WARN: publish data.status expected 2")

        ok, r = test(
            "6.3e GET /projects/:id (after publish)",
            "GET",
            f"/api/v1/projects/{state.DRAFT_PUBLISH_UUID}",
        )
        _pub_assert = False
        if ok and isinstance(r.get("data"), dict):
            _pd = r["data"]
            _t = str(_pd.get("title") or "")
            _desc = str(_pd.get("description") or "")
            _pub_assert = (
                _pd.get("category") == "visual"
                and int(_pd.get("status", 0)) == 2
                and len(_t) >= 5
                and len(_desc) >= 20
            )
        print(
            f"  [{'PASS' if _pub_assert else 'FAIL'}] 6.3e assert: published status=2, category=visual, len(title)>=5, len(desc)>=20"
        )
        state.RESULTS.append(("6.3e assert publish title/desc/category", _pub_assert, 200, 0))

    if state.PROJECT_UUID:
        ok, r = test("6.4 GET /projects/:id/prd", "GET", f"/api/v1/projects/{state.PROJECT_UUID}/prd")
        if ok and r.get("data"):
            cf(r["data"], ["prd_id", "project_id", "title"])

        test(
            "6.5 PUT /projects/:id/prd/cards/:cardId",
            "PUT",
            f"/api/v1/projects/{state.PROJECT_UUID}/prd/cards/card_001",
            {"criteria_id": "ac_001"},
        )
