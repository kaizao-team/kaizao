"""11b. 通知模块（需 Docker MySQL 种子）"""

import re
import uuid

from . import state
from .helpers import req, test, cf, mysql_scalar, mysql_exec


def run():
    print("\n--- 11b. 通知模块 ---")
    state.NOTIF_UUID_A = None
    state.NOTIF_UUID_B = None
    if not state.TOKEN or not state.USER_ID:
        print("  [SKIP] 无 TOKEN/USER_ID")
    elif not re.match(
        r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
        state.USER_ID,
        re.I,
    ):
        print("  [SKIP] USER_ID 非 UUID")
    else:
        uid_row = mysql_scalar(f"SELECT id FROM users WHERE uuid='{state.USER_ID}' LIMIT 1")
        if not uid_row or not uid_row.isdigit():
            print("  [SKIP] 无法从 MySQL 解析当前用户 id（docker / 库不可用）")
        else:
            state.NOTIF_UUID_A = str(uuid.uuid4())
            state.NOTIF_UUID_B = str(uuid.uuid4())
            # 清理历史种子并插入两条未读（类型 1、2）
            mysql_exec(
                f"DELETE FROM notifications WHERE user_id={int(uid_row)} AND title LIKE 'KZ_TEST_%'"
            )
            esc = lambda s: s.replace("\\", "\\\\").replace("'", "''")
            ok_ins = mysql_exec(
                "INSERT INTO notifications (uuid, user_id, title, content, notification_type, is_read, is_pushed) VALUES "
                f"('{state.NOTIF_UUID_A}', {int(uid_row)}, '{esc('KZ_TEST_A')}', '{esc('body a')}', 1, 0, 0),"
                f"('{state.NOTIF_UUID_B}', {int(uid_row)}, '{esc('KZ_TEST_B')}', '{esc('body b')}', 2, 0, 0)"
            )
            if not ok_ins:
                print("  [SKIP] INSERT notifications 失败")
            else:
                st_uc, r_uc = req("GET", "/api/v1/notifications/unread-count")
                uc0 = (r_uc.get("data") or {}).get("unread_count")
                uc_ok = r_uc.get("code") == 0 and isinstance(uc0, int) and uc0 >= 2
                print(
                    f"  [{'PASS' if uc_ok else 'FAIL'}] 11b.1 GET /notifications/unread-count (seed>=2) -> unread_count={uc0!r}"
                )
                state.RESULTS.append(("11b.1 GET /notifications/unread-count", uc_ok, st_uc, r_uc.get("code", -1)))

                st_l, r_l = req("GET", "/api/v1/notifications?page=1&page_size=20")
                ok_l = r_l.get("code") == 0
                ids_a = {state.NOTIF_UUID_A, state.NOTIF_UUID_B}
                found = set()
                if ok_l and isinstance(r_l.get("data"), list):
                    for row in r_l["data"]:
                        if isinstance(row, dict) and row.get("uuid") in ids_a:
                            found.add(row["uuid"])
                sub_ok = ok_l and ids_a <= found
                meta = r_l.get("meta") if isinstance(r_l.get("meta"), dict) else {}
                page_ok = meta.get("page") == 1 and meta.get("page_size") == 20
                list_ok = sub_ok and page_ok
                print(
                    f"  [{'PASS' if list_ok else 'FAIL'}] 11b.2 GET /notifications (paged+seeds) "
                    f"-> HTTP {st_l}, code={r_l.get('code')}, meta.page={meta.get('page')}"
                )
                if ok_l and not sub_ok:
                    print(f"         FAIL: list missing seeded uuids, found={found}")
                state.RESULTS.append(("11b.2 GET /notifications paged+seeds", list_ok, st_l, r_l.get("code", -1)))

                st_t1, r_t1 = req("GET", "/api/v1/notifications?page=1&page_size=20&type=1")
                ok_t1 = r_t1.get("code") == 0
                type_ok = False
                if ok_t1 and isinstance(r_t1.get("data"), list):
                    rows = [row for row in r_t1["data"] if isinstance(row, dict)]
                    uuids_t1 = {row.get("uuid") for row in rows}
                    all_type1 = all(row.get("type") == 1 for row in rows)
                    type_ok = (
                        state.NOTIF_UUID_A in uuids_t1
                        and state.NOTIF_UUID_B not in uuids_t1
                        and all_type1
                    )
                print(
                    f"  [{'PASS' if type_ok else 'FAIL'}] 11b.3 GET /notifications?type=1 -> HTTP {st_t1}, code={r_t1.get('code')}"
                )
                if ok_t1 and not type_ok:
                    print("         FAIL: type=1 应含 A、不含 B，且条目 type 均为 1")
                state.RESULTS.append(("11b.3 GET /notifications?type=1", type_ok, st_t1, r_t1.get("code", -1)))

                test(
                    "11b.4 PUT /notifications/:uuid/read (A)",
                    "PUT",
                    f"/api/v1/notifications/{state.NOTIF_UUID_A}/read",
                    body=None,
                )
                _, r_uc2 = req("GET", "/api/v1/notifications/unread-count")
                uc1 = (r_uc2.get("data") or {}).get("unread_count")
                uc_dec = isinstance(uc0, int) and isinstance(uc1, int) and uc1 == uc0 - 1
                print(
                    f"  [{'PASS' if uc_dec else 'FAIL'}] 11b.5 unread after one read -> {uc0}->{uc1}"
                )
                state.RESULTS.append(("11b.5 unread_count after mark one read", uc_dec, 200, r_uc2.get("code", -1)))

                test("11b.6 PUT /notifications/read-all", "PUT", "/api/v1/notifications/read-all")
                _, r_uc3 = req("GET", "/api/v1/notifications/unread-count")
                uc2 = (r_uc3.get("data") or {}).get("unread_count")
                uc_zero = r_uc3.get("code") == 0 and uc2 == 0
                print(
                    f"  [{'PASS' if uc_zero else 'FAIL'}] 11b.7 unread after read-all -> {uc2!r}"
                )
                state.RESULTS.append(("11b.7 unread_count after read-all", uc_zero, 200, r_uc3.get("code", -1)))

                ok_idem, _ = test(
                    "11b.8 PUT /notifications/:uuid/read (idempotent)",
                    "PUT",
                    f"/api/v1/notifications/{state.NOTIF_UUID_A}/read",
                    body=None,
                )
                state.RESULTS.append(("11b.8 mark read idempotent", ok_idem, 200, 0))
