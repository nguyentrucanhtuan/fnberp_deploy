# TRCF ERP — Cài đặt

Hai phần: **A. Cài ERP** (máy chủ của quán) · **B. Cài Bridge** (máy quầy có máy in USB).
Mỗi bước là một lệnh, dán vào terminal.

Bản đầy đủ (sao lưu, migration, xử lý sự cố, lịch sử): [docs/README-CHI-TIET.md](docs/README-CHI-TIET.md).

---

## A. Cài ERP

Cần: Ubuntu 22.04/24.04 · chip x86_64 (bộ cài tự kiểm) · 2 CPU · 4 GB RAM · 20 GB đĩa · tài khoản `root` hoặc có `sudo`
· token do nhà cung cấp cấp. Nên đặt IP tĩnh cho máy (hoặc DHCP reservation ở router).

### Bước 1 — Cài Docker

```bash
curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/docker.sh | bash && newgrp docker
```

### Bước 2 — Cài ERP

Thay `<token>` rồi dán. Chờ 5–10 phút, cuối cùng màn hình in địa chỉ, tài khoản, mật khẩu.

```bash
cd ~ && curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/erp.sh | GHCR_TOKEN=<token> bash
```

Xong. Hệ thống có sẵn kho tổng + kho quầy, 3 phương thức thanh toán, Quầy chính, cấu hình kho/quỹ,
phòng ban + hồ sơ Quản lý.

- Đăng nhập bằng tài khoản in ra (mặc định `admin@trcf.vn` / `1234567890@`), **đổi mật khẩu ngay**.
  Thông tin lưu ở `~/fnberp/thong-tin-dang-nhap.txt`.
- Máy thu ngân, tablet bếp, điện thoại cùng wifi mở **cùng địa chỉ đó**.
- Có tên miền: thêm `bash -s -- --domain erp.tenquan.vn` thay cho `bash` ở cuối lệnh (DNS phải trỏ về máy trước).
- Đứt giữa chừng: chạy lại đúng lệnh trên, nó làm tiếp phần còn dở.

### Lệnh thường dùng

```bash
cd ~/fnberp
docker compose ps          # trạng thái
docker compose logs -f     # xem log (Ctrl+C thoát)
docker compose restart     # khởi động lại
```

**Cập nhật lên bản mới** (giữ nguyên dữ liệu):

```bash
cd ~ && curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/erp.sh \
  | bash -s -- --update --backend-tag sha-<mới> --app-tag sha-<mới>
```

> ⛔ **Không bao giờ chạy `docker compose down -v`** — cờ `-v` xoá sạch dữ liệu.

---

## B. Cài Bridge (máy in USB)

Máy in có **cổng mạng (LAN)** thì **không cần Bridge**: vào ERP → **Máy in** → Thêm → kết nối **mạng**
→ nhập IP máy in + cổng `9100`. Xong.

Bridge chỉ dành cho máy in **chỉ có cổng USB**, và máy quầy cắm máy in phải chạy **Linux**
(Windows/macOS chưa hỗ trợ máy in USB).

### Bước 1 — Cắm máy in USB vào máy quầy, bật nguồn

Máy quầy chưa có Docker thì chạy bước A1 (cài Docker) trước.

### Bước 2 — Cài Bridge

```bash
cd ~ && curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/bridge.sh \
  | GHCR_TOKEN=<token> sudo -E bash
```

Máy đã cài ERP thì bỏ `GHCR_TOKEN=<token>` cũng được.

### Bước 3 — Kiểm tra máy in đã nhận

```bash
trcf-bridge list
```

Không thấy máy in nào:

```bash
sudo systemctl disable --now cups cups-browsed
```

rồi rút cắm lại dây USB, chạy lại bước 2.

### Bước 4 — Lấy mã ghép trên ERP

ERP → **Máy in** → **Thêm máy in** → kết nối **USB** → Lưu → menu **⋯** ở dòng vừa tạo →
**Lấy mã ghép**. Được mã 6 số, **dùng trong 10 phút**.

### Bước 5 — Ghép và bật chạy nền

```bash
sudo trcf-bridge pair --server http://localhost --code <mã-6-số>
docker compose -f /opt/trcf-bridge/docker-compose.yml up -d
```

- Máy in cắm ở **chính máy chủ ERP**: giữ `http://localhost` (không thêm `:3333`).
- Máy in cắm ở **máy khác**: thay bằng địa chỉ ERP, ví dụ `http://192.168.1.50`.

Máy in ra một tờ thử. Trên ERP, cột **Kết nối in** chuyển sang **"Đang chạy"** là xong.

**Thêm máy in thứ hai** (bếp, tem): cắm vào → chạy lại bước 2 → lặp bước 4–5 với mã mới.

### Cập nhật Bridge / máy in đổi cổng

```bash
cd ~ && curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/bridge.sh \
  | sudo -E bash
```

Giữ nguyên liên kết, không phải ghép lại.

### Lỗi hay gặp

| Báo lỗi | Làm |
|---|---|
| Mã ghép sai / hết hạn | Lấy mã mới. Mã dùng một lần, chỉ mã mới nhất còn dùng được. |
| Không gọi được ERP | Sai `--server`. Dùng `http://localhost` hoặc IP máy chủ, không kèm `:3333`. |
| Máy in đang do máy khác cầm | ERP → Máy in → **⋯** → *Thu hồi chương trình in* → ghép lại. |
| In được nhưng ngăn kéo tiền không bật | Ghép lại kèm `--drawer-pin 1`. |

Gửi nhà cung cấp khi cần hỗ trợ:

```bash
trcf-bridge version; trcf-bridge list; docker compose -f /opt/trcf-bridge/docker-compose.yml logs --tail 100
```
