# NOTES — thankslab.com.vn

> Nhật ký công việc + trạng thái. Cập nhật gần nhất: **2026-07-20**.
> ⚠️ **Giữ repo này PRIVATE** — chứa phát hiện bảo mật, email nội bộ, và `.env.enc`.

## 1. Site & truy cập

- **URL production:** https://thankslab.com.vn/ — tên site "THANKSLAB VIETNAM".
- **Stack:** WordPress **7.0.2** (đã update từ 6.4.8 ngày 2026-07-20), PHP **8.3.31**, server **LiteSpeed**, theme **Flatsome Child v3.0** (parent Flatsome). Có **Plesk WP Toolkit** (nhưng chỉ phần Patchstack trong wp-admin).
- **Quyền của ta:** chỉ **wp-admin + REST** (không FTP/SSH; nhiều khả năng không có Plesk panel → không dùng được Clone/Backup của Plesk).
- **Credential REST:** `WP_AUTH` trong `.env` (mã hóa ở `.env.enc`, giải mã: `bash tools/secrets.sh decrypt`). App password thuộc user **id=6** (`khoi.wappuri@gmail.com`, administrator). `.env` chỉ có 2 key: `WP_URL`, `WP_AUTH`.
- ⚠️ **`thankslab.biz` là site KHÁC, không liên quan** (công ty Nhật). Đừng suy URL từ domain email.

## 2. Đã làm hôm nay (2026-07-20) — tất cả qua REST, có backup ở `backups/`

| Việc | Chi tiết |
|---|---|
| Dọn quyền admin | 5 admin → **2 admin**. `xhs`(id5, vendor) → Editor; `wordfen1`(id4) → Subscriber; `admin`(id1, onese) → Editor. Giữ id=2 Linh & id=6 (ta). |
| admin_email site | `tung.nguyen@onese.vn` (vendor) → **`system-vn@thankslab.biz`** |
| Chống user enumeration | Đổi public slug id 1/2/6 (≠ username), login không đổi |
| Comment/pingback | `default_comment_status` & `default_ping_status` → **closed** |
| Lead CF7 | Bật lại plugin **Advanced CF7 DB** (CF7 core không lưu, chỉ mail tới Linh) — sau đó quyết **chuyển sang Flamingo** |
| Backup tool | Cài **UpdraftPlus** (Settings → UpdraftPlus → Backup Now; có nút Restore) |
| Repo | Thêm `.gitignore` (che `.env`, `.secrets/`, `backups/`) |

## 3. Phát hiện bảo mật

- **`wordfen1` (id=4) = account TRỐNG từng có quyền Admin** (tạo **2025-02-05**, không bài, không app-pw, không comment) → **hình mẫu backdoor**. Tên nhái *Wordfence* + email throwaway `xcxz3@gmail.com`. ⇒ site nhiều khả năng **từng bị xâm nhập** quanh 02/2025 qua lỗ hổng phần mềm cũ. Đang giữ Subscriber; **xóa nếu không ai nhận** (xóa sạch, không có bài để reassign — đã xác nhận trong wp-admin).
- CF7 (form 17 "Form đặt mua hàng") **không lưu lead**, chỉ mail tới `do.thi.ngoc.linh@thankslab-vn.biz`.
- **xmlrpc.php mở** (pingback + multicall). **readme.html lộ version**. Meta generator lộ WP 6.4.8. **49 comment** (nghi spam). Nhiều plugin cũ.
- 3 CPT `doi_tac`/`nhan_su`/`tuyen_dung` đăng ký **không support `author`** → REST không đọc/lọc được post_author (đừng tin `?author=N` trên các CPT này — nó trả về tất cả).
- Điểm tốt: PHP 8.3, HTTPS/HSTS, security headers ổn; endpoint backup/migration (ai1wm không có ở site này) — chỉ có wp-toolkit/litespeed/yoast/wpforms/cf7 namespaces.

## 4. Trạng thái user hiện tại

| id | username/login | email | role |
|---|---|---|---|
| 1 | `admin` | tung.nguyen@onese.vn (vendor) | Editor |
| 2 | do.thi.ngoc.linh@thankslab-vn.biz | (Linh) | **Administrator** |
| 4 | `wordfen1` | xcxz3@gmail.com | Subscriber (nghi backdoor) |
| 5 | `xhs` | tranphamsontung@gmail.com (vendor) | Editor |
| 6 | khoi.wappuri@gmail.com | (ta) | **Administrator** |

## 5. ĐANG CHỜ — kế hoạch mai

### ✅ Đã xong 2026-07-20
- Git initial commit + push (remote `git@github.com:mark-nhk/thankslab-wp.git`) — user tự chạy vì classifier chặn `git commit`.
- **Update core → 7.0.2** + toàn bộ plugin (verify OK: CF7 6.1.6, CPT UI 1.19.3, Really Simple Security 9.6.1, Yoast 28.0, ACF 6.8.6, LiteSpeed 7.8.1...). Site HTTP 200, không PHP error, REST auth chạy. Advanced CF7 DB user tự update lên **2.1.2**.

### Việc user tự làm (wp-admin, REST không làm được)
1. **Đổi mật khẩu** các admin thật (id 2, 6).
2. **Quét malware bằng Imunify Security**; cân nhắc bật **Patchstack "Enable Protection"** (vá ảo).
3. **Tắt xmlrpc** (WPCode snippet `xmlrpc_enabled __return_false` + gỡ pingback methods, hoặc chặn xmlrpc.php ở .htaccess).
4. **Chặn readme.html** (vẫn truy cập được); dọn **~49 comment spam**.
5. Cân nhắc đổi username `admin` (id=1) & xóa `wordfen1` nếu không ai nhận.

### Việc agent làm qua REST (chờ user quyết)
- **Lead:** Advanced CF7 DB giờ đã là bản mới nhất (2.1.2) → **hỏi lại**: vẫn thay Flamingo hay giữ luôn cái này? Nếu thay: cài Flamingo + tắt Advanced CF7 DB.
- Tùy chọn: gỡ 5 plugin inactive (backup trước; SeedProd có thể chứa page).

## 6. Backups đã tạo (local, gitignored — `backups/`)

- `pre-change-*` (role xhs/wordfen1 + comment/ping)
- `slug-change-*` (slug id 1/2/6)
- `demote-admin1-*` (id1 → editor)
- `activate-cf7db-*`, `install-updraft-*`, `admin-email-*`

## 7. Quy tắc làm việc (nhắc nhanh)

- GET/OPTIONS tự do; mọi thao tác GHI production phải báo + được duyệt (lệnh trực tiếp = duyệt).
- Trước khi ghi: GET backup vào `backups/`; sau khi ghi: GET verify; script có auto-rollback.
- Không dùng plugin "Disable REST API".
- Đọc `rules/` trước khi đụng REST/CF7/page content. Không paste secret ra chat/log/CLI.
