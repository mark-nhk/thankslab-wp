---
name: feedback-tooling-autonomy
description: "Chọn tooling/stack theo hướng agent tự động hóa được 100% bằng CLI, không phải theo hướng user tự thao tác GUI"
metadata:
  type: feedback
---

Khi chọn công cụ/hạ tầng dev cho user, ưu tiên thứ **agent điều khiển trọn vẹn bằng
dòng lệnh/script**, KHÔNG ưu tiên thứ "tiện tay user" (GUI bấm-là-chạy).

**Why:** User nói rõ: "tôi chỉ yêu cầu thôi, muốn bạn hỗ trợ làm phần lớn các việc."
Từng tư vấn LocalWP (GUI) vì tối ưu cho user tự dựng — tối ưu SAI hướng: agent không
tự thao tác GUI được, user vẫn phải bấm tay.

**How to apply:** local WP → PHP native + wp-cli + SQLite (`php -S`), agent drive 100%.
Tổng quát: giữa 2 tool tương đương, chọn cái có CLI/script đầy đủ. Xem [[feedback-work-style]].
