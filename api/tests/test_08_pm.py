import re
import uuid
import os
import time
import json
import subprocess
import shutil
import tempfile

from . import state
from .helpers import req, test, cf, gen_phone, get_sms_code, mysql_scalar, mysql_exec


def run():
    # ==================== 8. Phase 4: 项目管理 ====================
    print("\n--- 8. Phase 4: 项目管理 ---")
    _UUID_RE = re.compile(
        r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
        re.I,
    )

    state.MS_UUID = None
    state.TOKEN_OUTSIDER = None  # 8.2f 第三方用户，用于 8.5 文件区越权校验
    if state.PROJECT_UUID:
        ok, r = test(
            "8.1 GET /projects/:id/tasks",
            "GET",
            f"/api/v1/projects/{state.PROJECT_UUID}/tasks",
        )
        if ok:
            print(f"         tasks: {len(r.get('data', []))}")

        ok, r = test(
            "8.2 POST /projects/:id/milestones (create)",
            "POST",
            f"/api/v1/projects/{state.PROJECT_UUID}/milestones",
            {
                "title": state.MILESTONE_TEST_TITLE,
                "description": "里程碑创建接口联调",
                "sort_order": 0,
                "due_date": "2026-12-31",
                "payment_ratio": 25.0,
            },
            expect_http=200,
        )
        if ok and isinstance(r.get("data"), dict):
            d = r["data"]
            state.MS_UUID = d.get("uuid") or d.get("id")
            pa = d.get("payment_amount")
            print(f"         milestone uuid={state.MS_UUID}, payment_amount={pa!r}")
            # 撮合后 bid 8000 → 25% 应为 2000
            if pa is not None and abs(float(pa) - 2000.0) < 0.02:
                print("         payment_amount 与 agreed_price×25% 一致 (≈2000)")
        test(
            "8.2b POST /projects/:id/milestones (payment_ratio sum>100% -> 21007)",
            "POST",
            f"/api/v1/projects/{state.PROJECT_UUID}/milestones",
            {
                "title": "集成测试-比例超额",
                "payment_ratio": 80.0,
            },
            expect_code=21007,
            expect_http=400,
        )
        _fake_pid = str(uuid.uuid4())
        test(
            "8.2c POST /projects/:id/milestones (project not found -> 20001)",
            "POST",
            f"/api/v1/projects/{_fake_pid}/milestones",
            {"title": "不存在的项目里程碑", "payment_ratio": 10.0},
            expect_code=20001,
            expect_http=404,
        )

        state.TASK_TEST_TITLE = "集成测试-手动任务"
        state.TASK_CREATE_UUID = None
        _task_body = {
            "title": state.TASK_TEST_TITLE,
            "ears_type": "event",
            "ears_behavior": "用户点击登录按钮后跳转首页",
            "priority": 2,
        }
        if state.MS_UUID:
            _task_body["milestone_id"] = state.MS_UUID
        ok_tk, r_tk = test(
            "8.2d POST /projects/:id/tasks (create manual)",
            "POST",
            f"/api/v1/projects/{state.PROJECT_UUID}/tasks",
            _task_body,
            expect_http=200,
        )
        if ok_tk and isinstance(r_tk.get("data"), dict):
            state.TASK_CREATE_UUID = r_tk["data"].get("uuid") or r_tk["data"].get("id")
            print(
                f"         task uuid={state.TASK_CREATE_UUID}, task_code={r_tk['data'].get('task_code')!r}"
            )

        # 8.2d2 创建响应中 milestone_id 须为里程碑 UUID（与 MS_UUID 一致），不得为数字主键
        ms_uuid_in_create_ok = True
        if not state.MS_UUID:
            print("  [SKIP] 8.2d2 无里程碑 UUID，跳过 milestone_id 格式断言")
        elif not ok_tk:
            ms_uuid_in_create_ok = False
            print("  [FAIL] 8.2d2 依赖 8.2d 创建成功以校验 milestone_id")
        elif isinstance(r_tk.get("data"), dict):
            dtk = r_tk["data"]
            mid = dtk.get("milestone_id")
            if (
                not mid
                or not _UUID_RE.match(str(mid))
                or str(mid).lower() != str(state.MS_UUID).lower()
            ):
                ms_uuid_in_create_ok = False
                print(
                    f"  [FAIL] 8.2d2 POST create task response milestone_id must be milestone UUID "
                    f"(got {mid!r}, expect {state.MS_UUID!r})"
                )
            else:
                print("  [PASS] 8.2d2 create response milestone_id is UUID and matches milestone")
        else:
            ms_uuid_in_create_ok = False
        state.RESULTS.append(
            (
                "8.2d2 create task milestone_id is UUID",
                ms_uuid_in_create_ok,
                200 if ok_tk else 0,
                0 if ms_uuid_in_create_ok else -1,
            )
        )

        st_tasks, r_tasks = req("GET", f"/api/v1/projects/{state.PROJECT_UUID}/tasks")
        tasks_list_ok = False
        if r_tasks.get("code") == 0 and isinstance(r_tasks.get("data"), list):
            rows_t = [x for x in r_tasks["data"] if isinstance(x, dict)]
            titles_t = [x.get("title") for x in rows_t]
            tasks_list_ok = state.TASK_TEST_TITLE in titles_t
            if state.TASK_CREATE_UUID:
                tasks_list_ok = tasks_list_ok and any(
                    (x.get("id") == state.TASK_CREATE_UUID or x.get("uuid") == state.TASK_CREATE_UUID)
                    for x in rows_t
                )
            # 列表项 milestone_id 须为 UUID（与创建时里程碑一致）
            if tasks_list_ok and state.MS_UUID and state.TASK_CREATE_UUID:
                for x in rows_t:
                    if not isinstance(x, dict):
                        continue
                    if x.get("title") != state.TASK_TEST_TITLE:
                        continue
                    lm = x.get("milestone_id")
                    if (
                        not lm
                        or not _UUID_RE.match(str(lm))
                        or str(lm).lower() != str(state.MS_UUID).lower()
                    ):
                        tasks_list_ok = False
                        print(
                            f"  [FAIL] 8.2e list task milestone_id must be UUID (got {lm!r}, expect {state.MS_UUID!r})"
                        )
                    break
            print(
                f"  [{'PASS' if tasks_list_ok else 'FAIL'}] 8.2e GET /projects/:id/tasks "
                f"(list contains created) -> HTTP {st_tasks}, n={len(rows_t)}"
            )
            if not tasks_list_ok:
                print(
                    f"         titles={titles_t!r}, expect={state.TASK_TEST_TITLE!r}, uuid={state.TASK_CREATE_UUID!r}"
                )
        else:
            print(
                f"  [FAIL] 8.2e GET /projects/:id/tasks -> HTTP {st_tasks}, code={r_tasks.get('code')}"
            )
        state.RESULTS.append(
            ("8.2e GET tasks list contains created", tasks_list_ok, st_tasks, r_tasks.get("code", -1))
        )

        # 8.2f 指派人须属于项目：第三方用户 assignee_id -> 21011 + HTTP 400
        phone3 = gen_phone()
        test(
            "8.2f0 POST /auth/sms-code (user3 outsider)",
            "POST",
            "/api/v1/auth/sms-code",
            {"phone": phone3, "purpose": 2},
            need_auth=False,
        )
        time.sleep(0.3)
        sc3 = get_sms_code(phone3) or "952786"
        ok3, r3 = test(
            "8.2f1 POST /auth/login (user3)",
            "POST",
            "/api/v1/auth/login",
            {"phone": phone3, "code": sc3},
            need_auth=False,
        )
        USER3_ID = None
        if ok3 and isinstance(r3.get("data"), dict):
            USER3_ID = r3["data"].get("user_id")
            state.TOKEN_OUTSIDER = r3["data"].get("access_token")
        assignee_guard_ok = False
        if not USER3_ID or not _UUID_RE.match(str(USER3_ID)):
            print("  [SKIP] 8.2f 无有效 user3 UUID，跳过 assignee 校验")
            state.RESULTS.append(("8.2f assignee outsider -> 21011 (skipped)", True, 0, 0))
        else:
            st_af, r_af = req(
                "POST",
                f"/api/v1/projects/{state.PROJECT_UUID}/tasks",
                {
                    "title": "集成测试-非法指派人",
                    "ears_type": "event",
                    "ears_behavior": "assignee 须为项目相关方",
                    "assignee_id": str(USER3_ID),
                },
            )
            assignee_guard_ok = r_af.get("code") == 21011 and st_af == 400
            print(
                f"  [{'PASS' if assignee_guard_ok else 'FAIL'}] 8.2f POST /tasks (outsider assignee) "
                f"-> HTTP {st_af}, code={r_af.get('code')}"
            )
            if not assignee_guard_ok:
                print(f"         expect code=21011 HTTP=400, body={r_af!r}")
            state.RESULTS.append(
                ("8.2f assignee outsider -> 21011", assignee_guard_ok, st_af, r_af.get("code", -1))
            )

        st_ms, r_ms = req("GET", f"/api/v1/projects/{state.PROJECT_UUID}/milestones")
        ms_list_ok = False
        if r_ms.get("code") == 0 and isinstance(r_ms.get("data"), list):
            rows = [x for x in r_ms["data"] if isinstance(x, dict)]
            titles = [x.get("title") for x in rows]
            ms_list_ok = state.MILESTONE_TEST_TITLE in titles
            if state.MS_UUID:
                ms_list_ok = ms_list_ok and any(
                    (x.get("id") == state.MS_UUID or x.get("uuid") == state.MS_UUID) for x in rows
                )
            print(
                f"  [{'PASS' if ms_list_ok else 'FAIL'}] 8.3 GET /projects/:id/milestones "
                f"(list contains created) -> HTTP {st_ms}, n={len(rows)}"
            )
            if not ms_list_ok:
                print(
                    f"         titles={titles!r}, expect title={state.MILESTONE_TEST_TITLE!r}, uuid={state.MS_UUID!r}"
                )
        else:
            print(
                f"  [FAIL] 8.3 GET /projects/:id/milestones -> HTTP {st_ms}, code={r_ms.get('code')}"
            )
        state.RESULTS.append(
            ("8.3 GET milestones list contains created", ms_list_ok, st_ms, r_ms.get("code", -1))
        )

        # 8.3d 里程碑交付 POST /milestones/:id/deliver（需 §7 撮合后 TOKEN2=服务方且项目已绑定 provider_id）
        _prov = None
        if state.PROJECT_UUID:
            _prov = mysql_scalar(
                f"SELECT provider_id FROM projects WHERE uuid='{state.PROJECT_UUID}' LIMIT 1"
            )
        _has_provider = (
            _prov is not None
            and str(_prov).strip() != ""
            and str(_prov).strip().upper() != "NULL"
        )
        if not state.MS_UUID:
            print("  [SKIP] 8.3d 无里程碑 UUID，跳过交付接口")
        elif not state.TOKEN2:
            print("  [SKIP] 8.3d 无 TOKEN2（§7 未撮合/未登录服务方），跳过交付接口")
        elif not _has_provider:
            print("  [SKIP] 8.3d 项目未绑定服务方（provider_id 空），跳过交付接口")
        else:
            tok_dm = state.TOKEN
            # 默认创建为 pending(1)，须进行中或打回后方可交付
            test(
                "8.3dp POST /milestones/:id/deliver (pending -> 21014)",
                "POST",
                f"/api/v1/milestones/{state.MS_UUID}/deliver",
                {"delivery_note": "未开始执行", "preview_url": "https://example.com/w"},
                auth_token=state.TOKEN2,
                expect_code=21014,
                expect_http=400,
            )
            mysql_exec(
                f"UPDATE milestones SET status=2 WHERE uuid='{state.MS_UUID}' "
                f"AND project_id=(SELECT id FROM projects WHERE uuid='{state.PROJECT_UUID}' LIMIT 1)"
            )
            # 8.3d0 交付说明与预览至少一项非空
            test(
                "8.3d0 POST /milestones/:id/deliver (empty note+url -> 99001)",
                "POST",
                f"/api/v1/milestones/{state.MS_UUID}/deliver",
                {"delivery_note": "", "preview_url": ""},
                auth_token=state.TOKEN2,
                expect_code=99001,
                expect_http=400,
            )
            # 8.3d1 需求方不可交付
            test(
                "8.3d1 POST /milestones/:id/deliver (demander -> 21013)",
                "POST",
                f"/api/v1/milestones/{state.MS_UUID}/deliver",
                {"delivery_note": "需求方尝试交付", "preview_url": "https://example.com/x"},
                auth_token=tok_dm,
                expect_code=21013,
                expect_http=403,
            )
            ok_del, r_del = test(
                "8.3d2 POST /milestones/:id/deliver (provider success)",
                "POST",
                f"/api/v1/milestones/{state.MS_UUID}/deliver",
                {
                    "delivery_note": "WSL 联调交付说明",
                    "preview_url": "https://example.com/milestone-preview",
                },
                auth_token=state.TOKEN2,
                expect_code=0,
                expect_http=200,
            )
            del_data_ok = (
                ok_del
                and isinstance(r_del.get("data"), dict)
                and r_del["data"].get("status") == "delivered"
                and (r_del.get("message") == "交付已提交")
            )
            if not del_data_ok and ok_del:
                print(
                    f"  [WARN] 8.3d2 响应 data/message 与预期不一致: {r_del.get('message')!r}, data={r_del.get('data')!r}"
                )
            state.RESULTS.append(
                (
                    "8.3d2 deliver response status=delivered",
                    del_data_ok,
                    200 if ok_del else 0,
                    0 if del_data_ok else -1,
                )
            )

            test(
                "8.3e POST /milestones/:id/accept (expert -> 20009 仅需求方)",
                "POST",
                f"/api/v1/milestones/{state.MS_UUID}/accept",
                {},
                auth_token=state.TOKEN2,
                expect_code=20009,
                expect_http=403,
            )
            test(
                "8.3f POST /milestones/:id/revision (expert -> 20009 仅需求方)",
                "POST",
                f"/api/v1/milestones/{state.MS_UUID}/revision",
                {"description": "专家尝试打回"},
                auth_token=state.TOKEN2,
                expect_code=20009,
                expect_http=403,
            )

            st_n22, r_n22 = req(
                "GET", "/api/v1/notifications?type=22&page_size=50", auth_token=tok_dm
            )
            rows_n22 = r_n22.get("data") if isinstance(r_n22.get("data"), list) else []
            hit_n22 = any(
                isinstance(x, dict)
                and (x.get("title") == "里程碑待验收" or "待验收" in (x.get("content") or ""))
                for x in rows_n22
            )
            print(
                f"  [{'PASS' if hit_n22 and r_n22.get('code') == 0 else 'FAIL'}] 8.3d3 GET /notifications?type=22 (需求方 里程碑待验收)"
            )
            state.RESULTS.append(
                (
                    "8.3d3 demander notification type=22 deliver",
                    hit_n22 and r_n22.get("code") == 0,
                    st_n22,
                    r_n22.get("code", -1),
                )
            )

            st_m3, r_m3 = req(
                "GET", f"/api/v1/projects/{state.PROJECT_UUID}/milestones", auth_token=tok_dm
            )
            ms_status_ok = False
            if r_m3.get("code") == 0 and isinstance(r_m3.get("data"), list):
                for row in r_m3["data"]:
                    if not isinstance(row, dict):
                        continue
                    if row.get("title") == state.MILESTONE_TEST_TITLE and row.get("status") == "delivered":
                        ms_status_ok = True
                        break
            print(
                f"  [{'PASS' if ms_status_ok else 'FAIL'}] 8.3d4 GET /projects/:id/milestones (含 status=delivered)"
            )
            state.RESULTS.append(
                ("8.3d4 milestone list status delivered", ms_status_ok, st_m3, r_m3.get("code", -1))
            )

            test(
                "8.3d5 POST /milestones/:id/deliver (duplicate -> 21009)",
                "POST",
                f"/api/v1/milestones/{state.MS_UUID}/deliver",
                {"delivery_note": "重复提交", "preview_url": "https://example.com/y"},
                auth_token=state.TOKEN2,
                expect_code=21009,
                expect_http=400,
            )

        ok, r = test(
            "8.4 GET /projects/:id/daily-reports",
            "GET",
            f"/api/v1/projects/{state.PROJECT_UUID}/daily-reports",
        )
        if ok and r.get("data"):
            print(f"         reports: {len(r['data'])}")

        # 8.5 项目共享文件（MinIO + multipart；无 curl 或 11013 时跳过）
        def _curl_post_project_file(puuid, tok, tmp_path, file_kind, milestone_uuid=None):
            cmd = [
                "curl",
                "-sS",
                "-X",
                "POST",
                state.BASE + f"/api/v1/projects/{puuid}/files",
                "-H",
                "Authorization: Bearer " + tok,
                "-F",
                "file=@" + tmp_path + ";type=text/plain",
                "-F",
                f"file_kind={file_kind}",
            ]
            if milestone_uuid:
                cmd.extend(["-F", f"milestone_id={milestone_uuid}"])
            cp = subprocess.run(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=120,
                check=False,
            )
            body = cp.stdout.decode(errors="replace").strip()
            try:
                j = json.loads(body) if body else {}
            except Exception:
                j = {"code": -1, "raw": body[:300]}
            return cp.returncode, j

        state.PROJECT_FILE_UUID_REF = None
        state.PROJECT_FILE_UUID_MS = None
        if not state.PROJECT_UUID:
            print("  [SKIP] 8.5 无 PROJECT_UUID")
        elif shutil.which("curl") is None:
            print("  [SKIP] 8.5 无 curl，跳过项目文件接口")
            state.RESULTS.append(("8.5 project files (curl missing)", False, 0, -1))
        else:
            st_pf0, r_pf0 = req(
                "GET", f"/api/v1/projects/{state.PROJECT_UUID}/files?page=1&page_size=20"
            )
            pf_list_ok0 = r_pf0.get("code") == 0 and isinstance(r_pf0.get("data"), list)
            print(
                f"  [{'PASS' if pf_list_ok0 else 'FAIL'}] 8.5a GET /projects/:id/files (demander) "
                f"-> HTTP {st_pf0}, code={r_pf0.get('code')}"
            )
            state.RESULTS.append(
                ("8.5a GET project files list (demander)", pf_list_ok0, st_pf0, r_pf0.get("code", -1))
            )

            fd_pf, tmp_pf = tempfile.mkstemp(suffix=".txt", text=False)
            try:
                os.write(fd_pf, b"kaizao project file integration ref\n")
                os.close(fd_pf)
                fd_pf = -1  # 已关闭，避免 finally 再次 close
                http_u1, up1 = _curl_post_project_file(
                    state.PROJECT_UUID, state.TOKEN, tmp_pf, "reference"
                )
                if up1.get("code") == 11013:
                    print("  [SKIP] 8.5b–8.5j 对象存储未启用 (11013)，跳过上传与后续文件断言")
                    state.RESULTS.append(("8.5 OSS disabled skip", True, 200, 11013))
                elif up1.get("code") != 0:
                    print(
                        f"  [FAIL] 8.5b POST /projects/:id/files (demander reference) "
                        f"curl_rc={http_u1}, code={up1.get('code')}, msg={up1.get('message')!r}"
                    )
                    state.RESULTS.append(
                        ("8.5b POST project file reference", False, 200, up1.get("code", -1))
                    )
                else:
                    d1 = up1.get("data") if isinstance(up1.get("data"), dict) else {}
                    state.PROJECT_FILE_UUID_REF = d1.get("uuid")
                    ref_ok = (
                        http_u1 == 0
                        and state.PROJECT_FILE_UUID_REF
                        and _UUID_RE.match(str(state.PROJECT_FILE_UUID_REF))
                        and d1.get("file_kind") == "reference"
                        and (d1.get("download_url") or "").startswith(("http://", "https://"))
                    )
                    print(
                        f"  [{'PASS' if ref_ok else 'FAIL'}] 8.5b POST /projects/:id/files (demander reference)"
                    )
                    state.RESULTS.append(
                        ("8.5b POST project file reference", ref_ok, 200, 0 if ref_ok else -1)
                    )

                    st_pf1, r_pf1 = req(
                        "GET",
                        f"/api/v1/projects/{state.PROJECT_UUID}/files?page=1&page_size=20&with_url=1",
                    )
                    rows_pf = r_pf1.get("data") if isinstance(r_pf1.get("data"), list) else []
                    hit_ref = next(
                        (
                            x
                            for x in rows_pf
                            if isinstance(x, dict)
                            and x.get("uuid") == state.PROJECT_FILE_UUID_REF
                        ),
                        None,
                    )
                    list_ok = (
                        r_pf1.get("code") == 0
                        and hit_ref is not None
                        and hit_ref.get("file_kind") == "reference"
                        and (hit_ref.get("download_url") or "").startswith(("http://", "https://"))
                    )
                    print(
                        f"  [{'PASS' if list_ok else 'FAIL'}] 8.5c GET /projects/:id/files (contains ref + presign)"
                    )
                    state.RESULTS.append(
                        ("8.5c GET project files list has ref", list_ok, st_pf1, r_pf1.get("code", -1))
                    )

                    st_one, r_one = req(
                        "GET",
                        f"/api/v1/projects/{state.PROJECT_UUID}/files/{state.PROJECT_FILE_UUID_REF}",
                    )
                    one_ok = (
                        r_one.get("code") == 0
                        and isinstance(r_one.get("data"), dict)
                        and r_one["data"].get("uuid") == state.PROJECT_FILE_UUID_REF
                        and (r_one["data"].get("download_url") or "").startswith(
                            ("http://", "https://")
                        )
                    )
                    print(
                        f"  [{'PASS' if one_ok else 'FAIL'}] 8.5d GET /projects/:id/files/:uuid (detail)"
                    )
                    state.RESULTS.append(
                        ("8.5d GET project file detail", one_ok, st_one, r_one.get("code", -1))
                    )

                    st_fk, r_fk = req(
                        "GET",
                        f"/api/v1/projects/{state.PROJECT_UUID}/files?file_kind=reference&page=1&page_size=10",
                    )
                    fk_ok = False
                    if r_fk.get("code") == 0 and isinstance(r_fk.get("data"), list):
                        fk_ok = all(
                            (not isinstance(x, dict)) or x.get("file_kind") == "reference"
                            for x in r_fk["data"]
                        ) and any(
                            isinstance(x, dict) and x.get("uuid") == state.PROJECT_FILE_UUID_REF
                            for x in r_fk["data"]
                        )
                    print(
                        f"  [{'PASS' if fk_ok else 'FAIL'}] 8.5e GET /projects/:id/files?file_kind=reference"
                    )
                    state.RESULTS.append(
                        ("8.5e GET project files filter file_kind", fk_ok, st_fk, r_fk.get("code", -1))
                    )

                    prov_upload_ok = False
                    if state.TOKEN2:
                        fd_p2, tmp_p2 = tempfile.mkstemp(suffix=".txt", text=False)
                        try:
                            os.write(fd_p2, b"provider deliverable upload\n")
                            os.close(fd_p2)
                            http_u2, up2 = _curl_post_project_file(
                                state.PROJECT_UUID, state.TOKEN2, tmp_p2, "deliverable"
                            )
                            prov_upload_ok = up2.get("code") == 0 and http_u2 == 0
                            d2 = up2.get("data") if isinstance(up2.get("data"), dict) else {}
                            if prov_upload_ok and d2.get("file_kind") != "deliverable":
                                prov_upload_ok = False
                            print(
                                f"  [{'PASS' if prov_upload_ok else 'FAIL'}] 8.5f POST /projects/:id/files (provider deliverable)"
                            )
                            state.RESULTS.append(
                                (
                                    "8.5f POST project file provider",
                                    prov_upload_ok,
                                    200 if prov_upload_ok else 0,
                                    up2.get("code", -1),
                                )
                            )
                        finally:
                            try:
                                os.unlink(tmp_p2)
                            except OSError:
                                pass
                    else:
                        print("  [SKIP] 8.5f 无 TOKEN2，跳过服务方上传")

                    if state.MS_UUID:
                        fd_ms, tmp_ms = tempfile.mkstemp(suffix=".txt", text=False)
                        try:
                            os.write(fd_ms, b"milestone linked file\n")
                            os.close(fd_ms)
                            http_u3, up3 = _curl_post_project_file(
                                state.PROJECT_UUID, state.TOKEN, tmp_ms, "process", state.MS_UUID
                            )
                            ms_up_ok = up3.get("code") == 0 and http_u3 == 0
                            d3 = up3.get("data") if isinstance(up3.get("data"), dict) else {}
                            state.PROJECT_FILE_UUID_MS = d3.get("uuid")
                            if ms_up_ok and (
                                not state.PROJECT_FILE_UUID_MS
                                or d3.get("milestone_id") != state.MS_UUID
                            ):
                                ms_up_ok = False
                            print(
                                f"  [{'PASS' if ms_up_ok else 'FAIL'}] 8.5g POST /projects/:id/files (with milestone_id)"
                            )
                            state.RESULTS.append(
                                (
                                    "8.5g POST project file milestone",
                                    ms_up_ok,
                                    200 if ms_up_ok else 0,
                                    up3.get("code", -1),
                                )
                            )
                            if ms_up_ok and state.PROJECT_FILE_UUID_MS:
                                st_msf, r_msf = req(
                                    "GET",
                                    f"/api/v1/projects/{state.PROJECT_UUID}/files?milestone_id={state.MS_UUID}&page=1&page_size=10",
                                )
                                msf_ok = False
                                if r_msf.get("code") == 0 and isinstance(r_msf.get("data"), list):
                                    msf_ok = any(
                                        isinstance(x, dict)
                                        and x.get("uuid") == state.PROJECT_FILE_UUID_MS
                                        for x in r_msf["data"]
                                    )
                                print(
                                    f"  [{'PASS' if msf_ok else 'FAIL'}] 8.5g1 GET /files?milestone_id=..."
                                )
                                state.RESULTS.append(
                                    (
                                        "8.5g1 GET project files filter milestone",
                                        msf_ok,
                                        st_msf,
                                        r_msf.get("code", -1),
                                    )
                                )
                        finally:
                            try:
                                os.unlink(tmp_ms)
                            except OSError:
                                pass
                    else:
                        print("  [SKIP] 8.5g 无 MS_UUID，跳过里程碑关联上传")

                    http_bad, bad = _curl_post_project_file(
                        state.PROJECT_UUID, state.TOKEN, tmp_pf, "not_a_kind"
                    )
                    bad_kind_ok = bad.get("code") == 21016
                    print(
                        f"  [{'PASS' if bad_kind_ok else 'FAIL'}] 8.5h POST /files (invalid file_kind -> 21016)"
                    )
                    state.RESULTS.append(
                        (
                            "8.5h POST project file bad kind",
                            bad_kind_ok,
                            400 if bad_kind_ok else 200,
                            bad.get("code", -1),
                        )
                    )

                    fake_fid = str(uuid.uuid4())
                    test(
                        "8.5i GET /projects/:id/files/:uuid (not found -> 21015)",
                        "GET",
                        f"/api/v1/projects/{state.PROJECT_UUID}/files/{fake_fid}",
                        expect_code=21015,
                        expect_http=404,
                    )

                    if state.TOKEN_OUTSIDER:
                        test(
                            "8.5j GET /projects/:id/files (outsider -> 21008)",
                            "GET",
                            f"/api/v1/projects/{state.PROJECT_UUID}/files?page=1&page_size=5",
                            auth_token=state.TOKEN_OUTSIDER,
                            expect_code=21008,
                            expect_http=403,
                        )
                    else:
                        print("  [SKIP] 8.5j 无 TOKEN_OUTSIDER，跳过圈外人列表校验")
            finally:
                if fd_pf >= 0:
                    try:
                        os.close(fd_pf)
                    except OSError:
                        pass
                try:
                    os.unlink(tmp_pf)
                except OSError:
                    pass
