import json
import urllib.request
import urllib.error
import subprocess
import re
import hashlib
import time
import random
import uuid
import base64
import os
import shutil
import tempfile
import concurrent.futures

try:
    from cryptography.hazmat.backends import default_backend
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import padding

    _CRYPTO_OK = True
except ImportError:
    _CRYPTO_OK = False

from . import state


def req(method, path, body=None, need_auth=True, auth_token=None):
    url = state.BASE + path
    data = json.dumps(body).encode() if body else None
    headers = {"Content-Type": "application/json"}
    tok = state.TOKEN if auth_token is None else auth_token
    if need_auth and tok:
        headers["Authorization"] = "Bearer " + tok
    r = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        resp = urllib.request.urlopen(r)
        result = json.loads(resp.read().decode())
        return resp.status, result
    except urllib.error.HTTPError as e:
        body_text = e.read().decode()
        try:
            result = json.loads(body_text)
        except Exception:
            result = {"raw": body_text}
        return e.code, result


def test(
    name,
    method,
    path,
    body=None,
    need_auth=True,
    expect_code=0,
    auth_token=None,
    expect_http=None,
):
    """expect_http: 若指定则同时校验 HTTP 状态码（如里程碑创建：成功 200，业务错 400/403/404）。"""
    status, result = req(method, path, body, need_auth, auth_token)
    code = result.get("code", -1)
    ok = code == expect_code
    if expect_http is not None:
        ok = ok and (status == expect_http)
    icon = "PASS" if ok else "FAIL"
    print(f"  [{icon}] {name} -> HTTP {status}, code={code}")
    if not ok:
        msg = result.get("message", "")
        extra = f", expect_http={expect_http}" if expect_http is not None else ""
        print(f"         Expected code={expect_code}{extra}, got code={code}, HTTP={status}, msg={msg}")
    state.RESULTS.append((name, ok, status, code))
    return ok, result


def get_sms_code(phone, purpose=2):
    try:
        phone_hash = hashlib.sha256(phone.encode()).hexdigest()
        key = f"sms:code:{phone_hash}:{purpose}"
        result = subprocess.run(
            ["docker", "exec", state.REDIS_CONTAINER, "redis-cli", "-a", state.REDIS_PASSWORD, "get", key],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True, timeout=10)
        val = result.stdout.strip()
        if val and val != "(nil)":
            return val
    except Exception:
        pass
    return None


def gen_phone():
    return f"13{random.randint(100000000, 999999999)}"


def cf(data, fields, label=""):
    missing = [f for f in fields if f not in data]
    if missing:
        print(f"         WARN[{label}]: missing {missing}")
    return len(missing) == 0


def mysql_scalar(sql):
    """docker exec MySQL 执行查询，返回首行首列（无则 None）。失败返回 None。"""
    try:
        result = subprocess.run(
            [
                "docker",
                "exec",
                state.MYSQL_CONTAINER,
                "mysql",
                "-u" + state.MYSQL_USER,
                "-p" + state.MYSQL_PASSWORD,
                state.MYSQL_DB,
                "-N",
                "-e",
                sql,
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
            timeout=30,
            check=True,
        )
        out = result.stdout.strip()
        if not out:
            return None
        return out.split("\n")[0].strip()
    except Exception:
        return None


def mysql_exec(sql):
    """docker exec MySQL 执行非查询语句。成功返回 True。"""
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
                sql,
            ],
            check=True,
            timeout=30,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return True
    except Exception:
        return False


def encrypt_password_cipher(pem: str, password: str) -> str:
    """RSA-OAEP-SHA256，与 api-registry.md / smoke_password_auth.py 一致。"""
    if not _CRYPTO_OK:
        raise RuntimeError("cryptography not installed")
    pub = serialization.load_pem_public_key(pem.encode("utf-8"), backend=default_backend())
    ct = pub.encrypt(
        password.encode("utf-8"),
        padding.OAEP(
            mgf=padding.MGF1(algorithm=hashes.SHA256()),
            algorithm=hashes.SHA256(),
            label=None,
        ),
    )
    return base64.b64encode(ct).decode("ascii")


def get_dchest_captcha_code(captcha_id):
    """从 Redis 键 captcha:dchest:{id} 解析 dchest 验证码答案（每位 0–9 数值字节）。"""
    if not captcha_id:
        return None
    key = f"captcha:dchest:{captcha_id}"
    try:
        result = subprocess.run(
            [
                "docker",
                "exec",
                state.REDIS_CONTAINER,
                "redis-cli",
                "-a",
                state.REDIS_PASSWORD,
                "--raw",
                "GET",
                key,
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=False,
            timeout=15,
        )
        raw = result.stdout
        if not raw:
            return None
        raw = raw.rstrip(b"\r\n")
        if raw == b"(nil)" or not raw:
            return None
        return "".join(str(b) for b in raw)
    except Exception:
        return None
