# Page content gotchas — chỉ áp dụng khi dán HTML/JS vào content WordPress

Ba sự cố chí mạng đã ăn thật ở fitrack-wp. Site mới chưa dán HTML tay thì chưa cần,
nhưng đọc trước khi làm bất kỳ landing/custom HTML nào.

## 1. Texturize phá inline script — cấm `&&`

WP texturize biến `&&` trong `<script>` inline (nằm trong post content) thành
`&#038;&#038;` → SyntaxError chết cả khối script. Triệu chứng: section trống hàng loạt,
nút chết, không lỗi nào hiện rõ.

- **Không để `&&` trong mọi inline script** của content — viết lại thành ternary /
  arrow-IIFE / `if` lồng.
- Chuẩn gác cổng: **0 ký tự `&`** trong inline script, kể cả trong string/regex
  (texturize phá tất) — cần `&` thì dùng `String.fromCharCode(38)`.
- Audit sau publish: curl trang, grep `&#038;` bên trong `<script>` — phải 0 kết quả;
  bóc từng script ra file → `node --check` pass.

## 2. wpautop chèn `<br/>` `<p>` phá markup — bọc wp:html

`the_content` tự chèn `<br />`/`<p>` vào HTML nhiều dòng → grid vỡ. Phòng: bọc toàn bộ
deliverable trong `<!-- wp:html -->` ... `<!-- /wp:html -->` (block HTML của Gutenberg
— wpautop không đụng vào).

## 3. Tab Visual (TinyMCE) nghiền nát code — cấm tuyệt đối

Mở/dán qua tab **Visual** một lần là code nát toàn bộ (`<span>` lạ trong `<option>`,
attribute bay màu). Chỉ dùng tab **Text** (Classic) hoặc **Code editor** (Gutenberg,
Ctrl+Shift+Alt+M). Không bao giờ hướng dẫn user mở tab Visual, kể cả "chỉ xem thôi".

## Khác biệt hợp lệ giữa nguồn dán và trang live (đừng báo động nhầm)

- Entity texturize trong **text** (ngoài script): `&#8220;` `&#8217;`... — bình thường.
- WP tự thêm `decoding="async"` vào `<img>` — bình thường.

## Kỹ thuật failsafe (tùy chọn, đáng dùng cho landing JS-nặng)

Cuối script chính đặt marker `;window.__ok=1;`. Script riêng thứ hai: sau ~1,2s nếu
`!window.__ok` thì bung mọi phần tử đang ẩn chờ animation (`.reveal` v.v.) — script chính
có chết vì lý do mới thì trang cũng không bao giờ trắng. Marker còn dùng để audit:
curl trang đếm số lần xuất hiện.
