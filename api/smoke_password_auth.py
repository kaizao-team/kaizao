#!/usr/bin/env python3
"""
对照 api/api-registry.md：密码注册 + 密码登录（用户名）冒烟测试。

依赖：cryptography（RSA-OAEP-SHA256）、redis（经本机端口读验证码答案，与 server 共用同一 Redis）。

用法（WSL，栈已起、8080/6379 已映射）：
  pip install cryptography redis
  python3 smoke_password_auth.py
  python3 smoke_password_auth.py --base http://127.0.0.1:8080 --redis-host 127.0.0.1 --redis-port 6379
"""
from __future__ import annotations

import argparse
import json
import random
import string
import sys
import urllib.error
import urllib.request

try:
    from cryptography.hazmat.backends import default_backend
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import padding
except ImportError:
    print("请先安装: pip install cryptography", file=sys.stderr)
    sys.exit(2)

try:
    import redis
except ImportError:
    redis = None  # type: ignore


def req_json(method: str, base: str, path: str, body: dict | None = None) -> tuple[int, dict]:
    url = base.rstrip("/") + path
    data = json.dumps(body).encode("utf-8") if body is not None else None
    r = urllib.request.Request(url, data=data, method=method)
    r.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(r, timeout=60) as resp:
            raw = resp.read().decode("utf-8")
            payload = json.loads(raw) if raw else {}
            return resp.status, payload
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", errors="replace")
        try:
            payload = json.loads(raw) if raw else {}
        except json.JSONDecodeError:
            payload = {"_raw": raw}
        return e.code, payload


def encrypt_password_cipher(pem: str, password: str) -> str:
    pub = serialization.load_pem_public_key(pem.encode("utf-8"), backend=default_backend())
    ct = pub.encrypt(
        password.encode("utf-8"),
        padding.OAEP(
            mgf=padding.MGF1(algorithm=hashes.SHA256()),
            algorithm=hashes.SHA256(),
            label=None,
        ),
    )
    import base64

    return base64.b64encode(ct).decode("ascii")


def redis_captcha_answer(host: str, port: int, password: str, captcha_id: str) -> str:
    """从 captcha:dchest:{id} 取答案。

    dchest/captcha 的 RandomDigits 存的是「每位 0–9 的数值字节」，不是 ASCII 数字字符；
    VerifyString 接收的则是用户输入的十进制数字串（如 \"384521\"）。须先转成数字串再 POST。
    """
    if redis is None:
        raise RuntimeError("请安装: pip install redis")
    key = f"captcha:dchest:{captcha_id}"
    r = redis.Redis(host=host, port=port, password=password, decode_responses=False)
    raw = r.get(key)
    if not raw:
        raise RuntimeError(f"Redis 无验证码键: {key}（确认本机可连 {host}:{port} 且与 server 同一实例）")
    # raw: bytes, each byte value 0..9
    return "".join(str(b) for b in raw)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="http://127.0.0.1:8080", help="API 根，如 http://127.0.0.1:8080")
    ap.add_argument("--redis-host", default="127.0.0.1", help="与 server 相同的 Redis（compose 映射到宿主机）")
    ap.add_argument("--redis-port", type=int, default=6379)
    ap.add_argument("--redis-password", default="redis123")
    ap.add_argument("--password", default="Abcd1234", help="满足强度：8+ 且含字母与数字")
    args = ap.parse_args()
    base = args.base

    suffix = "".join(random.choices(string.ascii_lowercase + string.digits, k=8))
    username = f"kz_{suffix}"

    # 1) password-key
    st, j = req_json("GET", base, "/api/v1/auth/password-key")
    if st != 200 or j.get("code") != 0:
        print("FAIL password-key", st, j)
        return 1
    data = j.get("data") or {}
    pem = data.get("public_key_pem")
    if not pem:
        print("FAIL no public_key_pem", j)
        return 1
    cipher = encrypt_password_cipher(pem, args.password)

    # 2) register：需 captcha 吗？register-password 不需要 captcha，直接注册
    st, j = req_json(
        "POST",
        base,
        "/api/v1/auth/register-password",
        {"username": username, "password_cipher": cipher, "nickname": "冒烟用户"},
    )
    if st != 200 or j.get("code") != 0:
        print("FAIL register-password", st, j)
        return 1
    reg = j.get("data") or {}
    if not reg.get("access_token"):
        print("FAIL no access_token in register response", j)
        return 1
    print("OK register-password", "user", (reg.get("user") or {}).get("uuid", "?"))

    # 3) login-password：需要 captcha
    st, j = req_json("GET", base, "/api/v1/auth/captcha")
    if st != 200 or j.get("code") != 0:
        print("FAIL captcha", st, j)
        return 1
    cdata = j.get("data") or {}
    cid = cdata.get("captcha_id")
    if not cid:
        print("FAIL no captcha_id", j)
        return 1

    try:
        code = redis_captcha_answer(
            args.redis_host, args.redis_port, args.redis_password, cid
        )
    except Exception as e:
        print("FAIL read captcha answer:", e)
        print("提示: pip install redis；确保本机可访问 Redis（compose 已映射 6379）")
        return 1

    cipher2 = encrypt_password_cipher(pem, args.password)
    st, j = req_json(
        "POST",
        base,
        "/api/v1/auth/login-password",
        {
            "login_type": "username",
            "identity": username,
            "password_cipher": cipher2,
            "captcha_id": cid,
            "captcha_code": code,
            "device_type": "android",
        },
    )
    if st != 200 or j.get("code") != 0:
        print("FAIL login-password", st, j)
        return 1
    d = j.get("data") or {}
    if not d.get("access_token"):
        print("FAIL login no access_token", j)
        return 1
    print("OK login-password", "user_id", d.get("user_id"))
    print("ALL OK — api-registry 密码注册/登录链路正常")
    return 0


if __name__ == "__main__":
    sys.exit(main())
