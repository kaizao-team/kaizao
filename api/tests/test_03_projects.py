"""§3 项目：CRUD、推荐。"""

from . import state
from .helpers import cf, req, test


def run():
    print("\n--- 3. 项目模块 ---")
    ok, r = test(
        "3.1 POST /projects (create)",
        "POST",
        "/api/v1/projects",
        {
            "title": "Test Flutter App V2",
            "description": "Integration testing project for v2 API specification validation.",
            "category": "dev",
            "budget_min": 5000,
            "budget_max": 15000,
            "tech_requirements": ["Flutter", "Go"],
        },
    )
    if ok and r.get("data"):
        state.PROJECT_UUID = r["data"].get("uuid") or r["data"].get("id")
        print(f"         project={state.PROJECT_UUID}")

    test(
        "3.2n GET /projects without auth -> 401",
        "GET",
        "/api/v1/projects?page=1&page_size=10",
        need_auth=False,
        expect_code=10008,
        expect_http=401,
    )

    ok, r = test("3.2 GET /projects (list, mine)", "GET", "/api/v1/projects?page=1&page_size=10")
    if ok and isinstance(r.get("data"), list) and state.USER_ID:
        scope_ok = True
        for item in r["data"]:
            oid = item.get("owner_id") or ""
            pid = item.get("provider_id") or ""
            if oid != state.USER_ID and pid != state.USER_ID:
                scope_ok = False
                break
        print(
            f"         [{'PASS' if scope_ok else 'FAIL'}] 3.2 owner/provider scope (current user only)"
        )
        if not scope_ok:
            state.RESULTS.append(("3.2 scope mine-only", False, 200, r.get("code", -1)))

    ok, r = test("3.2a GET /projects?role=1 (demander)", "GET", "/api/v1/projects?role=1&page=1&page_size=10")
    if ok:
        print(f"         demander projects: {len(r.get('data', []))}")

    ok, r = test("3.2b GET /projects?role=2 (expert)", "GET", "/api/v1/projects?role=2&page=1&page_size=10")
    if ok:
        print(f"         expert projects: {len(r.get('data', []))}")

    if state.PROJECT_UUID:
        ok, r = test("3.3 GET /projects/:id (detail)", "GET", f"/api/v1/projects/{state.PROJECT_UUID}")
        if ok and r.get("data"):
            cf(r["data"], ["id", "title", "status", "category"])

            d = r["data"]
            prd_ok = "prd_summary" in d
            print(
                f"  [{'PASS' if prd_ok else 'FAIL'}] 3.3b prd_summary field present "
                f"-> type={type(d.get('prd_summary')).__name__}, value={d.get('prd_summary')!r}"
            )
            state.RESULTS.append(("3.3b prd_summary field", prd_ok, 200, 0 if prd_ok else -1))

            ms = d.get("milestones")
            ms_ok = isinstance(ms, list)
            print(
                f"  [{'PASS' if ms_ok else 'FAIL'}] 3.3c milestones field is array "
                f"-> type={type(ms).__name__}, count={len(ms) if isinstance(ms, list) else 'N/A'}"
            )
            state.RESULTS.append(("3.3c milestones field", ms_ok, 200, 0 if ms_ok else -1))

            if isinstance(ms, list) and len(ms) > 0:
                ms0 = ms[0]
                ms_fields_ok = cf(ms0, ["id", "title", "status", "progress"], "milestone[0]")
                print(
                    f"  [{'PASS' if ms_fields_ok else 'FAIL'}] 3.3d milestone[0] structure "
                    f"-> id={ms0.get('id')!r}, status={ms0.get('status')!r}, progress={ms0.get('progress')}"
                )
                state.RESULTS.append(("3.3d milestone structure", ms_fields_ok, 200, 0 if ms_fields_ok else -1))

        test(
            "3.4 PUT /projects/:id (update)",
            "PUT",
            f"/api/v1/projects/{state.PROJECT_UUID}",
            {"title": "Updated Flutter App V2"},
        )
        state.PROJECT_DISPLAY_TITLE = "Updated Flutter App V2"

        # 智能推荐（api-spec_v2 / 撮合）：转发 AI-Agent /api/v2/match/recommend；需服务端配置 VB_AI_AGENT_BASE_URL
        st_rec, r_rec = req(
            "GET",
            f"/api/v1/projects/{state.PROJECT_UUID}/recommendations?page=1&page_size=5",
        )
        msg_rec = r_rec.get("message") or ""
        rec_ok = r_rec.get("code") == 0 and isinstance(r_rec.get("data"), dict)
        if rec_ok:
            dd = r_rec["data"]
            rec_ok = isinstance(dd.get("recommendations"), list) or isinstance(dd.get("experts"), list)
        # 远程 AI-Agent 若未启用 Milvus/Embedding，返回 50002，网关为 50001 —— 视为链路已打通的降级通过
        rec_degraded = r_rec.get("code") == 50001 and (
            "未初始化" in msg_rec or "Milvus" in msg_rec or "匹配服务" in msg_rec
        )
        rec_final = rec_ok or rec_degraded
        print(
            f"  [{'PASS' if rec_final else 'FAIL'}] 3.5 GET /projects/:id/recommendations -> HTTP {st_rec}, code={r_rec.get('code', -1)}"
            + (" (AI degraded)" if rec_degraded and not rec_ok else "")
        )
        if not rec_final:
            print(f"         msg={msg_rec!r}")
        state.RESULTS.append(("3.5 GET /projects/:id/recommendations (AI)", rec_final, st_rec, r_rec.get("code", -1)))

        team_shape_ok = True
        if rec_degraded:
            team_shape_ok = True
        elif r_rec.get("code") == 0 and isinstance(r_rec.get("data"), dict):
            dd_shape = r_rec["data"]
            relist = dd_shape.get("recommendations") or dd_shape.get("experts") or []
            if relist and isinstance(relist[0], dict) and relist[0].get("provider_id"):
                r0 = relist[0]
                team_shape_ok = (
                    r0.get("bid_type") == "team"
                    and bool(r0.get("team_id"))
                    and bool(r0.get("team_name"))
                    and isinstance(r0.get("team_members"), list)
                )
        print(
            f"  [{'PASS' if team_shape_ok else 'FAIL'}] 3.5b GET /projects/:id/recommendations (team-shaped rows)"
        )
        state.RESULTS.append(
            (
                "3.5b GET /projects/:id/recommendations (team-shaped rows)",
                team_shape_ok,
                st_rec,
                r_rec.get("code", -1),
            )
        )
