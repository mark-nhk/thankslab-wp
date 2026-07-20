# Contact Form 7 qua REST — namespace riêng, không phải wp/v2

Verify trên CF7 6.1.x (07/2026). Đây là phần trọng tâm khi site mới cấp API để sửa CF7.

## Điều quan trọng nhất

CF7 lưu form ở post type `wpcf7_contact_form` **không expose qua `/wp/v2/`** —
`GET/DELETE /wp/v2/wpcf7_contact_form/<id>` trả `rest_no_route`. Toàn bộ thao tác đi qua
namespace riêng:

```
GET    /wp-json/contact-form-7/v1/contact-forms            # danh sách form
GET    /wp-json/contact-form-7/v1/contact-forms/<id>       # 1 form, đủ properties
POST   /wp-json/contact-form-7/v1/contact-forms            # tạo form
POST   /wp-json/contact-form-7/v1/contact-forms/<id>       # sửa form
DELETE /wp-json/contact-form-7/v1/contact-forms/<id>       # xóa form (đã verify chạy được)
POST   /wp-json/contact-form-7/v1/contact-forms/<id>/feedback   # SUBMIT THẬT — cẩn thận
```

Cần auth admin (cap `wpcf7_read_contact_forms` / `wpcf7_edit_contact_forms` map về
`publish_pages`/`edit_others_pages`+ tùy version — thực tế app password của admin là đủ,
của Editor thì GET được nhưng nên probe lại trên version đang chạy).

## Sửa form

GET form trước để thấy shape thật của `properties` trên version đang chạy:
`form` (template shortcode-style), `mail`, `mail_2`, `messages`, `additional_settings`.
Khi POST sửa, gửi đúng key đó. **Luôn GET → lưu backup JSON → POST → GET lại so sánh.**
Đừng viết body theo docs/trí nhớ — probe bằng chính `tools/wp_probe.py <url> --cf7`.

## Bẫy trên site đang live

1. **`/feedback` là submit thật**: gửi mail thật + tạo lead Flamingo thật. Trên site
   live KHÔNG dùng nó để test — chỉ verify form render (curl trang chứa form, thấy
   markup `wpcf7`) + không lỗi JS console. Muốn test submit trọn vòng → làm trên staging.
2. **Xóa form đang được trang nào đó nhúng** → shortcode `[contact-form-7 ...]` thành
   text chết trên trang. Grep content các page trước khi xóa form.
3. CF7 mặc định tạo sẵn "Contact form 1" — form rác, xóa được (qua namespace riêng ở trên).
4. Form gửi qua chính REST (`admin-ajax` cũ / `wp-json` mới) → plugin dạng "Disable
   REST API" sẽ giết luôn form trên site. Không bao giờ cài.

## Flamingo (nếu site dùng để lưu lead)

- Flamingo map **mọi capability** của nó về `edit_users` — thực tế chỉ **Administrator**
  đọc được lead. Muốn chặn account nào đọc lead: hạ xuống Editor là đủ (đã verify).
- Lead nằm ở post type `flamingo_inbound` — cũng không expose REST; đọc lead tự động
  phải qua wp-admin hoặc viết endpoint riêng (chưa cần thì thôi).
