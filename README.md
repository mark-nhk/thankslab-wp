# extract/ — bộ rule / skill / memory dùng lại cho project WP mới

Trích từ dự án fitrack-wp (07/2026). Chỉ chứa những gì **đã kiểm chứng trên site thật**
và **không phụ thuộc FitTrack** (không Flatsome, không mockup pipeline, không deploy.py).
Sau khi tách ra, 2 project phát triển độc lập — không sync ngược.

## Cấu trúc

```
CLAUDE.template.md      → đổi tên thành CLAUDE.md ở repo mới, điền chỗ trống
rules/
  wp-rest-capabilities.md   REST làm được / KHÔNG làm được (đã verify)
  cf7-rest.md               Contact Form 7 qua REST — trọng tâm cho site mới
  content-gotchas.md        texturize &&, wpautop, tab Visual... (khi đụng page content)
  security-baseline.md      user enumeration, app password, Flamingo caps
  agent-env-windows.md      bẫy môi trường Claude Code trên Windows
tools/
  _secrets_env.py           secret loader (env -> .env -> .secrets/) — copy nguyên
  secrets.sh                .env <-> .env.enc (AES-256, keystore per-device) — copy nguyên
  wp_probe.py               probe REST chỉ-đọc: routes, methods, CF7 contract
memory/
  *.md                      seed cho auto-memory của project mới
```

## Bootstrap project mới (thứ tự)

1. Repo mới + git init. Copy `CLAUDE.template.md` → `CLAUDE.md`, copy `rules/` + `tools/`.
2. `.gitignore`: thêm `.env` và `.secrets/` ngay từ commit đầu.
3. User tạo **Application Password** trong wp-admin (Users → Profile) — KHÔNG dùng
   password đăng nhập thật. Ghi vào `.env` ở repo root:
   `WP_AUTH=tenuser:xxxx xxxx xxxx xxxx xxxx xxxx`
4. Mã hóa: `bash tools/secrets.sh setup` (chạy bằng **Git Bash thật**, không phải WSL —
   xem rules/agent-env-windows.md) rồi `bash tools/secrets.sh encrypt`. Commit `.env.enc`.
5. Chạy `python tools/wp_probe.py https://site-moi.example` — chỉ đọc, an toàn tuyệt đối.
   Kết quả cho biết: quyền của app password tới đâu, CF7 version + contract, route nào mở.
6. Từ kết quả probe mới quyết định làm gì tiếp. **Không viết script ghi khi chưa probe.**
7. Seed memory: bảo agent ở project mới đọc `memory/` trong folder này và lưu lại
   (đường dẫn memory là per-project, agent tự biết chỗ).

## Những gì CỐ TÌNH không mang theo

- Toàn bộ pipeline mockup→WP (convert_*.py, deploy.py, audit_pixel.py, neutralizer) —
  đặc thù Flatsome + trang landing dán `wp:html` của FitTrack.
- health_check.py — baseline (plugin bắt buộc, page id, marker `__ftlpOK`) là của FitTrack.
  Pattern thì giữ: xem CLAUDE.template.md mục "health check".
- staging.py — dùng được nếu site mới cần dev theme, nhưng site mới bắt đầu bằng CF7
  qua REST nên chưa cần; lấy sau từ repo fitrack-wp nếu phát sinh.
- AGENTS.md / WORKFLOW.md / PLAN.md — bối cảnh và kế hoạch riêng của FitTrack.
