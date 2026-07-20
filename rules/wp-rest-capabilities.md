# WP REST API — làm được / KHÔNG làm được

Đúc kết đã **verify trên site thật** (WP 7.0.x, 07/2026) từ dự án fitrack-wp.
Auth: header `Authorization: Basic base64(user:app-password)`.

## Làm được qua REST core (`/wp-json/wp/v2/`)

| Việc | Endpoint | Ghi chú |
|---|---|---|
| CRUD page/post | `pages`, `posts` | đủ field: title, content, status, slug, template, meta |
| Upload media | `media` | POST binary, header `Content-Disposition: attachment; filename=...` |
| CRUD user | `users?context=edit` | đổi được email, roles, `slug` (nicename), display name |
| Settings | `settings` | title, tagline, timezone_string, page_on_front... |
| Plugin | `plugins` | **chỉ** cài (POST slug wp.org), bật/tắt (`status`), xóa (DELETE) |
| Theme | `themes` | chỉ đọc + đổi theme active qua settings/customize tùy theme |

## KHÔNG làm được qua REST core — đừng mất thời gian thử lại

1. **Update plugin/theme/core.** `/wp/v2/plugins/<slug>` chỉ nhận `context|plugin|status`.
   Không có endpoint update. Xóa-rồi-cài-lại KHÔNG phải update: DELETE chạy
   `uninstall.php` → **mất dữ liệu plugin** (CF7 mất form). Update luôn là việc user
   bấm trong wp-admin.
2. **Ghi file lên server.** Không có endpoint sửa functions.php, .htaccess, hay upload
   theme/plugin zip tùy ý. Theme/plugin ngoài wp.org → user upload zip qua Dashboard.
3. **Cài language pack.** `POST /wp/v2/settings {"language":"vi"}` trả **200 nhưng giá
   trị không đổi** nếu locale chưa cài — WP nhả im lặng, không báo lỗi. User cài qua
   wp-admin → Settings → General trước.
4. **Custom post type không `show_in_rest`** — không thấy trong `/wp/v2/`, phải tìm
   namespace riêng của plugin (vd CF7: `contact-form-7/v1` — xem cf7-rest.md).

## Quy trình probe chuẩn (chỉ đọc, chạy trước mọi script ghi)

```
GET  /wp-json/                      # danh sách routes + namespaces
OPTIONS <route>                     # methods + args schema thật
GET  <route>?context=edit           # xem quyền của app password tới đâu
```

`tools/wp_probe.py <base-url>` gói sẵn 3 bước trên. Lỗi hay gặp:
- `rest_no_route` → post type không expose, tìm namespace plugin.
- `rest_cannot_*` / 401 / 403 → app password thiếu quyền (thuộc user role nào?).
- 200 nhưng giá trị không đổi → validation im lặng (như language ở trên) — luôn GET
  lại để so, đừng tin status code.
