"""§5 需求广场与 §5.4 收藏。"""

import concurrent.futures
import uuid

from . import state
from .helpers import cf, req, test


def _project_favorite_count():
    """GET /projects/:uuid 返回的 favorite_count，失败返回 None。"""
    if not state.PROJECT_UUID:
        return None
    st, rr = req("GET", f"/api/v1/projects/{state.PROJECT_UUID}")
    if st != 200 or rr.get("code") != 0:
        return None
    d = rr.get("data")
    if not isinstance(d, dict):
        return None
    try:
        return int(d.get("favorite_count", 0))
    except (TypeError, ValueError):
        return None


def run():
    print("\n--- 5. 需求广场 ---")
    test("5.1 GET /market/projects", "GET", "/api/v1/market/projects?page=1&page_size=10")
    test("5.2 GET /market/projects (filter)", "GET", "/api/v1/market/projects?category=dev")

    ok, r = test(
        "5.3 GET /market/experts",
        "GET",
        "/api/v1/market/experts?page=1&page_size=10",
        need_auth=False,
    )
    state.EXPERT_UUID_FOR_FAV = None
    state.EXPERT_TEAM_UUID = None
    if ok:
        data = r.get("data", [])
        print(f"         experts count: {len(data)}")
        if data and len(data) > 0:
            cf(data[0], ["id", "nickname", "rating", "skills", "hourly_rate", "leader_uuid"], "expert[0]")
            state.EXPERT_UUID_FOR_FAV = data[0].get("leader_uuid")
            state.EXPERT_TEAM_UUID = data[0].get("id")

            # 5.3b 团队实体对齐：响应应含团队维度字段
            team_fields = ["team_name", "vibe_level", "vibe_power", "member_count"]
            tf_ok = cf(data[0], team_fields, "expert[0] team fields")
            print(
                f"  [{'PASS' if tf_ok else 'FAIL'}] 5.3b market/experts team fields "
                f"-> team_name={data[0].get('team_name')!r}, vibe_level={data[0].get('vibe_level')!r}, "
                f"vibe_power={data[0].get('vibe_power')}, member_count={data[0].get('member_count')}"
            )
            state.RESULTS.append(("5.3b market/experts team fields", tf_ok, 200, 0 if tf_ok else -1))

    # ==================== 5.4 收藏（POST/DELETE /favorites，GET /users/me/favorites）====================
    print("\n--- 5.4 收藏 ---")

    if state.PROJECT_UUID:
        fc_base = _project_favorite_count()
        if fc_base is None:
            fc_base = 0
        test(
            "5.4a1 POST /favorites (invalid target_type -> 99001)",
            "POST",
            "/api/v1/favorites",
            {"target_type": "repo", "target_id": state.PROJECT_UUID},
            expect_code=99001,
            expect_http=400,
        )
        fake_puuid = str(uuid.uuid4())
        test(
            "5.4a2 POST /favorites (project not found -> 20001)",
            "POST",
            "/api/v1/favorites",
            {"target_type": "project", "target_id": fake_puuid},
            expect_code=20001,
            expect_http=404,
        )
        if state.USER_ID:
            test(
                "5.4a3 POST /favorites (self as expert, ineligible -> 30010)",
                "POST",
                "/api/v1/favorites",
                {"target_type": "expert", "target_id": state.USER_ID},
                expect_code=30010,
                expect_http=400,
            )

        fake_euuid = str(uuid.uuid4())
        test(
            "5.4a4 POST /favorites (expert uuid not found -> 30010)",
            "POST",
            "/api/v1/favorites",
            {"target_type": "expert", "target_id": fake_euuid},
            expect_code=30010,
            expect_http=400,
        )

        ok_add, r_add = test(
            "5.4b POST /favorites (project)",
            "POST",
            "/api/v1/favorites",
            {"target_type": "project", "target_id": state.PROJECT_UUID},
        )
        fc_after_add = _project_favorite_count()
        cnt_ok = fc_after_add is not None and fc_after_add == fc_base + 1
        print(
            f"  [{'PASS' if cnt_ok else 'FAIL'}] 5.4b1 GET /projects/:id favorite_count after add "
            f"-> {fc_after_add} (expect {fc_base + 1})"
        )
        state.RESULTS.append(("5.4b1 favorite_count +1", cnt_ok, 200, 0 if cnt_ok else -1))

        ok_idem, r_idem = test(
            "5.4c POST /favorites (project, idempotent)",
            "POST",
            "/api/v1/favorites",
            {"target_type": "project", "target_id": state.PROJECT_UUID},
        )
        idem_msg = (r_idem.get("message") or "") if isinstance(r_idem, dict) else ""
        idem_ok = ok_idem and isinstance(r_idem.get("data"), dict) and r_idem["data"].get("id")
        fc_after_idem = _project_favorite_count()
        cnt_stable = fc_after_idem == fc_base + 1
        idem_full = idem_ok and cnt_stable and ("已收藏" in idem_msg)
        print(
            f"  [{'PASS' if idem_full else 'FAIL'}] 5.4c1 idempotent message + favorite_count unchanged "
            f"-> count={fc_after_idem}"
        )
        state.RESULTS.append(("5.4c1 favorite idempotent count", idem_full, 200, 0 if idem_full else -1))

        ok_list, r_list = test(
            "5.4d GET /users/me/favorites?target_type=project",
            "GET",
            "/api/v1/users/me/favorites?target_type=project&page=1&page_size=20",
        )
        list_ok = False
        if ok_list and isinstance(r_list.get("data"), list):
            ids = [x.get("target_id") for x in r_list["data"] if isinstance(x, dict)]
            list_ok = state.PROJECT_UUID in ids
        print(
            f"  [{'PASS' if list_ok else 'FAIL'}] 5.4d1 favorites list contains project uuid"
        )
        state.RESULTS.append(("5.4d1 GET /me/favorites project", list_ok, 200, 0 if list_ok else -1))

        ok_del, _ = test(
            "5.4e DELETE /favorites (project)",
            "DELETE",
            "/api/v1/favorites",
            {"target_type": "project", "target_id": state.PROJECT_UUID},
        )
        fc_after_del = _project_favorite_count()
        del_cnt_ok = fc_after_del is not None and fc_after_del == fc_base
        print(
            f"  [{'PASS' if del_cnt_ok else 'FAIL'}] 5.4e1 GET /projects/:id favorite_count after delete "
            f"-> {fc_after_del} (expect {fc_base})"
        )
        state.RESULTS.append(("5.4e1 favorite_count restored", del_cnt_ok, 200, 0 if del_cnt_ok else -1))

        ok_del2, _ = test(
            "5.4f DELETE /favorites (project, idempotent)",
            "DELETE",
            "/api/v1/favorites",
            {"target_type": "project", "target_id": state.PROJECT_UUID},
        )
        print(
            f"  [{'PASS' if ok_del2 else 'FAIL'}] 5.4f1 DELETE when not favorited (idempotent)"
        )
        state.RESULTS.append(("5.4f DELETE idempotent", ok_del2, 200, 0 if ok_del2 else -1))

        test(
            "5.4g DELETE /favorites (invalid target_type -> 99001)",
            "DELETE",
            "/api/v1/favorites",
            {"target_type": "invalid", "target_id": state.PROJECT_UUID},
            expect_code=99001,
            expect_http=400,
        )

        # 5.4j 并发 POST 同一项目收藏：1062 幂等 + favorite_count 原子 +1（非单元测试，依赖 HTTP 并发）
        fc_before_conc = _project_favorite_count()
        if fc_before_conc is None:
            fc_before_conc = 0
        body_conc = {"target_type": "project", "target_id": state.PROJECT_UUID}

        def _post_favorite_concurrent():
            return req("POST", "/api/v1/favorites", body_conc)

        with concurrent.futures.ThreadPoolExecutor(max_workers=12) as pool:
            futs = [pool.submit(_post_favorite_concurrent) for _ in range(12)]
            conc_results = [fu.result() for fu in concurrent.futures.as_completed(futs)]

        conc_all_200 = all(st == 200 for st, _ in conc_results)
        conc_all_code0 = all(
            isinstance(r, dict) and r.get("code") == 0 for _, r in conc_results
        )
        fc_after_conc = _project_favorite_count()
        conc_count_ok = (
            fc_after_conc is not None and fc_before_conc is not None and fc_after_conc == fc_before_conc + 1
        )
        conc_ok = conc_all_200 and conc_all_code0 and conc_count_ok
        print(
            f"  [{'PASS' if conc_ok else 'FAIL'}] 5.4j concurrent POST /favorites x12 "
            f"-> all HTTP 200 & code=0: {conc_all_200 and conc_all_code0}, "
            f"favorite_count {fc_before_conc}->{fc_after_conc} (expect +1)"
        )
        state.RESULTS.append(("5.4j concurrent favorite + atomic count", conc_ok, 200, 0 if conc_ok else -1))

        _, _ = req(
            "DELETE",
            "/api/v1/favorites",
            {"target_type": "project", "target_id": state.PROJECT_UUID},
        )
    else:
        print("  [SKIP] 5.4 无 PROJECT_UUID，跳过收藏用例")

    # 5.4h 用团队 UUID 收藏专家（target_id 存储团队 UUID）
    if state.EXPERT_TEAM_UUID and state.USER_ID:
        ok_e, r_e = test(
            "5.4h POST /favorites (expert via team UUID)",
            "POST",
            "/api/v1/favorites",
            {"target_type": "expert", "target_id": state.EXPERT_TEAM_UUID},
        )
        if ok_e:
            ok_el, r_el = test(
                "5.4h1 GET /users/me/favorites?target_type=expert",
                "GET",
                "/api/v1/users/me/favorites?target_type=expert&page=1&page_size=20",
            )
            el_ok = False
            if ok_el and isinstance(r_el.get("data"), list):
                eids = [x.get("target_id") for x in r_el["data"] if isinstance(x, dict)]
                el_ok = state.EXPERT_TEAM_UUID in eids
            print(
                f"  [{'PASS' if el_ok else 'FAIL'}] 5.4h2 favorites target_id is team uuid "
                f"(expect {state.EXPERT_TEAM_UUID!r} in list)"
            )
            state.RESULTS.append(("5.4h2 GET /me/favorites expert (team uuid)", el_ok, 200, 0 if el_ok else -1))
            test(
                "5.4i DELETE /favorites (expert via team UUID)",
                "DELETE",
                "/api/v1/favorites",
                {"target_type": "expert", "target_id": state.EXPERT_TEAM_UUID},
            )
    elif state.EXPERT_TEAM_UUID is None:
        print("  [SKIP] 5.4h–i 无市场专家数据，跳过专家收藏用例")

    # 5.4h3–h6 用 leader UUID 收藏专家（后端自动解析为团队 UUID 存储）
    if (
        state.EXPERT_TEAM_UUID
        and state.EXPERT_UUID_FOR_FAV
        and state.USER_ID
        and state.EXPERT_UUID_FOR_FAV != state.USER_ID
    ):
        ok_t, r_t = test(
            "5.4h3 POST /favorites (expert via leader UUID -> team UUID)",
            "POST",
            "/api/v1/favorites",
            {"target_type": "expert", "target_id": state.EXPERT_UUID_FOR_FAV},
        )
        if ok_t:
            ok_tl, r_tl = test(
                "5.4h4 GET /users/me/favorites?target_type=expert (after leader uuid add)",
                "GET",
                "/api/v1/users/me/favorites?target_type=expert&page=1&page_size=20",
            )
            tid_ok = False
            if ok_tl and isinstance(r_tl.get("data"), list):
                stored_ids = [x.get("target_id") for x in r_tl["data"] if isinstance(x, dict)]
                tid_ok = state.EXPERT_TEAM_UUID in stored_ids
            print(
                f"  [{'PASS' if tid_ok else 'FAIL'}] 5.4h5 favorites target_id stored as team uuid "
                f"(expect {state.EXPERT_TEAM_UUID!r} in list)"
            )
            state.RESULTS.append(("5.4h5 leader uuid -> team uuid in favorites", tid_ok, 200, 0 if tid_ok else -1))

            # idempotent: re-add with team uuid should be already-favorited
            ok_idem, r_idem = test(
                "5.4h5b POST /favorites (expert team uuid idempotent)",
                "POST",
                "/api/v1/favorites",
                {"target_type": "expert", "target_id": state.EXPERT_TEAM_UUID},
            )
            idem_ok = ok_idem and r_idem.get("message", "").find("已收藏") >= 0
            print(f"  [{'PASS' if idem_ok else 'FAIL'}] 5.4h5c idempotent check (leader uuid then team uuid)")
            state.RESULTS.append(("5.4h5c idempotent leader+team uuid", idem_ok, 200, 0 if idem_ok else -1))

            test(
                "5.4h6 DELETE /favorites (expert via leader UUID)",
                "DELETE",
                "/api/v1/favorites",
                {"target_type": "expert", "target_id": state.EXPERT_UUID_FOR_FAV},
            )
    elif state.EXPERT_TEAM_UUID is None:
        print("  [SKIP] 5.4h3–h6 无团队 UUID，跳过团队 UUID 收藏用例")
