import sys
import os
import re
import time
import uuid
import random
import subprocess
import json
import shutil
import tempfile
from datetime import datetime

from . import state
from .helpers import (
    req,
    test,
    get_sms_code,
    gen_phone,
    cf,
    mysql_scalar,
    mysql_exec,
    encrypt_password_cipher,
    get_dchest_captcha_code,
    _CRYPTO_OK,
)


def run():
    print("=" * 60)
    print("  Kaizao API v2 Integration Tests")
    print(f"  Base: {state.BASE}  Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)

    # ==================== 1. 认证 ====================
    print("\n--- 1. 认证模块 ---")
    phone = gen_phone()
    print(f"  [INFO] Phone: {phone}")

    test("1.1 POST /auth/sms-code", "POST", "/api/v1/auth/sms-code",
         {"phone": phone, "purpose": 2}, need_auth=False)
    test("1.2 POST /auth/login (wrong code)", "POST", "/api/v1/auth/login",
         {"phone": phone, "code": "000000"}, need_auth=False, expect_code=10003)

    time.sleep(0.3)
    sms_code = get_sms_code(phone)
    if not sms_code:
        sms_code = "952786"
    print(f"  [INFO] Code: {sms_code}")

    ok, r = test("1.3 POST /auth/login (correct)", "POST", "/api/v1/auth/login",
                 {"phone": phone, "code": sms_code}, need_auth=False)
    state.LOGIN_PHONE = phone
    if ok and r.get("data"):
        state.TOKEN = r["data"].get("access_token")
        state.USER_ID = r["data"].get("user_id")
        state.REFRESH_TOKEN = r["data"].get("refresh_token")
        print(f"         user_id={state.USER_ID}")

    if not state.TOKEN:
        print("  [FATAL] No token, exit")
        sys.exit(1)

    if state.REFRESH_TOKEN:
        ok, r = test("1.4 POST /auth/refresh", "POST", "/api/v1/auth/refresh",
                     {"refresh_token": state.REFRESH_TOKEN}, need_auth=False)
        if ok and r.get("data"):
            state.TOKEN = r["data"].get("access_token", state.TOKEN)
            state.REFRESH_TOKEN = r["data"].get("refresh_token", state.REFRESH_TOKEN)

    # --- 1.4b 密码认证（api-registry.md：password-key / captcha / register-password / login-password）---
    print("\n--- 1.4b 密码认证（api-registry） ---")
    state.PW_FLOW_PASSWORD = "Abcd1234"
    state.USERNAME_PW_REG = None
    pem_pw = None

    ok_pk, r_pk = test(
        "1.4b1 GET /auth/password-key",
        "GET",
        "/api/v1/auth/password-key",
        need_auth=False,
    )
    if ok_pk and isinstance(r_pk.get("data"), dict):
        d_pk = r_pk["data"]
        cf_pk = cf(d_pk, ["key_id", "algorithm", "public_key_pem"], "password-key")
        pem_pw = d_pk.get("public_key_pem")
        algo_ok = str(d_pk.get("algorithm") or "") == "RSA-OAEP-SHA256"
        pk_meta = cf_pk and algo_ok
        print(
            f"  [{'PASS' if pk_meta else 'FAIL'}] 1.4b1a password-key fields + algorithm RSA-OAEP-SHA256"
        )
        state.RESULTS.append(("1.4b1a password-key meta", pk_meta, 200, 0 if pk_meta else -1))
    else:
        print("  [WARN] 1.4b1 无 data，后续依赖公钥的用例跳过")

    ok_cap0, r_cap0 = test(
        "1.4b2 GET /auth/captcha",
        "GET",
        "/api/v1/auth/captcha",
        need_auth=False,
    )
    if ok_cap0 and isinstance(r_cap0.get("data"), dict):
        d_cap = r_cap0["data"]
        cf_cap = cf(d_cap, ["captcha_id", "image_base64", "expires_in"], "captcha")
        print(
            f"  [{'PASS' if cf_cap else 'FAIL'}] 1.4b2a captcha response fields (captcha_id/image_base64/expires_in)"
        )
        state.RESULTS.append(("1.4b2a captcha fields", cf_cap, 200, 0 if cf_cap else -1))

    test(
        "1.4b3 POST /auth/register-password (forbidden root password field -> 10023)",
        "POST",
        "/api/v1/auth/register-password",
        {"username": "kz_bad1", "password": "Secret123"},
        need_auth=False,
        expect_code=10023,
        expect_http=400,
    )

    if _CRYPTO_OK and pem_pw:
        try:
            cipher_fmt = encrypt_password_cipher(pem_pw, state.PW_FLOW_PASSWORD)
        except Exception as ex:
            print(f"  [SKIP] 1.4b4–1.4b8 公钥加密失败: {ex}")
            cipher_fmt = None
    else:
        cipher_fmt = None
        print(
            "  [SKIP] 1.4b4–1.4b8 需 pip install cryptography 且 1.4b1 返回 public_key_pem"
        )

    if cipher_fmt:
        test(
            "1.4b4 POST /auth/register-password (invalid username -> 10020)",
            "POST",
            "/api/v1/auth/register-password",
            {"username": "bad!usr", "password_cipher": cipher_fmt},
            need_auth=False,
            expect_code=10020,
            expect_http=400,
        )

        state.USERNAME_PW_REG = f"kz_pw_{uuid.uuid4().hex[:12]}"
        ok_reg, r_reg = test(
            "1.4b5 POST /auth/register-password",
            "POST",
            "/api/v1/auth/register-password",
            {
                "username": state.USERNAME_PW_REG,
                "password_cipher": cipher_fmt,
                "nickname": "pw_reg",
            },
            need_auth=False,
        )
        if ok_reg and isinstance(r_reg.get("data"), dict) and r_reg["data"].get("access_token"):
            print(f"         register-password user={state.USERNAME_PW_REG!r}")

        if cipher_fmt:
            USERNAME_PW_REG_PHONE = f"kz_pw_{uuid.uuid4().hex[:12]}"
            phone_only = f"139{random.randint(10000000, 99999999)}"
            ok_reg_phone, _ = test(
                "1.4b5a POST /auth/register-password (phone only, no sms_code)",
                "POST",
                "/api/v1/auth/register-password",
                {
                    "username": USERNAME_PW_REG_PHONE,
                    "password_cipher": cipher_fmt,
                    "nickname": "pw_reg_phone",
                    "phone": phone_only,
                },
                need_auth=False,
            )
            if ok_reg_phone:
                print(f"         register-password+phone user={USERNAME_PW_REG_PHONE!r} phone={phone_only!r}")
            test(
                "1.4b5b POST /auth/register-password (sms_code without phone -> 99001)",
                "POST",
                "/api/v1/auth/register-password",
                {
                    "username": f"kz_pw_{uuid.uuid4().hex[:12]}",
                    "password_cipher": cipher_fmt,
                    "sms_code": "123456",
                },
                need_auth=False,
                expect_code=99001,
                expect_http=400,
            )

        if ok_reg:
            test(
                "1.4b8 POST /auth/register-password (duplicate username -> 10021)",
                "POST",
                "/api/v1/auth/register-password",
                {
                    "username": state.USERNAME_PW_REG,
                    "password_cipher": cipher_fmt,
                },
                need_auth=False,
                expect_code=10021,
                expect_http=400,
            )

        st_c2, r_c2 = req("GET", "/api/v1/auth/captcha", need_auth=False)
        cap_ok = st_c2 == 200 and r_c2.get("code") == 0
        cid_login = None
        if cap_ok and isinstance(r_c2.get("data"), dict):
            cid_login = r_c2["data"].get("captcha_id")
        cap_code = get_dchest_captcha_code(cid_login) if cid_login else None

        if state.USERNAME_PW_REG and cid_login and cap_code:
            ok_lp, r_lp = test(
                "1.4b6 POST /auth/login-password",
                "POST",
                "/api/v1/auth/login-password",
                {
                    "login_type": "username",
                    "identity": state.USERNAME_PW_REG,
                    "password_cipher": cipher_fmt,
                    "captcha_id": cid_login,
                    "captcha_code": cap_code,
                    "device_type": "web",
                },
                need_auth=False,
            )
            lp_data_ok = False
            if ok_lp and isinstance(r_lp.get("data"), dict):
                lp_data_ok = bool(r_lp["data"].get("access_token"))
            print(
                f"  [{'PASS' if lp_data_ok else 'FAIL'}] 1.4b6a login-password returns access_token"
            )
            state.RESULTS.append(("1.4b6a login-password token", lp_data_ok, 200, 0 if lp_data_ok else -1))

            st_c3, r_c3 = req("GET", "/api/v1/auth/captcha", need_auth=False)
            cid_bad = None
            if st_c3 == 200 and r_c3.get("code") == 0 and isinstance(r_c3.get("data"), dict):
                cid_bad = r_c3["data"].get("captcha_id")
            if cid_bad:
                test(
                    "1.4b7 POST /auth/login-password (wrong captcha -> 10026)",
                    "POST",
                    "/api/v1/auth/login-password",
                    {
                        "login_type": "username",
                        "identity": state.USERNAME_PW_REG,
                        "password_cipher": cipher_fmt,
                        "captcha_id": cid_bad,
                        "captcha_code": "0000000000000000",
                        "device_type": "web",
                    },
                    need_auth=False,
                    expect_code=10026,
                    expect_http=400,
                )
        else:
            print(
                "  [SKIP] 1.4b6–1.4b7 需 Docker 可读 Redis 验证码键 captcha:dchest:*（与 server 同一实例）"
            )

    # --- 1.5 管理端邀请码（docker 将当前用户提权为 role=9）---
    print("\n--- 1.5 管理端邀请码（可选） ---")
    if os.environ.get("KZ_SKIP_ADMIN_INVITE", "0") == "1":
        print("  [SKIP] KZ_SKIP_ADMIN_INVITE=1，跳过提权与 /admin/invite-codes")
    elif state.USER_ID and re.match(
        r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
        state.USER_ID,
        re.I,
    ):
        try:
            subprocess.run(
                [
                    "docker",
                    "exec",
                    state.MYSQL_CONTAINER,
                    "mysql",
                    "-u" + state.MYSQL_USER,
                    "-p" + state.MYSQL_PASSWORD,
                    state.MYSQL_DB,
                    "-e",
                    f"UPDATE users SET role=9 WHERE uuid='{state.USER_ID}'",
                ],
                check=True,
                timeout=30,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except Exception as ex:
            print(f"  [WARN] 无法通过 docker 提权管理员（跳过 1.5）: {ex}")
        else:
            ok, r = test(
                "1.5a POST /admin/invite-codes (batch create)",
                "POST",
                "/api/v1/admin/invite-codes",
                {
                    "count": 5,
                    "note": "integration-test",
                },
            )
            if ok and r.get("data"):
                codes = r["data"].get("codes", [])
                count = r["data"].get("count", 0)
                batch_ok = isinstance(codes, list) and count > 0
                print(f"  [{'PASS' if batch_ok else 'FAIL'}] 1.5a1 batch create returned {count} codes")
                state.RESULTS.append(("1.5a1 batch invite-codes count", batch_ok, 200, 0 if batch_ok else -1))
                if codes:
                    state.INVITE_CODE_PLAIN = codes[0]
                    print(f"         first invite_code={state.INVITE_CODE_PLAIN!r}")
            ok2, _ = test(
                "1.5b GET /admin/invite-codes",
                "GET",
                "/api/v1/admin/invite-codes?page=1&page_size=10",
            )
            state.ADMIN_SETUP_OK = bool(ok and ok2 and state.INVITE_CODE_PLAIN)
    else:
        print("  [WARN] USER_ID 非 UUID，跳过 1.5")

    # --- 1.6 新增接口（可选）：专家材料提交 + 团队静态文件（MinIO）---
    if state.TEST_NEW_APIS:
        print("\n--- 1.6 新增接口（--test-new-apis） ---")
        uuid_pat = re.compile(
            r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", re.I
        )
        if not (state.ADMIN_SETUP_OK and state.TOKEN and state.USER_ID and uuid_pat.match(state.USER_ID)):
            print("  [SKIP] 需 1.5 成功且 USER_ID 为 UUID")
            state.RESULTS.append(("1.6 prerequisites", False, 0, -1))
        else:
            mat_phone = gen_phone()
            test(
                "1.6a POST /auth/sms-code (register)",
                "POST",
                "/api/v1/auth/sms-code",
                {"phone": mat_phone, "purpose": 1},
                need_auth=False,
            )
            time.sleep(0.3)
            sc1 = get_sms_code(mat_phone, 1) or "952786"
            ok_mat, r_mat = test(
                "1.6b POST /auth/register (expert for materials)",
                "POST",
                "/api/v1/auth/register",
                {
                    "phone": mat_phone,
                    "sms_code": sc1,
                    "nickname": "MaterialExpert",
                    "role": 2,
                },
                need_auth=False,
            )
            d_mat = r_mat.get("data") if isinstance(r_mat, dict) else {}
            mat_tok = d_mat.get("access_token")
            mat_uuid = (d_mat.get("user") or {}).get("uuid") if isinstance(d_mat.get("user"), dict) else None
            if ok_mat and mat_tok and mat_uuid:
                test(
                    "1.6c POST /users/me/onboarding/application",
                    "POST",
                    "/api/v1/users/me/onboarding/application",
                    {"resume_url": "https://example.com/integration-cv.pdf", "note": "api test"},
                    auth_token=mat_tok,
                )
                test(
                    "1.6d PUT /admin/users/:uuid/onboarding (approve materials)",
                    "PUT",
                    f"/api/v1/admin/users/{mat_uuid}/onboarding",
                    {"status": "approved"},
                )
                st_m, r_m = req("GET", "/api/v1/users/me", None, True, mat_tok)
                ob_m = r_m.get("data", {}).get("onboarding_status") if isinstance(r_m, dict) else None
                ok_ob_m = ob_m == 2
                print(
                    f"  [{'PASS' if ok_ob_m else 'FAIL'}] 1.6e GET /users/me (materials path approved) onboarding={ob_m}"
                )
                state.RESULTS.append(
                    ("1.6e materials path onboarding=2", ok_ob_m, st_m, r_m.get("code", -1))
                )
            else:
                print("  [FAIL] 1.6b 专家注册失败，跳过材料审核子项")
                state.RESULTS.append(("1.6b expert register", False, 0, r_mat.get("code", -1)))

            try:
                subprocess.run(
                    [
                        "docker",
                        "exec",
                        state.MYSQL_CONTAINER,
                        "mysql",
                        "-u" + state.MYSQL_USER,
                        "-p" + state.MYSQL_PASSWORD,
                        state.MYSQL_DB,
                        "-e",
                        "INSERT IGNORE INTO team_members (team_id, user_id, role_in_team, split_ratio, status) "
                        "SELECT t.id, u.id, 'member', 0, 1 FROM teams t, users u "
                        f"WHERE t.uuid = '{state.SEED_TEAM_UUID}' AND u.uuid = '{state.USER_ID}'",
                    ],
                    check=True,
                    timeout=30,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            except Exception as ex:
                print(f"  [WARN] 无法写入 team_members（跳过 MinIO 测）: {ex}")
            else:
                if shutil.which("curl") is None:
                    print("  [SKIP] 未找到 curl，跳过 multipart 上传")
                    state.RESULTS.append(("1.6f POST static-assets (curl missing)", False, 0, -1))
                else:
                    fd, tmp_path = tempfile.mkstemp(suffix=".txt", text=False)
                    try:
                        os.write(fd, b"kaizao minio integration test\n")
                        os.close(fd)
                        cp = subprocess.run(
                            [
                                "curl",
                                "-sS",
                                "-X",
                                "POST",
                                state.BASE + f"/api/v1/teams/{state.SEED_TEAM_UUID}/static-assets",
                                "-H",
                                "Authorization: Bearer " + state.TOKEN,
                                "-F",
                                "purpose=integration",
                                "-F",
                                "file=@" + tmp_path + ";type=text/plain",
                            ],
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE,
                            timeout=120,
                            check=False,
                        )
                        try:
                            up_json = json.loads(cp.stdout.decode())
                        except Exception:
                            up_json = {"raw": cp.stdout.decode()[:200], "code": -1}
                        ok_up = up_json.get("code") == 0
                        print(
                            f"  [{'PASS' if ok_up else 'FAIL'}] 1.6f POST /teams/.../static-assets -> code={up_json.get('code')}"
                        )
                        state.RESULTS.append(
                            (
                                "1.6f POST /teams/:uuid/static-assets",
                                ok_up,
                                200 if ok_up else 0,
                                up_json.get("code", -1),
                            )
                        )
                        test(
                            "1.6g GET /teams/:uuid/static-assets",
                            "GET",
                            f"/api/v1/teams/{state.SEED_TEAM_UUID}/static-assets?page=1&page_size=10",
                        )
                    finally:
                        try:
                            os.unlink(tmp_path)
                        except OSError:
                            pass
