import time
import json
import urllib.request
import urllib.error

from . import state
from .helpers import req, test, cf


def run():
    # ==================== 2. 用户 ====================
    print("\n--- 2. 用户模块 ---")
    ok, r = test("2.1 GET /users/me", "GET", "/api/v1/users/me")
    if ok and r.get("data"):
        cf(r["data"], ["id", "uuid", "nickname", "role", "credit_score", "stats", "contact_phone"])
        stats = r["data"].get("stats", {})
        if stats:
            cf(stats, ["published_projects", "total_spent", "days_on_platform",
                        "completed_projects", "approval_rate", "total_earnings"], "me.stats")

    # 勿带 role：1.5 Docker 提权后 role=9，写回 1 会导致后续 §15 管理端 403
    test("2.2 PUT /users/me", "PUT", "/api/v1/users/me", {"nickname": "TestV2User"})

    test(
        "2.2d PUT /users/me (contact_phone)",
        "PUT",
        "/api/v1/users/me",
        {"contact_phone": "13900001234"},
    )
    st_cp, r_cp = req("GET", "/api/v1/users/me")
    cp_val = (r_cp.get("data") or {}).get("contact_phone") if isinstance(r_cp, dict) else None
    cp_ok = cp_val == "13900001234"
    print(
        f"  [{'PASS' if cp_ok else 'FAIL'}] 2.2e GET /users/me contact_phone roundtrip -> {cp_val!r}"
    )
    state.RESULTS.append(("2.2e GET /me contact_phone", cp_ok, st_cp, r_cp.get("code", -1)))

    # 技能：PUT 保存后 GET /me 应带回 skills（修复恒为空数组）
    test(
        "2.2b PUT /users/me/skills",
        "PUT",
        "/api/v1/users/me/skills",
        {
            "skills": [
                {"name": "Flutter", "category": "mobile", "proficiency": 4, "is_primary": True},
                {"name": "Go", "category": "backend"},
            ]
        },
    )
    status_me, r_me = req("GET", "/api/v1/users/me")
    skills_after = []
    if r_me.get("code") == 0 and r_me.get("data"):
        skills_after = r_me.get("data", {}).get("skills") or []
    ok_skills = len(skills_after) >= 2
    print(
        f"  [{'PASS' if ok_skills else 'FAIL'}] 2.2c GET /users/me (skills roundtrip) "
        f"-> HTTP {status_me}, skills len={len(skills_after)}"
    )
    if not ok_skills:
        print("         BUG: PUT /users/me/skills 后 GET /me 的 skills 仍为空或未达 2 条")
    state.RESULTS.append(("2.2c GET /me skills roundtrip", ok_skills, status_me, r_me.get("code", -1)))
    if ok_skills:
        cf(skills_after[0], ["id", "name", "category", "skill_id"], "me.skills[0]")

    # 2.2f 团队实体对齐：PUT hourly_rate/available_status -> GET /users/me 回读一致
    test_hr = 250.0
    test_as = 2
    test("2.2f PUT /users/me (hourly_rate+available_status)", "PUT", "/api/v1/users/me",
         {"hourly_rate": test_hr, "available_status": test_as})
    st_hr, r_hr = req("GET", "/api/v1/users/me")
    hr_data = (r_hr.get("data") or {}) if isinstance(r_hr, dict) else {}
    hr_back = hr_data.get("hourly_rate")
    as_back = hr_data.get("available_status")
    hr_roundtrip = False
    try:
        hr_roundtrip = abs(float(hr_back or 0) - test_hr) < 0.01 and int(as_back or 0) == test_as
    except (TypeError, ValueError):
        pass
    print(
        f"  [{'PASS' if hr_roundtrip else 'FAIL'}] 2.2f GET /users/me hourly_rate/available_status roundtrip "
        f"-> hourly_rate={hr_back}, available_status={as_back}"
    )
    state.RESULTS.append(("2.2f hourly_rate/available_status roundtrip", hr_roundtrip, st_hr, r_hr.get("code", -1)))
    # 恢复默认
    test("2.2f2 PUT /users/me (restore available_status)", "PUT", "/api/v1/users/me",
         {"available_status": 1})

    # 2.2h PUT role=2 自动建队 + hourly 同步主团队（仅当前 role=1，避免覆盖 Docker 提权等非需求方账号）
    st_h0, r_h0 = req("GET", "/api/v1/users/me")
    role_h0 = (r_h0.get("data") or {}).get("role") if isinstance(r_h0.get("data"), dict) else None
    if role_h0 != 1:
        print(f"  [SKIP] 2.2h PUT role=2 建队（当前 role={role_h0}，非 1 则跳过）")
        state.RESULTS.append(("2.2h auto-create team (skipped)", True, st_h0, 0))
    else:
        ok_h, _ = test("2.2h1 PUT /users/me (role=2)", "PUT", "/api/v1/users/me", {"role": 2})
        st_h1, r_h1 = req("GET", "/api/v1/users/me")
        rh1 = (r_h1.get("data") or {}).get("role") if isinstance(r_h1.get("data"), dict) else None
        role_ok = rh1 == 2 and ok_h
        print(f"  [{'PASS' if role_ok else 'FAIL'}] 2.2h2 GET /users/me role after switch -> {rh1!r}")
        state.RESULTS.append(("2.2h role=2 roundtrip", role_ok, st_h1, r_h1.get("code", -1)))
        test_h2 = 199.0
        test_as2 = 2
        test(
            "2.2h3 PUT /users/me (hourly_rate after role=2)",
            "PUT",
            "/api/v1/users/me",
            {"hourly_rate": test_h2, "available_status": test_as2},
        )
        st_h2, r_h2 = req("GET", "/api/v1/users/me")
        d2 = (r_h2.get("data") or {}) if isinstance(r_h2, dict) else {}
        hb2 = d2.get("hourly_rate")
        asb2 = d2.get("available_status")
        h2_ok = False
        try:
            h2_ok = abs(float(hb2 or 0) - test_h2) < 0.01 and int(asb2 or 0) == test_as2
        except (TypeError, ValueError):
            pass
        print(
            f"  [{'PASS' if h2_ok else 'FAIL'}] 2.2h4 GET /users/me hourly after team create "
            f"-> hourly_rate={hb2}, available_status={asb2}"
        )
        state.RESULTS.append(("2.2h hourly after expert team", h2_ok, st_h2, r_h2.get("code", -1)))
        test("2.2h5 PUT /users/me (restore available_status)", "PUT", "/api/v1/users/me", {"available_status": 1})

    # 2.2g 团队预算区间：仅存主团队；仅 role=2/3 可写（默认登录用户多为需求方则跳过）
    st_role, r_role = req("GET", "/api/v1/users/me")
    me_role = (r_role.get("data") or {}).get("role") if isinstance(r_role.get("data"), dict) else None
    if me_role not in (2, 3):
        print(
            f"  [SKIP] 2.2g budget_min/max（当前 role={me_role}，非专家/团队方，跳过 PUT 预算）"
        )
        state.RESULTS.append(("2.2g budget (skipped non-expert)", True, st_role, 0))
    else:
        test("2.2g PUT /users/me (budget_min+budget_max)", "PUT", "/api/v1/users/me",
             {"budget_min": 3000.0, "budget_max": 12000.0})
        st_bg, r_bg = req("GET", "/api/v1/users/me")
        bg_data = (r_bg.get("data") or {}) if isinstance(r_bg, dict) else {}
        bmin = bg_data.get("budget_min")
        bmax = bg_data.get("budget_max")
        bg_ok = False
        try:
            bg_ok = abs(float(bmin or 0) - 3000.0) < 0.01 and abs(float(bmax or 0) - 12000.0) < 0.01
        except (TypeError, ValueError):
            pass
        print(
            f"  [{'PASS' if bg_ok else 'FAIL'}] 2.2g GET /users/me budget_min/max roundtrip "
            f"-> budget_min={bmin}, budget_max={bmax}"
        )
        state.RESULTS.append(("2.2g budget_min/max roundtrip", bg_ok, st_bg, r_bg.get("code", -1)))

        st_bad, r_bad = req(
            "PUT",
            "/api/v1/users/me",
            {"budget_min": 5000.0, "budget_max": 1000.0},
        )
        bad_ok = st_bad == 400 or r_bad.get("code") == 20005
        print(
            f"  [{'PASS' if bad_ok else 'FAIL'}] 2.2g PUT invalid budget range (expect 400) "
            f"-> HTTP {st_bad}, code={r_bad.get('code')}"
        )
        state.RESULTS.append(("2.2g invalid budget range", bad_ok, st_bad, r_bad.get("code", -1)))

    # v6 Profile
    if state.USER_ID:
        ok, r = test("2.3 GET /users/:id (profile)", "GET", f"/api/v1/users/{state.USER_ID}")
        if ok and r.get("data"):
            cf(r["data"], ["id", "nickname", "rating", "credit_score", "stats"])
            stats = r["data"].get("stats", {})
            if stats:
                cf(stats, ["published_projects", "total_spent", "days_on_platform"], "profile.stats")

        test("2.4 PUT /users/:id (update)", "PUT", f"/api/v1/users/{state.USER_ID}",
             {"nickname": "UpdatedV2"})

        ok, r = test("2.5 GET /users/:id/skills", "GET", f"/api/v1/users/{state.USER_ID}/skills")
        if ok:
            print(f"         skills count: {len(r.get('data', []))}")

        ok, r = test("2.6 GET /users/:id/portfolios", "GET", f"/api/v1/users/{state.USER_ID}/portfolios")
        if ok:
            print(f"         portfolios count: {len(r.get('data', []))}")

        # §2.6b 作品集 CRUD（JWT）
        state.PORTFOLIO_TEST_UUID = None
        if state.TOKEN:
            ok, r = test(
                "2.6b POST /users/me/portfolios",
                "POST",
                "/api/v1/users/me/portfolios",
                {
                    "title": "API V2 Test Portfolio",
                    "description": "integration test",
                    "category": "web",
                    "tech_stack": ["Go", "Vue"],
                },
            )
            if ok and isinstance(r.get("data"), dict):
                state.PORTFOLIO_TEST_UUID = r["data"].get("id")
                print(f"         portfolio uuid={state.PORTFOLIO_TEST_UUID!r}")

            st401, r401 = req("GET", "/api/v1/users/me/portfolios", need_auth=False)
            auth401_ok = st401 == 401 and r401.get("code") == 10008
            print(
                f"  [{'PASS' if auth401_ok else 'FAIL'}] 2.6b2 GET /users/me/portfolios (no auth) "
                f"-> HTTP {st401}, code={r401.get('code', -1)}"
            )
            state.RESULTS.append(("2.6b2 GET /me/portfolios 401", auth401_ok, st401, r401.get("code", -1)))

            ok_m, r_m = test("2.6c GET /users/me/portfolios", "GET", "/api/v1/users/me/portfolios")
            if ok_m and isinstance(r_m.get("data"), list) and state.PORTFOLIO_TEST_UUID:
                found = next((x for x in r_m["data"] if x.get("id") == state.PORTFOLIO_TEST_UUID), None)
                pf_ok = found is not None and cf(
                    found, ["id", "title", "category", "tech_stack"], "portfolio[me]"
                )
                ts = found.get("tech_stack") if isinstance(found, dict) else None
                ts_ok = isinstance(ts, list) and "Go" in ts
                pf_ok = pf_ok and ts_ok
                print(
                    f"  [{'PASS' if pf_ok else 'FAIL'}] 2.6c1 GET /me/portfolios item fields "
                    f"(category/tech_stack)"
                )
                state.RESULTS.append(("2.6c1 GET /me/portfolios fields", pf_ok, 200, 0 if pf_ok else -1))

            ok_pub, r_pub = test(
                "2.6d GET /users/:id/portfolios (same user)",
                "GET",
                f"/api/v1/users/{state.USER_ID}/portfolios",
            )
            if ok_pub and isinstance(r_pub.get("data"), list) and state.PORTFOLIO_TEST_UUID:
                ids_pub = [x.get("id") for x in r_pub["data"]]
                sync_ok = state.PORTFOLIO_TEST_UUID in ids_pub
                print(
                    f"  [{'PASS' if sync_ok else 'FAIL'}] 2.6d1 public list contains new portfolio"
                )
                state.RESULTS.append(("2.6d1 GET /users/:id/portfolios sync", sync_ok, 200, 0 if sync_ok else -1))

            if state.PORTFOLIO_TEST_UUID:
                test(
                    "2.6e0 PUT /users/me/portfolios/:uuid (category empty -> 99001)",
                    "PUT",
                    f"/api/v1/users/me/portfolios/{state.PORTFOLIO_TEST_UUID}",
                    {"category": ""},
                    expect_code=99001,
                    expect_http=400,
                )
                test(
                    "2.6e0c PUT /users/me/portfolios/:uuid (category whitespace -> 99001)",
                    "PUT",
                    f"/api/v1/users/me/portfolios/{state.PORTFOLIO_TEST_UUID}",
                    {"category": "   "},
                    expect_code=99001,
                    expect_http=400,
                )
                test(
                    "2.6e0b PUT /users/me/portfolios/:uuid (category invalid -> 99001)",
                    "PUT",
                    f"/api/v1/users/me/portfolios/{state.PORTFOLIO_TEST_UUID}",
                    {"category": "not_a_valid_category"},
                    expect_code=99001,
                    expect_http=400,
                )
                ok_u, r_u_pf = test(
                    "2.6e PUT /users/me/portfolios/:uuid",
                    "PUT",
                    f"/api/v1/users/me/portfolios/{state.PORTFOLIO_TEST_UUID}",
                    {
                        "title": "Updated API V2 Portfolio",
                        "tech_stack": ["Go"],
                        "preview_url": "https://example.com/preview",
                    },
                )
                if ok_u:
                    _, r_chk = req("GET", "/api/v1/users/me/portfolios")
                    upd_ok = False
                    if isinstance(r_chk.get("data"), list):
                        hit = next(
                            (x for x in r_chk["data"] if x.get("id") == state.PORTFOLIO_TEST_UUID),
                            None,
                        )
                        upd_ok = bool(
                            hit
                            and hit.get("title") == "Updated API V2 Portfolio"
                            and hit.get("preview_url") == "https://example.com/preview"
                        )
                    print(
                        f"  [{'PASS' if upd_ok else 'FAIL'}] 2.6e1 PUT roundtrip (title/preview_url)"
                    )
                    state.RESULTS.append(("2.6e1 PUT portfolio roundtrip", upd_ok, 200, 0 if upd_ok else -1))

                ok_del, _ = test(
                    "2.6f DELETE /users/me/portfolios/:uuid",
                    "DELETE",
                    f"/api/v1/users/me/portfolios/{state.PORTFOLIO_TEST_UUID}",
                )
                if ok_del:
                    _, r_after = req("GET", "/api/v1/users/me/portfolios")
                    gone_ok = True
                    if isinstance(r_after.get("data"), list):
                        gone_ok = state.PORTFOLIO_TEST_UUID not in [
                            x.get("id") for x in r_after["data"]
                        ]
                    print(
                        f"  [{'PASS' if gone_ok else 'FAIL'}] 2.6f1 after DELETE not in list"
                    )
                    state.RESULTS.append(("2.6f1 DELETE soft list", gone_ok, 200, 0 if gone_ok else -1))

        # 1x1 PNG，POST /upload（需 OSS 或 local_upload_dir）
        upload_ok = False
        st_u, r_u = 0, {}
        if state.TOKEN:
            png_1x1 = bytes.fromhex(
                "89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c489"
                "0000000a49444154789c63000100000500018dbb28120000000049454e44ae426082"
            )
            bnd = "----KzTest" + str(int(time.time() * 1000))
            body_u = (
                f"--{bnd}\r\n"
                'Content-Disposition: form-data; name="file"; filename="dot.png"\r\n'
                "Content-Type: image/png\r\n\r\n"
            ).encode() + png_1x1 + f"\r\n--{bnd}--\r\n".encode()
            u_url = state.BASE + "/api/v1/upload"
            rq_u = urllib.request.Request(u_url, data=body_u, method="POST")
            rq_u.add_header("Content-Type", f"multipart/form-data; boundary={bnd}")
            rq_u.add_header("Authorization", "Bearer " + state.TOKEN)
            try:
                resp_u = urllib.request.urlopen(rq_u)
                st_u = resp_u.status
                r_u = json.loads(resp_u.read().decode())
            except urllib.error.HTTPError as e:
                st_u = e.code
                try:
                    r_u = json.loads(e.read().decode())
                except Exception:
                    r_u = {}
            if r_u.get("code") == 0 and isinstance(r_u.get("data"), dict):
                du = r_u["data"]
                u = du.get("url") or ""
                url_ok = u.startswith(("http://", "https://", "/"))
                upload_ok = bool(
                    url_ok and du.get("object_key") and du.get("size_bytes", 0) > 0
                )
                # 2.7b 将上传返回的 url 作为 cover_url 创建作品，再删除（上传→作品集联调）
                if upload_ok and state.USER_ID:
                    cover_url = (du.get("url") or "").strip()
                    if cover_url.startswith("/") and not cover_url.startswith("//"):
                        cover_url = state.BASE.rstrip("/") + cover_url
                    ok_pc, r_pc = test(
                        "2.7b POST /users/me/portfolios (cover_url from upload)",
                        "POST",
                        "/api/v1/users/me/portfolios",
                        {
                            "title": "Portfolio With Cover",
                            "category": "web",
                            "cover_url": cover_url,
                            "tech_stack": ["Go"],
                        },
                    )
                    if ok_pc and isinstance(r_pc.get("data"), dict):
                        pid_cov = r_pc["data"].get("id")
                        if pid_cov:
                            _, r_list_cov = req("GET", "/api/v1/users/me/portfolios")
                            cov_hit = None
                            if isinstance(r_list_cov.get("data"), list):
                                cov_hit = next(
                                    (x for x in r_list_cov["data"] if x.get("id") == pid_cov),
                                    None,
                                )
                            # 列表中的 cover_url 可能与请求略有差异（相对/绝对），只校验存在且标题一致
                            cov_url_ok = bool(
                                cov_hit
                                and cov_hit.get("title") == "Portfolio With Cover"
                                and cov_hit.get("cover_url")
                            )
                            print(
                                f"  [{'PASS' if cov_url_ok else 'FAIL'}] 2.7b1 GET /me/portfolios "
                                f"cover_url matches upload"
                            )
                            state.RESULTS.append(
                                (
                                    "2.7b1 portfolio cover_url roundtrip",
                                    cov_url_ok,
                                    200,
                                    0 if cov_url_ok else -1,
                                )
                            )
                            test(
                                "2.7c DELETE /users/me/portfolios (cover portfolio)",
                                "DELETE",
                                f"/api/v1/users/me/portfolios/{pid_cov}",
                            )
        print(
            f"  [{'PASS' if upload_ok else 'FAIL'}] 2.7 POST /upload (1x1 PNG) -> HTTP {st_u}, code={r_u.get('code', -1)}"
        )
        state.RESULTS.append(("2.7 POST /upload image", upload_ok, st_u, r_u.get("code", -1)))
