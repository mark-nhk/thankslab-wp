# CLAUDE.md

<!-- Template từ fitrack-wp. Điền: <SITE_URL>, tên project, và xóa comment này. -->

Site production: `<SITE_URL>` — user **không có FTP/SSH**, chỉ có wp-admin + REST API
(Application Password). Mọi thao tác tự động đi qua REST. Đọc `rules/` trước khi làm
việc với REST hoặc page content.

## Nguyên tắc bất di bất dịch

1. **Đọc thoải mái, ghi phải duyệt.** GET/OPTIONS lên production chạy tự do. Mọi thao
   tác **GHI** (POST/PUT/DELETE) lên production phải báo user và được duyệt trước.
   User đã ra lệnh trực tiếp ("Làm đi") = duyệt, làm trọn gói không hỏi lại từng bước.
2. **Probe trước, ghi sau.** Chưa từng đụng endpoint nào thì chạy `tools/wp_probe.py`
   hoặc OPTIONS/GET trước để biết contract thật — không đoán theo docs.
3. **Mọi lần ghi có đường lùi.** Trước khi ghi: GET giá trị hiện tại, lưu ra file backup
   (thư mục `backups/`, gitignored). Sau khi ghi: GET lại + curl trang liên quan để verify.
   Script ghi nên có auto-rollback khi verify fail.
4. **Secrets:** credential REST ở `.env` (`WP_AUTH=user:app-password`), mã hóa `.env.enc`
   qua `tools/secrets.sh`, đọc trong code qua `tools/_secrets_env.py`. `.env` và
   `.secrets/` luôn gitignored. **Không bao giờ** echo/paste passphrase hay giá trị
   secret ra chat, log, hay command line.
5. Nếu dán HTML/JS vào page content: tuân thủ `rules/content-gotchas.md`
   (không `&&` trong inline script, bọc `<!-- wp:html -->`, không tab Visual).
6. Ý tưởng chưa chốt để trong `ideas/` (không dùng git branch); chỉ merge vào code
   chính khi user nói "chốt".
7. Không cài plugin dạng "Disable REST API / hide wp-json" — sẽ tự chặt đứt toàn bộ
   automation và cả CF7 (form gửi qua REST).

## Health check (khi user hỏi tình trạng site)

Chưa có tool riêng — làm tay theo pattern: curl trang chính (HTTP 200, không lỗi
hiển thị), GET `/wp/v2/plugins` (plugin lạ / inactive / cần update), GET `/wp/v2/users`
public (lộ slug thật không?), GET settings. Báo cáo 3 mức **CRITICAL / PRIORITY / INFO**,
**không tự sửa** — user chốt mục nào mới làm mục đó. Khi đã ổn định thì viết
`tools/health_check.py` chỉ-đọc với baseline của site này.

## Môi trường

- Windows + Claude Code: đọc `rules/agent-env-windows.md` (bẫy PowerShell `$var`,
  UTF-8, classifier chặn script ghi, Git Bash vs WSL cho secrets.sh).
- Setup một lần mỗi máy: `bash tools/secrets.sh setup` (Git Bash) → `decrypt`.
