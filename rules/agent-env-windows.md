# Bẫy môi trường Claude Code trên Windows (máy Lenovo của Mark)

Đúc kết từ fitrack-wp — thuộc về **máy + harness**, không thuộc project nào, nên site
mới dính y hệt.

## PowerShell tool nuốt `$var`

Truyền lệnh inline có biến `$` qua PowerShell tool bị nuốt biến → viết script `.ps1`
ra scratchpad rồi chạy `pwsh -File <path>`, đừng dùng `-Command` với `$`.

## Unicode tiếng Việt/Nhật ra console

Console mặc định cp1252 → `UnicodeEncodeError`. Fix bền nhất là **trong script Python**:

```python
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
```

(`PYTHONIOENCODING=utf-8` cũng được nhưng prefix `export ...;` làm hỏng permission-rule
matching — xem mục dưới.)

## Auto-mode classifier chặn script ghi production

Script Python gọi REST có DELETE/sửa user bị "Blocked by classifier" **dù user đã duyệt
bằng lời trong chat** — lớp classifier không đọc ngữ cảnh hội thoại. Có lệnh chặn lần 1
chạy lại lần 2 là qua; có lệnh chặn hẳn. **Không lách** — báo user chọn: duyệt prompt
hoặc tự thêm permission rule. Luôn chạy probe đọc-only (OPTIONS/GET) trước để biết
endpoint làm được không rồi hẵng viết script ghi.

Permission rule cho scratchpad user từng thêm (project mới đổi path tương ứng):
`"Bash(python C:/Users/Lenovo/AppData/Local/Temp/claude/<project-slug>/*)"` —
prefix-match nên lệnh phải bắt đầu đúng bằng `python <path>`: không quote path,
không `export ...;` đằng trước.

## Deny rule `.secrets` chỉ chặn tool Read

`deny: Read(.secrets/**)` chặn secret vào context của agent, nhưng agent **vẫn chạy
được** script con tự đọc secret trong tiến trình của nó — đó là đường chuẩn để thao tác
REST. Đừng hiểu nhầm thành "agent không dùng secret được".

## tools/secrets.sh — bẫy keystore Git Bash vs WSL

- User gõ `bash` trong PowerShell → ra **WSL**, cache passphrase vào keystore WSL —
  **agent không thấy**. Bash tool của agent là **MINGW/Git Bash**, đọc cache Windows
  DPAPI ở `~/.config/repo-secrets/<repo>.dpapi`.
- User setup phải bằng Git Bash thật:
  `& 'C:\Program Files\Git\bin\bash.exe' tools/secrets.sh setup`
- `REPO_ID` = **tên thư mục repo** → mỗi repo mới phải `setup` lại một lần (cache riêng
  theo tên thư mục), dù cùng passphrase.
