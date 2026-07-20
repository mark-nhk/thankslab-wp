# -*- coding: utf-8 -*-
"""Probe WP REST CHI-DOC (GET/OPTIONS) — chay truoc moi script ghi.

Usage:  python tools/wp_probe.py https://site.example [--cf7]

Doc WP_AUTH tu env / .env o repo root (qua _secrets_env.py cung thu muc).
Khong bao gio ghi gi len site. Khong in secret.
"""
import base64
import json
import os
import sys
import urllib.error
import urllib.request

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS_DIR)
sys.path.insert(0, TOOLS_DIR)
import _secrets_env  # noqa: E402

if len(sys.argv) < 2 or not sys.argv[1].startswith("http"):
    sys.exit("Usage: python tools/wp_probe.py https://site.example [--cf7]")
BASE = sys.argv[1].rstrip("/") + "/wp-json"
WANT_CF7 = "--cf7" in sys.argv

AUTH = _secrets_env.get("WP_AUTH", ROOT, "wp.txt")
HDR = {"User-Agent": "wp-probe/1.0"}
if AUTH:
    HDR["Authorization"] = "Basic " + base64.b64encode(AUTH.encode()).decode()
else:
    print("!! WP_AUTH khong tim thay (env/.env) — probe o che do KHONG auth\n")


def call(path, method="GET"):
    req = urllib.request.Request(BASE + path, headers=HDR, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, json.load(r)
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.load(e)
        except Exception:
            return e.code, str(e)
    except Exception as e:
        return 0, str(e)


print(f"=== {BASE} ===")
st, root = call("/")
if st != 200 or not isinstance(root, dict):
    sys.exit(f"Khong doc duoc index REST: HTTP {st} {root}")
routes = sorted(root.get("routes", {}))
ns = root.get("namespaces", [])
print(f"Site: {root.get('name')!r}  |  namespaces: {ns}\n")

print("=== ROUTE CO SAN (nhom chinh) ===")
groups = {
    "pages": "/wp/v2/pages", "posts": "/wp/v2/posts", "media": "/wp/v2/media",
    "users": "/wp/v2/users", "settings": "/wp/v2/settings",
    "plugins": "/wp/v2/plugins", "themes": "/wp/v2/themes",
    "menus": "/wp/v2/menus", "templates": "/wp/v2/templates",
    "cf7 forms": "/contact-form-7/v1/contact-forms",
}
for label, r in groups.items():
    print(f"  {label:12} {'CO' if r in routes else '-- khong co'}   {r}")

print("\n=== METHOD GHI DUOC (OPTIONS) ===")
for r in ("/wp/v2/pages", "/wp/v2/posts", "/wp/v2/media", "/wp/v2/users",
          "/wp/v2/plugins", "/wp/v2/settings"):
    if r not in routes:
        continue
    st, info = call(r, "OPTIONS")
    m = info.get("methods") if isinstance(info, dict) else info
    print(f"  {r:22} {m}")

print("\n=== QUYEN CUA APP PASSWORD ===")
st, me = call("/wp/v2/users/me?context=edit")
if st == 200 and isinstance(me, dict):
    print(f"  users/me OK: id={me.get('id')} slug={me.get('slug')} roles={me.get('roles')}")
else:
    print(f"  users/me -> HTTP {st}: {me if isinstance(me, str) else me.get('code')}")

print("\n=== USER ENUMERATION (khong auth) ===")
req = urllib.request.Request(BASE + "/wp/v2/users", headers={"User-Agent": "wp-probe/1.0"})
try:
    with urllib.request.urlopen(req, timeout=30) as r:
        pub = json.load(r)
    for u in pub:
        print(f"  LO CONG KHAI: id={u['id']} slug={u['slug']!r} name={u['name']!r}"
              "  <- slug = username that? => doi slug qua REST")
except urllib.error.HTTPError as e:
    print(f"  /wp/v2/users khong auth -> HTTP {e.code} (da bi chan — tot)")

if WANT_CF7:
    print("\n=== CF7 CONTRACT ===")
    st, forms = call("/contact-form-7/v1/contact-forms")
    if st != 200:
        print(f"  list forms -> HTTP {st}: {forms}")
    else:
        for f in forms:
            print(f"  form id={f.get('id')} slug={f.get('slug')!r} title={f.get('title')!r}")
        if forms:
            fid = forms[0]["id"]
            st, one = call(f"/contact-form-7/v1/contact-forms/{fid}")
            if st == 200 and isinstance(one, dict):
                props = one.get("properties", {})
                print(f"  form {fid} properties keys: {sorted(props.keys())}")
                print("  -> GET form nay + luu JSON backup TRUOC khi POST sua bat ky gi.")
