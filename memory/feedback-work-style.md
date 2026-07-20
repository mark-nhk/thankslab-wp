---
name: feedback-work-style
description: "Cách user muốn làm việc — bàn trước khi làm, duyệt tường minh việc ghi production"
metadata:
  type: feedback
---

- Thay đổi kiến trúc/workflow: user muốn "**bàn trước khi thực hiện**" — trình bày
  phương án + trade-off, chờ chốt rồi mới làm. Khi user hỏi "vì sao phải X?" trả lời
  thẳng, kể cả khi câu trả lời là "cách cũ chưa tối ưu" — user đánh giá cao việc rút
  lại đề xuất khi có thông tin mới.
- Ghi lên production: báo trước rồi làm; user đã ra lệnh trực tiếp ("Làm đi") = duyệt,
  làm trọn gói không hỏi lại từng bước. User có thể từ chối 1 permission prompt rồi
  nói "Làm đi" — đó là duyệt lại, cứ chạy tiếp.
- Thay đổi nhiều phần lên live: làm **incremental theo đợt**, mỗi đợt đủ vòng
  test local → lên production → verify trên live → xong mới qua đợt kế.
- Ý tưởng chưa chốt để trong `ideas/` (không git branch), chỉ merge khi user nói "chốt".

**Why:** user quen quy trình duyệt 2 lớp (bàn phương án → duyệt thực thi), ghét rườm rà
nhưng vẫn muốn kiểm soát điểm ghi production.
**How to apply:** đề xuất → chờ chốt → làm một mạch → báo cáo kết quả kèm bằng chứng
(bảng audit, screenshot...). Xem [[feedback-tooling-autonomy]].
