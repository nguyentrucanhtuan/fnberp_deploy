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

Khoảng 15 phút, ai cũng làm được. Cần: máy in (bill và/hoặc tem) · bàn phím cắm vào máy quầy ·
**mật khẩu đăng nhập máy tính quầy** · tài khoản quản trị ERP.

> Máy in có **cổng mạng (dây LAN)** thì **không cần Bridge**: ERP → **Máy in** → **Thêm máy in** →
> Loại kết nối **Mạng LAN** → nhập IP máy in, cổng `9100`. Xong.
>
> Bridge dành cho máy in **chỉ có cổng USB**, máy quầy cắm máy in phải chạy **Linux**
> (Windows/macOS chưa hỗ trợ máy in USB). Cài ERP (phần A) **không** cài Bridge — ERP chỉ mở sẵn
> cửa `/bridge/*` để Bridge gọi vào.

### Bước 1 — Cắm máy in

1. Cắm **dây USB** của máy in vào máy quầy.
2. Cắm điện, **bật công tắc**, chờ đèn sáng.
3. Có máy in thứ hai (tem, bếp) thì cắm luôn.

### Bước 2 — Cài chương trình in (mỗi máy quầy làm 1 lần)

1. Bấm cùng lúc **Ctrl + Alt + T** → hiện cửa sổ nền đen (terminal). Cứ để mở tới hết.
2. Gõ hoặc dán (**Ctrl + Shift + V**) rồi Enter:

   ```bash
   cd ~ && curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/bridge.sh | sudo -E bash
   ```

3. Máy hỏi mật khẩu → gõ mật khẩu máy tính rồi Enter. **Lúc gõ màn hình không hiện gì — bình thường.**
4. Chờ khoảng 1 phút, thấy chữ xanh **"CÀI XONG"** là được.

> Máy quầy **chưa cài ERP** (máy in cắm ở máy khác máy chủ): chạy Bước 1 của phần A (cài Docker)
> trước, và thêm token vào lệnh: `... | GHCR_TOKEN=<token> sudo -E bash`. Không có token thì hỏi nhà cung cấp.

### Bước 3 — Tắt trình in có sẵn của Linux

Trình in của Linux (CUPS) hay **giành** máy in nhiệt, làm Bridge không thấy máy:

```bash
sudo systemctl mask --now cups cups.socket cups.path cups-browsed
```

⚠️ Máy quầy này còn dùng **in giấy A4** (máy in văn phòng) thì **bỏ qua** lệnh này và báo nhà cung cấp.
Muốn bật lại: `sudo systemctl unmask cups cups.socket cups.path cups-browsed`.

### Bước 4 — Kiểm tra máy in đã nhận

```bash
trcf-bridge list
```

Thấy tên máy in là đúng. Báo **"Không thấy máy in USB nào"** → kiểm dây + công tắc, rút USB cắm lại,
chờ 10 giây, gõ lại.

### Bước 5 — Khai máy in trên ERP

1. Mở trình duyệt, gõ **`localhost`** → Enter (máy in cắm ở máy khác máy chủ thì gõ IP máy chủ ERP).
   Đăng nhập quản trị.
2. Vào **Cài đặt cửa hàng → Máy in**.
3. Đã có sẵn dòng cho máy in này thì **bỏ qua**, sang Bước 6.
4. Chưa có → **Thêm máy in**:
   - **Tên thiết bị:** dễ nhận, vd `MÁY IN BILL QUẦY`
   - **Loại kết nối:** **USB**
   - **Loại máy in:** **Hoá đơn** (máy bill) · **Nhãn dán (Label)** (máy tem) · **Phiếu yêu cầu món** (máy bếp)
   - Máy bill: khổ giấy **80** hoặc **58** mm · Máy tem: **rộng × cao của CON TEM** (đo một con tem, không đo cuộn)
   - **Lưu**

### Bước 6 — Ghép máy in (lần lượt TỪNG máy một)

1. Trên ERP, chạm dòng máy in → **Lấy mã ghép**.
2. Hiện câu lệnh có mã 6 số → bấm **Chép câu lệnh**. ⏱ Mã sống **10 phút**, dùng một lần.
3. Sang cửa sổ đen, dán (**Ctrl + Shift + V**) → Enter. Hỏi mật khẩu thì gõ mật khẩu máy tính.
   Câu lệnh có dạng:

   ```bash
   sudo trcf-bridge pair --server http://localhost --code <mã-6-số>
   ```

4. Thành công → **máy in nhả một tờ thử**.
5. Báo **"có nhiều máy in, hãy chỉ rõ bằng --device"** kèm vài dòng `--device /dev/usb/lp…`:
   - bấm **mũi tên lên** để hiện lại câu lệnh vừa dán,
   - thêm vào cuối đúng `--device /dev/usb/lp…` của dòng có tên máy đang ghép
     (máy bill thường có chữ **POS**/**Printer**, máy tem có chữ **LABEL**),
     vd `sudo trcf-bridge pair --server http://localhost --code 123456 --device /dev/usb/lp1`
   - Enter.
6. Còn máy in khác → quay lại mục 1 với **dòng máy in đó**, mỗi máy **một mã mới**.

- Máy in cắm ở **chính máy chủ ERP**: giữ `http://localhost` (không thêm `:3333`).
- Máy in cắm ở **máy khác**: thay bằng địa chỉ ERP, vd `http://192.168.1.50`.

### Bước 7 — Bật chạy nền (1 lần, sau khi ghép xong hết)

```bash
sudo docker compose -f /opt/trcf-bridge/docker-compose.yml up -d
```

Thấy **Started**/**Running** là xong, đóng cửa sổ đen. Máy tính khởi động lại thì Bridge tự chạy.

### Bước 8 — Kiểm tra

1. ERP → **Máy in**: cột **Kết nối in** của mọi máy là **"Đang chạy"**.
2. Tạo một đơn có món nước, thanh toán → bill ra ở máy bill, tem ra ở máy tem.
3. Xem chữ tiếng Việt có dấu, giấy tự cắt, ngăn kéo tiền bật.

**Thêm máy in sau này** (bếp, tem): cắm vào → Bước 4–6 với mã mới → không phải cài lại Bridge
(nó tự dò thiết bị mới).

### Cập nhật Bridge / máy in đổi cổng

```bash
cd ~ && curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/bridge.sh \
  | sudo -E bash
```

Giữ nguyên liên kết, không phải ghép lại.

### Lỗi hay gặp

| Thấy gì | Làm gì |
|---|---|
| Mã ghép sai / hết hạn | Lấy mã mới trên ERP, dán lại lệnh. Chỉ mã mới nhất còn dùng được. |
| Không gọi được ERP | Sai `--server`. Dùng `http://localhost` hoặc `http://<IP máy chủ>`, **không** kèm `:3333`. |
| Máy in đang do máy khác cầm | ERP → Máy in → chạm dòng đó → *Thu hồi chương trình in* → ghép lại (Bước 6). |
| In được nhưng ngăn kéo tiền không bật | Ghép lại máy bill, thêm ` --drawer-pin 1` vào cuối lệnh. |
| Tem lệch, giấy chạy liên tục | Khai sai khổ tem → ERP sửa máy in tem, nhập đúng rộng × cao **con tem**. |

Lỗi khác — gõ lệnh sau, chụp màn hình gửi nhà cung cấp:

```bash
trcf-bridge version; trcf-bridge list; sudo docker compose -f /opt/trcf-bridge/docker-compose.yml logs --tail 100
```
