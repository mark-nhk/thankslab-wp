# -*- coding: utf-8 -*-
"""Secret loader dung chung cho cac tool Python.

Thu tu uu tien:  os.environ[NAME]  ->  .env (repo root)  ->  .secrets/<fallback_file>

Cho phep migrate secret sang co che .env ma hoa (xem secrets.md / tools/secrets.sh)
ma KHONG lam gay deploy.py / health_check.py: neu chua co .env thi van doc .secrets/ cu.
KHONG BAO GIO in gia tri secret ra stdout/log.
"""
import os

_env_cache = {}


def _dotenv(root):
    """Parse .env o repo root thanh dict (cache theo root). Bo qua dong trong / comment."""
    if root in _env_cache:
        return _env_cache[root]
    data = {}
    path = os.path.join(root, ".env")
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.rstrip("\n").rstrip("\r")
                s = line.strip()
                if not s or s.startswith("#") or "=" not in s:
                    continue
                k, v = s.split("=", 1)
                data[k.strip()] = v.strip()
    _env_cache[root] = data
    return data


def get(name, root, fallback_file=None):
    """Tra ve secret theo NAME. None neu khong tim thay o dau ca."""
    if os.environ.get(name):
        return os.environ[name].strip()
    val = _dotenv(root).get(name)
    if val:
        return val
    if fallback_file:
        p = os.path.join(root, ".secrets", fallback_file)
        if os.path.exists(p):
            return open(p, encoding="utf-8").read().strip()
    return None


def wp_auth(root):
    """Credential WP REST dang 'user:app-password'. WP_AUTH trong .env, fallback .secrets/wp.txt."""
    return get("WP_AUTH", root, "wp.txt")
