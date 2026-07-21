# TRCF ERP — Hướng dẫn cài đặt

Phần mềm quản lý quán (bán hàng, kho, nhân sự, kế toán, màn bếp, đặt món online).
Cài **một lệnh duy nhất** trên máy chủ Ubuntu — script tự cài Docker, tự tải phần mềm,
tự sinh mật khẩu, tự khởi động. Bạn chỉ việc mở trình duyệt.

---

## 1. Cần chuẩn bị

| | |
|---|---|
| **Máy chủ** | Ubuntu 22.04 / 24.04 (hoặc Debian 12). Máy tính cũ, NUC mini, hay VPS đều được. |
| **Cấu hình tối thiểu** | 2 CPU · 4 GB RAM · 20 GB ổ cứng |
| **Mạng** | Máy chủ cắm **cùng wifi/mạng LAN** với máy thu ngân, tablet màn bếp |
| **Quyền** | Tài khoản có `sudo` |
| **Token cài đặt** | Một chuỗi do **nhà cung cấp cấp** cho bạn (dùng để tải phần mềm về) |

> Nên đặt **IP tĩnh** cho máy chủ (hoặc cấu hình DHCP reservation trên router) để địa chỉ
> truy cập không đổi sau khi khởi động lại.

---

## 2. Cài đặt — một lệnh

Đăng nhập vào máy chủ (trực tiếp hoặc qua SSH), dán lệnh sau — **thay `<token>` bằng
token nhà cung cấp đã gửi bạn**:

```bash
cd ~ && curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/ubuntu.sh \
  | GHCR_TOKEN=<token> bash
```

Chờ **3–5 phút**. Script tự động:

1. Cài **Docker Engine + Docker Compose** (từ repo chính thức của Docker)
2. Dùng token để **tải phần mềm** về
3. Tải bộ cấu hình về **`~/fnberp`**
4. Sinh **`.env`** — mật khẩu database, `JWT_SECRET`, `AUTH_SECRET` đều ngẫu nhiên, mỗi máy một giá trị
5. **Khởi động** toàn bộ hệ thống
6. Chờ tạo xong bảng + tài khoản quản trị, rồi **in ra địa chỉ + mật khẩu**

Kết thúc, màn hình hiện:

```
╔══════════════════════════════════════════════════════════╗
║              TRCF ERP đã cài đặt xong                    ║
╚══════════════════════════════════════════════════════════╝

  Mở trình duyệt   http://192.168.1.50
  Tài khoản        admin@trcf.vn
  Mật khẩu         ••••••••••
```

Mở đúng địa chỉ đó và đăng nhập.

> Mật khẩu in ra là mật khẩu **mặc định** do nhà cung cấp quy ước. Muốn đổi:
> đăng nhập → menu tài khoản → **Đổi mật khẩu**.

> Thông tin trên cũng được lưu ở `~/fnberp/thong-tin-dang-nhap.txt` (chỉ chủ máy đọc được).

---

## 3. Dùng từ máy khác trong quán

Mọi thiết bị **cùng wifi** với máy chủ đều mở được, dùng **chung một địa chỉ** ở trên:

| Thiết bị | Mở đường dẫn |
|---|---|
| Máy thu ngân | `http://192.168.1.50` → đăng nhập → **Bán hàng** |
| Tablet màn bếp | `http://192.168.1.50/kitchen/<mã-màn>` |
| Màn hình khách | `http://192.168.1.50/customer-display/<mã-phiên>` |
| Điện thoại quản lý | `http://192.168.1.50` |

*(thay `192.168.1.50` bằng IP máy chủ mà script in ra)*

Màn bếp và màn hình khách cập nhật **thời gian thực** — có món mới là hiện ngay, không cần bấm tải lại.

---

## 4. Tuỳ chọn khi cài

Thêm tham số sau `bash -s --`:

```bash
# Có tên miền riêng → tự cấp HTTPS miễn phí (DNS phải trỏ sẵn về IP máy chủ)
curl -fsSL <url> | GHCR_TOKEN=<token> bash -s -- --domain erp.quanmimosa.vn

# Tự đặt tài khoản quản trị
curl -fsSL <url> | GHCR_TOKEN=<token> bash -s -- --admin-email chu@quan.vn --admin-password 'MatKhauManh123'

# Cổng 80 đã bị chiếm → dùng cổng khác (truy cập http://<ip>:8080)
curl -fsSL <url> | GHCR_TOKEN=<token> bash -s -- --http-port 8080
```

| Tham số | Ý nghĩa |
|---|---|
| `--ghcr-token <token>` | Token tải phần mềm (thay cho `GHCR_TOKEN=`; đặt qua biến môi trường an toàn hơn vì không lưu vào lịch sử lệnh) |
| `--domain <tên-miền>` | Dùng domain thật + tự cấp/gia hạn HTTPS (Let's Encrypt) |
| `--admin-email <email>` | Email quản trị (mặc định `admin@trcf.vn`) |
| `--admin-password <mk>` | Mật khẩu quản trị (mặc định theo quy ước nhà cung cấp) |
| `--dir <đường-dẫn>` | Thư mục cài (mặc định `~/fnberp`) |
| `--http-port <số>` | Đổi cổng HTTP (mặc định 80) |
| `--tag <phiên-bản>` | Cài đúng một phiên bản (mặc định `latest`) |
| `--update` | Chỉ cập nhật bản mới, giữ nguyên cấu hình + dữ liệu |

---

## 5. Vận hành hằng ngày

Mọi lệnh chạy trong thư mục cài:

```bash
cd ~/fnberp

docker compose ps          # xem 4 service có chạy tốt không
docker compose logs -f     # xem log (Ctrl+C để thoát)
docker compose restart     # khởi động lại
docker compose down        # TẮT phần mềm (dữ liệu vẫn còn nguyên)
docker compose up -d       # BẬT lại
```

Máy chủ mất điện rồi bật lại: phần mềm **tự chạy lại**, không cần làm gì.

> Nếu báo `permission denied` khi gõ `docker`: đăng xuất/đăng nhập lại một lần
> (hoặc gõ `newgrp docker`) — do tài khoản vừa được thêm vào nhóm `docker`.

---

## 6. Cập nhật phiên bản mới

```bash
cd ~/fnberp && docker compose pull && docker compose up -d
```

Không cần nhập lại token — máy đã ghi nhớ từ lần cài đầu.

Cấu hình và **toàn bộ dữ liệu được giữ nguyên**.

> Nếu báo `denied` / `unauthorized`: token đã hết hạn hoặc bị thu hồi → xin token mới rồi chạy:
> ```bash
> cd ~ && curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/ubuntu.sh \
>   | GHCR_TOKEN=<token-mới> bash -s -- --update
> ```

---

## 7. Sao lưu dữ liệu — QUAN TRỌNG

Dữ liệu (đơn hàng, kho, khách, sổ quỹ) nằm trong volume Docker `pgdata` **trên chính máy chủ này**.
Máy hỏng ổ cứng mà không có bản sao là **mất sạch**.

**Sao lưu:**

```bash
cd ~/fnberp
docker compose exec -T postgres pg_dump -U trcf trcf_erp | gzip > ~/backup-$(date +%F).sql.gz
```

**Phục hồi:**

```bash
cd ~/fnberp
gunzip -c ~/backup-2026-07-21.sql.gz | docker compose exec -T postgres psql -U trcf trcf_erp
```

**Sao lưu tự động mỗi đêm 2h** (khuyến nghị — chạy một lần rồi quên):

```bash
mkdir -p ~/backups
(crontab -l 2>/dev/null; echo '0 2 * * * cd ~/fnberp && docker compose exec -T postgres pg_dump -U trcf trcf_erp | gzip > ~/backups/trcf-$(date +\%F).sql.gz && find ~/backups -name "trcf-*.sql.gz" -mtime +30 -delete') | crontab -
```

*(giữ 30 ngày gần nhất; định kỳ copy thư mục `~/backups` sang ổ cứng ngoài hoặc cloud)*

> ⚠️ **Tuyệt đối không chạy `docker compose down -v`** — cờ `-v` xoá volume = **mất toàn bộ dữ liệu**.

---

## 8. Cấu trúc thư mục cài

```
~/fnberp/
├── docker-compose.yml           # định nghĩa 4 service
├── Caddyfile                    # cấu hình cổng vào (proxy + HTTPS)
├── .env                         # ⚠️ mật khẩu + khoá bí mật (KHÔNG chia sẻ)
└── thong-tin-dang-nhap.txt      # địa chỉ + tài khoản quản trị
```

Hệ thống gồm 4 phần chạy trong Docker:

| Service | Việc |
|---|---|
| `caddy` | Cổng vào duy nhất — nhận mọi truy cập, tự cấp HTTPS khi có domain |
| `frontend` | Giao diện người dùng |
| `backend` | Xử lý nghiệp vụ + API |
| `postgres` | Cơ sở dữ liệu |

Chỉ `caddy` mở cổng ra ngoài; `backend` và `postgres` **chỉ chạy trong mạng nội bộ Docker**,
không truy cập trực tiếp từ ngoài được.

---

## 9. Gặp sự cố

| Hiện tượng | Xử lý |
|---|---|
| Mở địa chỉ không lên | `cd ~/fnberp && docker compose ps` — service nào không `healthy` thì xem `docker compose logs <tên-service>` |
| Cài xong nhưng chưa vào được ngay | Lần đầu backend cần ~1 phút để tạo bảng. Chờ rồi tải lại trang. |
| `bind: address already in use` | Cổng 80 đang bị phần mềm khác chiếm → cài lại với `--http-port 8080` |
| Máy khác cùng wifi không vào được | Kiểm tra đúng IP máy chủ (`hostname -I`); mở tường lửa: `sudo ufw allow 80/tcp` |
| Màn bếp không tự cập nhật | Tải lại trang; xem `docker compose logs backend`; đảm bảo mở đúng địa chỉ máy chủ (không phải `localhost`) |
| Quên mật khẩu quản trị | `cat ~/fnberp/thong-tin-dang-nhap.txt` |
| `docker: permission denied` | Đăng xuất/đăng nhập lại, hoặc `newgrp docker` |
| `Chưa có quyền tải phần mềm` | Thiếu token → chạy lại kèm `GHCR_TOKEN=<token>` |
| `Token không hợp lệ hoặc đã bị thu hồi` | Token hết hạn/bị thu hồi → xin nhà cung cấp token mới |

Cần hỗ trợ: gửi kèm kết quả của

```bash
cd ~/fnberp && docker compose ps && docker compose logs --tail=100
```

---

## 10. Cài thủ công (không dùng script)

```bash
mkdir -p ~/fnberp && cd ~/fnberp
BASE=https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main
curl -fsSL -O $BASE/docker-compose.yml
curl -fsSL -O $BASE/Caddyfile
curl -fsSL $BASE/.env.example -o .env

nano .env                # điền DB_PASSWORD, JWT_SECRET, AUTH_SECRET, ADMIN_SEED_*
openssl rand -hex 32     # sinh giá trị cho từng khoá bí mật

# Đăng nhập kho ảnh bằng token nhà cung cấp cấp
echo <token> | docker login ghcr.io -u nguyentrucanhtuan --password-stdin

docker compose up -d
```

---

*Dành cho người phát hành bản cài (phát hành ảnh, đổi phiên bản): xem [MAINTAINER.md](MAINTAINER.md).*
