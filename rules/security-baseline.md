# Security baseline cho site WP mới — check ngay buổi đầu

Các phát hiện đã verify ở fitrack-wp, áp dụng cho mọi site WP.

## 1. User enumeration — mặc định của WP core, site nào cũng dính

`GET /wp-json/wp/v2/users` **không cần auth** trả về `slug` = `user_nicename`, mà
nicename mặc định = **username đăng nhập thật** → attacker có sẵn 50% bài toán
brute-force. Đây là hành vi core từ WP 4.7, không phải lỗ hổng plugin.

- Check: curl endpoint trên không auth, so `slug` với username đăng nhập.
- Fix không cần plugin: đổi `slug` qua REST (`POST /wp/v2/users/<id> {"slug":"ten-khac"}`)
  — **username đăng nhập không đổi**, chỉ slug công khai đổi. Lưu ý `user_nicename`
  KHÔNG sửa được trong wp-admin UI (chỉ có Nickname/Display name) — bắt buộc qua REST.
- Đừng fix bằng plugin chặn wp-json (giết automation + CF7).

## 2. Application Password — cách cấp API đúng

- Tạo ở wp-admin → Users → Profile → Application Passwords. **Không bao giờ** dùng
  password đăng nhập thật cho API.
- App password thừa kế **toàn bộ quyền của user tạo nó** → cân nhắc tạo từ user role
  thấp nhất đủ việc. Sửa CF7 cần admin; chỉ sửa page/post thì Editor đủ.
- Thu hồi được từng cái độc lập trong wp-admin — bị lộ thì revoke, không phải đổi password.
- Lưu theo scheme `.env`/`.env.enc` (tools/secrets.sh) — không hardcode, không paste ra chat.

## 3. Kiểm kê account buổi đầu

`GET /wp/v2/users?context=edit` (cần auth) → soát: bao nhiêu administrator? account
vendor/lạ nào còn quyền admin? Nguyên tắc đã áp dụng ở fitrack: vendor xong việc →
hạ xuống **Editor** (vẫn sửa content được, mất quyền plugin/user/lead Flamingo).
Trước khi hạ quyền ai: đảm bảo còn ít nhất 1 admin mình nắm — script hạ quyền phải
có guard danh sách KEEP_ADMIN.

## 4. Checklist còn lại buổi đầu (đọc-only, 10 phút)

- [ ] Plugin inactive → liệt kê, đề xuất xóa hẳn (code nằm đó vẫn khai thác được).
- [ ] Plugin/theme/core outdated → liệt kê version, **user tự bấm update trong wp-admin**
      (REST không update được — xem wp-rest-capabilities.md).
- [ ] Trang/post rác (Sample Page, Hello World, form CF7 mặc định).
- [ ] Timezone, ngôn ngữ, tagline mặc định "Just another WordPress site".
- [ ] `?author=1` và `/wp-json/wp/v2/users` (mục 1).
- Ghi kết quả 3 mức CRITICAL / PRIORITY / INFO, chờ user chốt từng mục — không tự sửa.
