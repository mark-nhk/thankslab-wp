# NOTES — thankslab.com.vn

> Nhật ký công việc + trạng thái. Cập nhật gần nhất: **2026-07-21**.
> ⚠️ **Giữ repo này PRIVATE** — chứa phát hiện bảo mật, email nội bộ, và `.env.enc`.

## 1. Site & truy cập

- **URL production:** https://thankslab.com.vn/ — tên site "THANKSLAB VIETNAM".
- **Stack:** WordPress **7.0.2** (đã update từ 6.4.8 ngày 2026-07-20), PHP **8.3.31**, server **LiteSpeed**, theme **Flatsome Child v3.0** (parent Flatsome). Có **Plesk WP Toolkit** (nhưng chỉ phần Patchstack trong wp-admin).
- **Quyền của ta:** chỉ **wp-admin + REST** (không FTP/SSH; nhiều khả năng không có Plesk panel → không dùng được Clone/Backup của Plesk).
- **Credential REST:** `WP_AUTH` trong `.env` (mã hóa ở `.env.enc`, giải mã: `bash tools/secrets.sh decrypt`). App password thuộc user **id=6** (`khoi.wappuri@gmail.com`, administrator). `.env` có 3 key: `WP_URL`, `WP_AUTH`, **`BREVO_KEY`** (API key Brevo của site này, thêm 21/07 — dùng check log gửi mail: `GET https://api.brevo.com/v3/smtp/statistics/events?email=<addr>` header `api-key`; lưu ý tên key là `BREVO_KEY`, không phải `BREVO_API_KEY` như fitrack).
- ⚠️ **`thankslab.biz` là site KHÁC, không liên quan** (công ty Nhật). Đừng suy URL từ domain email.

## 2. Đã làm 2026-07-20 — tất cả qua REST, có backup ở `backups/`

| Việc | Chi tiết |
|---|---|
| Dọn quyền admin | 5 admin → **2 admin**. `xhs`(id5, vendor) → Editor; `wordfen1`(id4) → Subscriber; `admin`(id1, onese) → Editor. Giữ id=2 Linh & id=6 (ta). |
| admin_email site | `tung.nguyen@onese.vn` (vendor) → **`system-vn@thankslab.biz`** |
| Chống user enumeration | Đổi public slug id 1/2/6 (≠ username), login không đổi |
| Comment/pingback | `default_comment_status` & `default_ping_status` → **closed** |
| Lead CF7 | Bật lại plugin **Advanced CF7 DB** (CF7 core không lưu, chỉ mail tới Linh) — sau đó quyết **chuyển sang Flamingo** |
| Backup tool | Cài **UpdraftPlus** (Settings → UpdraftPlus → Backup Now; có nút Restore) |
| Repo | Thêm `.gitignore` (che `.env`, `.secrets/`, `backups/`) |

## 2b. Đã làm 2026-07-21 — tất cả qua REST, backup ở `backups/`

| Việc | Chi tiết |
|---|---|
| **FIX Contact Form** | Form 17 chết vì `wp_mail` fail → truy ra **config WP Mail SMTP hỏng** (bật = `mail_failed`, tắt = `mail_sent`). Đã **tắt `wp-mail-smtp`** → form sống lại qua PHP mail(). User cần sửa config SMTP rồi mới bật lại (tab Email Test của plugin sẽ hiện lỗi cụ thể). |
| Lead capture | Cài **Flamingo 2.6.3** (active) — lưu mọi submission vào DB kể cả khi mail fail (menu **Flamingo → Inbound Messages**, chỉ Administrator đọc được). Advanced CF7 DB: tắt → user check lead kẹt 20–21/07 trong wp-admin → **xóa hẳn** cùng ngày. |
| Comment spam | Trash **50/50** (49 hold + 1 spam), backup JSON đầy đủ. Count giờ = 0. |
| Xóa `wordfen1` | **User id=4 đã xóa hẳn** (force, reassign=6), verify 404. Còn 4 user. |
| Gỡ plugin không dùng | Sáng: xóa **SeedProd, Nextend Social Login, OptinMonster, RafflePress** (scan content 0 tham chiếu). MonsterInsights REST DELETE 500 ×3 → **user xóa trong wp-admin OK**. Chiều (audit 17 active): xóa thêm **WPForms Lite** (0 form, wizard chưa chạy) + **Popup Builder** (0 popup render, dòng plugin nhiều CVE) — deactivate → verify sạch → DELETE. Còn **16 plugin**. |
| Display name | User đã tự sửa trong wp-admin; verify public = `OneSe`/`Linh`/`Mark` — hết lộ email/`admin`. |

**Phát hiện kèm theo (2026-07-21):**
- **CF7 6.1.x REST từ chối GHI form một cách im lặng** (POST tạo/sửa trả 200 + object nhưng không persist, id=null) — đã thử CẢ HAI contract: form-encoded `mail[...]` VÀ JSON `{"properties":{"mail":{...}}}` (21/07 chiều) — đều không ăn. Đọc/xóa vẫn OK. **Sửa form = wp-admin, khỏi thử REST nữa.** Endpoint `/feedback` đòi `multipart/form-data` (urlencoded → HTTP 415).
- LiteSpeed **Delay JS** đang bật: JS (kể cả CF7) chỉ chạy sau tương tác đầu tiên của khách — form vẫn hoạt động vì LiteSpeed re-dispatch DOMContentLoaded, nhưng cần nhớ khi debug "JS không chạy".
- Bundle delay JS còn load **jQuery 3.5.1 đè lên 3.7.1** (theme/builder nhúng bản cũ) — chưa gây lỗi thấy được, ghi nhận thôi.
- Validation tel của CF7 6.x chặn số giả dạng `0000000000` nhưng số VN thật pass — không phải bug.
- DNS `thankslab.com.vn`: **không có MX, không có SPF/TXT** → mail từ PHP mail() dễ vào spam. Nên thêm SPF (hoặc dùng SMTP xịn) khi sửa WP Mail SMTP.

## 3. Phát hiện bảo mật

- **`wordfen1` (id=4) = account TRỐNG từng có quyền Admin** (tạo **2025-02-05**, không bài, không app-pw, không comment) → **hình mẫu backdoor**. Tên nhái *Wordfence* + email throwaway `xcxz3@gmail.com`. ⇒ site nhiều khả năng **từng bị xâm nhập** quanh 02/2025 qua lỗ hổng phần mềm cũ. → **ĐÃ XÓA 2026-07-21** (vẫn nên quét Imunify + đổi mật khẩu admin để chắc không còn tàn dư).
- CF7 (form 17 "Form đặt mua hàng" — nhúng ở trang chủ page id=99) mail tới `do.thi.ngoc.linh@thankslab-vn.biz`, CC `tungtps@xhs.vn`. → Từ 2026-07-21 lead lưu thêm vào **Flamingo**.
- **xmlrpc.php mở** (pingback + multicall — CÒN). **readme.html lộ version** (CÒN). ~~49 comment spam~~ (đã dọn 21/07). ~~Nhiều plugin cũ~~ (đã update + gỡ 7 plugin không dùng).
- 3 CPT `doi_tac`/`nhan_su`/`tuyen_dung` đăng ký **không support `author`** → REST không đọc/lọc được post_author (đừng tin `?author=N` trên các CPT này — nó trả về tất cả).
- Điểm tốt: PHP 8.3, HTTPS/HSTS, security headers ổn; endpoint backup/migration (ai1wm không có ở site này) — chỉ có wp-toolkit/litespeed/yoast/wpforms/cf7 namespaces.

## 4. Trạng thái user hiện tại (sau 2026-07-21)

| id | username/login | email | role |
|---|---|---|---|
| 1 | `admin` | tung.nguyen@onese.vn (vendor) | Editor |
| 2 | do.thi.ngoc.linh@thankslab-vn.biz | (Linh) | **Administrator** |
| 5 | `xhs` | tranphamsontung@gmail.com (vendor) | Editor |
| 6 | khoi.wappuri@gmail.com | (ta) | **Administrator** |

(`wordfen1` id=4 — account nghi backdoor — **đã xóa 2026-07-21**, backup ở `backups/cleanup-*/user-4-wordfen1.json`.)

## 5. ĐANG CHỜ

### ✅ Đã xong (chi tiết ở §2, §2b)
- **2026-07-20:** git init + push (remote `git@github.com:mark-nhk/thankslab-wp.git`); update core →7.0.2 + toàn bộ plugin, verify OK.
- **2026-07-21:** fix Contact Form (tắt wp-mail-smtp hỏng config); Flamingo thay Advanced CF7 DB (ACF7DB đã xóa hẳn sau khi user check lead); trash 50 comment spam; xóa `wordfen1`; gỡ 7 plugin không dùng (SeedProd, Nextend, OptinMonster, RafflePress, MonsterInsights*, WPForms Lite, Popup Builder — *user xóa tay vì REST 500); display name public sạch. Site còn **16 plugin**, 4 user.

### ✅ SMTP Brevo — HOÀN THÀNH TRỌN GÓI 21/07 (giữ làm hồ sơ)
1. ~~Tạo Brevo + API key~~ → **ĐÃ XONG** (21/07 tối: sender + API key đã tạo).
2. ~~Vendor thêm DNS record~~ → **XONG 21/07**: vendor đã thêm đủ **8 record** (gồm cả SPF `include:spf.brevo.com ~all` theo template fit-track — Brevo flow mới không đòi SPF nhưng thêm vô hại; file gửi vendor: `D:\W\dns-brevo-thankslab.csv`). Verify 21/07 qua 8.8.8.8 + 1.1.1.1: **cả 8 đúng từng byte**. → User bấm **Verify** trong Brevo → Domains.
3. ~~Kích hoạt + config WP Mail SMTP~~ → **XONG 21/07**: domain Authenticated trong Brevo (branding `em/img.em/r.em` chờ checker xanh — cosmetic); sender **`no-reply@thankslab.com.vn`** Verified (DKIM ✅ DMARC ✅); WP Mail SMTP active, mailer Brevo, Sending Domain `thankslab.com.vn`, Email Test OK.
4. ~~Verify trọn gói~~ → **XONG 21/07**: E2E qua browser (đường khách thật: delay-JS → AJAX → CF7 → Brevo) = **"sent" thành công**. Toàn bộ 16 plugin active, 0 inactive.

### ✅ Audit form 17 — ĐÓNG (21/07 tối)
1. ~~BUG mail body thiếu `[diachi]`~~ → **user đã sửa trong wp-admin**, verify qua REST: body đủ 3 trường + footer đúng ngữ cảnh.
2. Đồng thời user revamp mail config: **recipient → `info-vn@thankslab.biz`**, **CC → Linh** (bỏ hẳn vendor `tungtps@xhs.vn`), subject → "Liên hệ về Thankslab Vietnam", From → `no-reply@thankslab.com.vn` (khớp sender Brevo).
3. **E2E nghiệm thu cuối 21/07: "sent" thành công** với config mới. Toàn tuyến chốt: form → CF7 → WP Mail SMTP (Brevo API) → info-vn@thankslab.biz + CC Linh; lead lưu Flamingo.
4. Còn lại (không gấp): dọn entry TEST trong Flamingo + mail TEST trong các inbox; `mail_2` off là đúng (form không thu email khách).

### Việc user — còn lại (đầu phiên sau)
1. **Check Settings → 301 Redirects**: trống → báo agent gỡ plugin Simple 301 Redirects; có rules → giữ (REST không đọc được rules).
2. **Check 2 mã GA song song** (`G-0PBTPYTV2B`, `G-N5T07F6SGD` — trong Insert Headers & Footers): 1 cái có thể legacy thừa.
3. **Đổi mật khẩu** 2 admin thật (id 2, 6). **Quét malware Imunify**; cân nhắc bật **Patchstack Protection**.
4. **Tắt xmlrpc** (snippet `xmlrpc_enabled __return_false` hoặc chặn .htaccess); **chặn readme.html**.
5. Cân nhắc đổi username `admin` (id=1).
6. **Dọn TEST**: entry `TEST` trong Flamingo → Inbound; mail TEST trong inbox Linh, `tungtps@xhs.vn` (các test sáng), `info-vn@thankslab.biz` (test nghiệm thu).
7. Brevo branding (`em/img.em/r.em`) đang "Not branded" — cosmetic; nếu vài ngày chưa tự xanh thì bấm re-check trong Brevo → Domains.

### Việc agent (phiên sau)
- Xử lý post lạ `__trashed` (https://thankslab.com.vn/__trashed/ — publish, slug hỏng SEO): xem nội dung → sửa slug hoặc trash, user chốt.
- Gỡ Simple 301 Redirects nếu user báo trống.
- Có `BREVO_KEY` trong `.env` → có thể tự check log delivered/bounce khi cần.
- Khi mọi thứ ổn định: viết `tools/health_check.py` chỉ-đọc theo baseline site này (xem CLAUDE.md).

## 6. Backups đã tạo (local, gitignored — `backups/`)

- `pre-change-*` (role xhs/wordfen1 + comment/ping)
- `slug-change-*` (slug id 1/2/6)
- `demote-admin1-*` (id1 → editor)
- `activate-cf7db-*`, `install-updraft-*`, `admin-email-*`
- 2026-07-21: `cf7-investigate-*` (form 17 JSON), `mail-diag*-*` (chẩn đoán mail),
  `smtp-test-*` (trạng thái wp-mail-smtp), `flamingo-swap-*` (plugin trước/sau),
  `cleanup-*` (50 comment + user wordfen1), `remove-plugins-*` (info 5 plugin đã gỡ),
  `remove-acf7db-*` (Advanced CF7 DB trước khi xóa), `deact-wpforms-popup-*` (WPForms + Popup Builder)

## 7. Quy tắc làm việc (nhắc nhanh)

- GET/OPTIONS tự do; mọi thao tác GHI production phải báo + được duyệt (lệnh trực tiếp = duyệt).
- Trước khi ghi: GET backup vào `backups/`; sau khi ghi: GET verify; script có auto-rollback.
- Không dùng plugin "Disable REST API".
- Đọc `rules/` trước khi đụng REST/CF7/page content. Không paste secret ra chat/log/CLI.
