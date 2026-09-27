# TRCF ERP — Hướng dẫn cài đặt

Phần mềm quản lý quán (bán hàng, kho, nhân sự, kế toán, màn bếp, đặt món online).
Cài **một lệnh duy nhất** trên máy chủ Ubuntu — script tự cài Docker, tự tải phần mềm,
tự sinh mật khẩu, tự khởi động. Bạn chỉ việc mở trình duyệt.

---

## 1. Cần chuẩn bị

| | |
|---|---|
| **Máy chủ** | Ubuntu 22.04 / 24.04 (hoặc Debian 12). Máy tính cũ, NUC mini, hay VPS đều được. |
| **Vi xử lý (CPU)** | **x86_64 / amd64** — hầu hết PC, laptop, NUC, VPS đều loại này (kiểm tra: gõ `uname -m`, thấy `x86_64` là đúng). Máy chip **ARM** (`aarch64`/`arm64` — vài VPS ARM giá rẻ, Raspberry Pi, một số mini-PC) **chưa dùng được**. |
| **Cấu hình tối thiểu** | 2 CPU · 4 GB RAM · 20 GB ổ cứng |
| **Mạng** | Máy chủ cắm **cùng wifi/mạng LAN** với máy thu ngân, tablet màn bếp |
| **Quyền** | Tài khoản có `sudo` |
| **Token cài đặt** | Một chuỗi do **nhà cung cấp cấp** cho bạn (dùng để tải phần mềm về) |

> Nên đặt **IP tĩnh** cho máy chủ (hoặc cấu hình DHCP reservation trên router) để địa chỉ
> truy cập không đổi sau khi khởi động lại.

> **Chưa biết máy thuộc loại nào?** Gõ `uname -m` trên máy chủ: kết quả `x86_64` là dùng được;
> `aarch64` hoặc `arm64` thì báo nhà cung cấp (cần bản phần mềm cho ARM).

---

## 2. Cài đặt — một lệnh

Đăng nhập vào máy chủ (trực tiếp hoặc qua SSH). Cài **2 bước**, dán lần lượt —
thay `<token>` bằng token nhà cung cấp đã gửi bạn.

**Bước 1 — cài Docker** (bỏ qua nếu máy đã có sẵn):

```bash
curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/docker.sh | bash
```

> Lệnh này **không cần token** (Docker là phần mềm miễn phí, công khai). Nó cài **Docker Engine +
> Docker Compose** từ **kho chính thức của Docker**, bật dịch vụ tự chạy, rồi thêm tài khoản của bạn
> vào nhóm `docker` (để lần sau gõ `docker` không cần `sudo`). Máy đã có Docker thì script tự bỏ qua.
> Cài xong nếu được nhắc, **đăng xuất/đăng nhập lại** một lần (hoặc gõ `newgrp docker`).

**Bước 2 — cài TRCF ERP:**

```bash
cd ~ && curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/erp.sh \
  | GHCR_TOKEN=<token> bash
```

> Muốn gọn hơn thì chạy **một lệnh duy nhất** thay cho cả 2 bước trên:
> ```bash
> cd ~ && curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/ubuntu.sh \
>   | GHCR_TOKEN=<token> bash
> ```

Chờ **3–5 phút**. Script tự động:

1. Cài **Docker Engine + Docker Compose** (từ repo chính thức của Docker) — bước 1
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

### Quán đã có sẵn gì khi vừa cài xong

Để bán được ngay mà không phải khai báo từ đầu, hệ thống tự tạo:

| Mục | Có sẵn |
|---|---|
| Kho | **Kho tổng** (nhập hàng, nguyên liệu) · **Kho quầy** (trừ hàng khi bán) |
| Thanh toán | **Tiền mặt** · **Chuyển khoản** · **Thẻ ngân hàng** |
| Quầy bán hàng | **Quầy chính** (nhận cả 3 hình thức trên) |
| Cấu hình | Kho bán/nhập/chế biến + phương thức tiền mặt cho sổ quỹ — đã trỏ đúng |
| Nhân sự | Phòng ban **Vận hành** + hồ sơ **Quản lý** gắn sẵn tài khoản quản trị |

Đổi tên, sửa hay xoá thoải mái — **hệ thống không tạo lại** những mục bạn đã xoá.
Riêng nhân viên: mỗi người bán cần **một tài khoản riêng gắn hồ sơ nhân viên**
(Nhân sự → Nhân viên), vì ai bán thì tự mở ca của người đó.

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

## 5. Máy in bill và phiếu bếp

Có **hai loại máy in**, cách lắp khác hẳn nhau. Nhìn vào cổng cắm phía sau máy in là biết:

| Máy in có | Phải cài gì | Vì sao |
|---|---|---|
| **Cổng mạng (LAN/Ethernet)** | **Không cài gì cả** | Máy chủ tự mở kết nối tới máy in. Chỉ cần vào ERP mục *Máy in* → Thêm → chọn **mạng** → nhập IP + cổng `9100`. |
| **Chỉ có cổng USB** | **Chương trình in** (mục dưới) | Máy chủ chạy trong Docker, mà container không chạm được cổng USB của máy. Phải có một chương trình nhỏ chạy **ngoài** container làm cầu nối. |

> **Máy in LAN dễ hơn hẳn.** Nếu đang chọn mua, chọn loại có cổng mạng thì bỏ qua được toàn bộ mục này.

### Hệ điều hành nào chạy được chương trình in

| Máy quầy chạy | Máy in USB | Máy in LAN |
|---|---|---|
| **Linux** (Ubuntu, Debian… · x86_64 hoặc ARM) | ✅ chạy đủ | ✅ (không cần chương trình in) |
| **Windows** | ❌ **chưa hỗ trợ** | ✅ (không cần chương trình in) |
| **macOS** | ❌ chưa hỗ trợ | ✅ (không cần chương trình in) |

Windows và macOS chỉ dùng được máy in **LAN**. Máy in USB trên hai hệ này còn đang làm dở —
quán đang dùng Windows mà chỉ có máy in USB thì tạm thời chưa in được, hãy báo nhà cung cấp.

---

### Cách 1 — Chạy bằng Docker: **một lệnh** (khuyến nghị, chỉ Linux)

Gọn nhất, và cập nhật về sau cũng chỉ một lệnh. **Chỉ chạy được trên Linux**: Docker trên
Windows/macOS nằm trong máy ảo không có cổng USB nào để cấp cho container.

```bash
cd ~ && curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/bridge.sh \
  | GHCR_TOKEN=<token> sudo -E bash
```

Lệnh này tự làm hết: kiểm máy chạy được không → tải phần mềm → **tự dò máy in đang cắm** →
ghi cấu hình vào `/opt/trcf-bridge` → cài lệnh gọn `trcf-bridge`.

> Máy đã cài ERP thì thường **không cần token** — Docker đã đăng nhập sẵn từ lần cài đó.
> Cứ chạy không có `GHCR_TOKEN=`, thiếu thì script sẽ tự nhắc.

**Ghép nối là bước riêng** (script cố ý không làm hộ: mã ghép chỉ sống 10 phút, gộp vào lệnh
cài thì phải lấy mã trước rồi mới dám chạy, lỡ tay là mã hết hạn giữa chừng):

```bash
# 1. Vào ERP → Máy in → Thêm máy in → chọn kết nối USB → lưu
# 2. Menu ⋯ ở dòng vừa tạo → Lấy mã ghép (mã 6 số)
# 3. Chạy trên máy quầy:
sudo trcf-bridge pair --server http://localhost --code <mã-6-số>

# 4. Bật chạy nền:
docker compose -f /opt/trcf-bridge/docker-compose.yml up -d
```

Xong: cột **Kết nối in** ở màn *Máy in* phải chuyển sang **"Đang chạy"**.

**Cắm thêm máy in thứ hai** (bếp, tem): chạy lại lệnh cài (nó dò cổng mới), rồi lặp bước 1–3
với mã mới. Chương trình tự cầm thêm máy in đó, không phải cài lại.

#### Cập nhật (Docker)

```bash
cd ~ && curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/bridge.sh \
  | sudo -E bash
```

Đúng lệnh cài lúc đầu — chạy lại là tải bản mới, dò lại cổng máy in, rồi khởi động lại. Liên kết
máy in **giữ nguyên**, không phải ghép lại.

> **Máy in đổi cổng** (rút cắm lại dây, khởi động máy → số `lpN` nhảy) cũng chữa bằng đúng lệnh
> này. Đó là lý do lệnh cài và lệnh cập nhật là một.

#### Xem và gỡ (Docker)

```bash
docker compose -f /opt/trcf-bridge/docker-compose.yml logs -f    # xem nhật ký
trcf-bridge list                                                # xem máy in đang cắm
trcf-bridge version                                             # đang chạy bản nào

docker compose -f /opt/trcf-bridge/docker-compose.yml down       # gỡ
sudo rm -rf /opt/trcf-bridge /usr/local/bin/trcf-bridge
sudo rm -rf /etc/trcf-bridge      # xoá luôn liên kết → lần sau phải ghép lại
```

---

### Cách 2 — Cài thẳng lên máy, không dùng Docker (Linux)

Dành cho máy quầy không chạy Docker (ERP đặt ở máy khác), hoặc muốn nhẹ hết mức.
Chương trình chạy bằng systemd, tự bật lại sau khi mất điện.

**Bước 1 — lấy chương trình** (moi ra từ ảnh Docker, dùng đúng token đã cấp lúc cài ERP):

```bash
echo <token> | docker login ghcr.io -u nguyentrucanhtuan --password-stdin
docker pull ghcr.io/nguyentrucanhtuan/trcf-bridge:latest
id=$(docker create ghcr.io/nguyentrucanhtuan/trcf-bridge:latest)
sudo docker cp $id:/usr/local/bin/trcf-bridge /usr/local/bin/trcf-bridge
docker rm $id && sudo chmod +x /usr/local/bin/trcf-bridge
```

**Bước 2 — xem máy in đã nhận chưa:**

```bash
trcf-bridge list
```

Không thấy gì thì kiểm dây, và xem mục *Máy in không ra giấy* ở dưới.

**Bước 3 — lấy mã ghép:** vào ERP mục *Máy in* → **Thêm máy in** → chọn kết nối **USB** → lưu →
menu ⋯ của dòng vừa tạo → **Lấy mã ghép**. Được **mã 6 số**, dùng trong **10 phút**.

**Bước 4 — ghép:**

```bash
sudo trcf-bridge pair --server http://localhost --code <mã-6-số>
```

Lệnh này tự dò máy in, **in một tờ thử**, rồi cài dịch vụ chạy nền. Không ra giấy thì nó dừng
ngay tại đó — không ghép bừa.

> ⚠️ `--server http://localhost`, **không phải** `http://localhost:3333`. Máy chủ nằm trong
> Docker và cổng 3333 cố ý không mở ra ngoài; chương trình in đi vào bằng cổng 80.
>
> Máy in cắm ở **máy khác** trong quán thì thay `localhost` bằng IP máy chủ, ví dụ
> `--server http://192.168.1.50`.

**Bước 5 — kiểm:** ở màn *Máy in*, cột **Kết nối in** phải chuyển sang **"Đang chạy"**. Trên máy:

```bash
systemctl status trcf-bridge
```

**Cắm thêm máy in thứ hai** (bếp, tem): lặp lại bước 3–4 với mã mới. Chương trình tự cầm thêm
máy in đó, **không** phải cài lại lần nữa.

#### Cập nhật chương trình in

```bash
docker pull ghcr.io/nguyentrucanhtuan/trcf-bridge:latest
id=$(docker create ghcr.io/nguyentrucanhtuan/trcf-bridge:latest)
sudo systemctl stop trcf-bridge
sudo docker cp $id:/usr/local/bin/trcf-bridge /usr/local/bin/trcf-bridge
docker rm $id
sudo systemctl start trcf-bridge
trcf-bridge version
```

Cấu hình và liên kết máy in **giữ nguyên** — không phải ghép lại.

#### Gỡ ra

```bash
sudo systemctl disable --now trcf-bridge
sudo rm /etc/systemd/system/trcf-bridge.service /usr/local/bin/trcf-bridge
sudo rm -rf /etc/trcf-bridge          # xoá luôn liên kết → lần sau phải ghép lại
sudo systemctl daemon-reload
```

---

### Máy in không ra giấy — xử lý

| Hiện tượng | Xử lý |
|---|---|
| `pair` báo **"mã ghép sai hoặc đã hết hạn"** | Mã sống 10 phút và **dùng một lần**. Lấy mã mới. Bấm nút lấy mã hai lần thì **chỉ mã mới nhất** còn dùng được. |
| `pair` báo **"không gọi được ERP"** | Sai địa chỉ. Dùng `http://localhost` (**không** kèm `:3333`), hoặc IP máy chủ nếu máy in cắm ở máy khác. |
| `pair` báo máy in **đang do máy khác cầm** | Đúng như vậy — một máy in chỉ thuộc một máy tính. Vào ERP gỡ nó khỏi máy cũ (menu ⋯ → *Thu hồi chương trình in*) rồi ghép lại. |
| `list` không thấy máy in nào, `/dev/usb/` trống | Hệ thống in của Linux (CUPS) hay **giành mất** máy in nhiệt USB: nó tự thêm một hàng đợi rồi tách driver, làm `/dev/usb/lpN` biến mất. Gỡ hàng đợi đó (`lpstat -p` rồi `lpadmin -x <tên>`) hoặc tắt CUPS nếu quán không in giấy A4: `sudo systemctl disable --now cups cups-browsed`. |
| Bill in ra nhưng **ngăn kéo tiền không bật** | Máy in dùng chân RJ11 khác. Ghép lại kèm `--drawer-pin 1` (mặc định là **chân 2**, đa số máy dùng chân này; `1` là chân 5). |
| Cột **Kết nối in** báo *"Chưa rõ tình trạng máy in"* | Chương trình in còn chạy nhưng lâu không báo tình trạng cổng. Xem `journalctl -u trcf-bridge -n 50` (hoặc `docker compose logs`). |
| Lệnh in nằm **"Đang chờ"** mãi | Máy in chưa ghép, hoặc chương trình in không chạy. Kiểm `systemctl status trcf-bridge`. Muốn bỏ lệnh: màn *Hàng đợi in* → **Bỏ lệnh**. |

Cần hỗ trợ: gửi kèm

```bash
trcf-bridge version && trcf-bridge list && journalctl -u trcf-bridge -n 100
```

---

## 6. Vận hành hằng ngày

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

## 7. Cập nhật phiên bản mới

```bash
cd ~/fnberp && docker compose pull && docker compose up -d
```

Không cần nhập lại token — máy đã ghi nhớ từ lần cài đầu.

Cấu hình và **toàn bộ dữ liệu được giữ nguyên**.

Bản mới có **migration một chiều** thì backend **không** tự chạy nó — xem [Migration một chiều](#migration-một-chiều--chạy-tay-có-người-ngồi-trước-màn-hình) bên dưới. Bản mới có thay đổi cấu trúc dữ liệu (migration) thường thì backend **tự sao lưu trước** rồi mới đổi — xem [§8 · Cổng sao lưu tự động](#cổng-sao-lưu-tự-động-trước-mỗi-lần-nâng-cấp). Sao lưu hỏng thì backend **không migrate, không mở cổng** — nhưng container có `restart: unless-stopped` nên sẽ **tự khởi động lại và thử lại cổng** (kèm một lượt `pg_dump` đầy đủ) mỗi lần. `docker compose logs backend` nêu lý do; trong lúc điều tra hãy `docker compose stop backend` để nó thôi thử lại.

> Nếu báo `denied` / `unauthorized`: token đã hết hạn hoặc bị thu hồi → xin token mới rồi chạy:
> ```bash
> cd ~ && curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/ubuntu.sh \
>   | GHCR_TOKEN=<token-mới> bash -s -- --update
> ```

### Migration một chiều — chạy tay, có người ngồi trước màn hình

Một số bản nâng cấp mang **migration một chiều**: thay đổi cấu trúc dữ liệu **không có đường lùi dữ liệu** (vd đổi kiểu cột giờ, thêm cột quán). Backend **không bao giờ** tự chạy loại này lúc khởi động — kể cả khi container tự khởi động lại lúc 2 giờ sáng. Người vận hành chạy tay, trong cửa sổ đã hẹn.

**Nhận biết.** Sau `docker compose pull && docker compose up -d`, log backend có dòng:

```
WARN [BackupGate] Migration MỘT CHIỀU đang chờ chạy tay (boot không chạy): <TênMigration> — lệnh: docker compose run --rm --no-deps backend node dist/oneway-migrate <TênMigration> …
```

Phần mềm **vẫn bán bình thường** trên cấu trúc cũ. Nhưng nếu bản mới còn có migration thường **phụ thuộc** vào migration một chiều đó, backend **từ chối khởi động** với câu `Cần chạy tay <TênMigration> trước (migration một chiều) — … migration thường đứng sau nó đang bị chặn: …`. Khi đó quán đang dừng bán — chạy tay ngay theo các bước dưới (hoặc quay về ảnh cũ nếu chưa tới cửa sổ).

**Cửa sổ.** Chỉ chạy **ngoài giờ bán**. Trần **30 phút** mỗi pha, mỗi quán, tính từ lúc dừng backend tới lúc backend lắng nghe lại. Thời gian lấy từ lượt chạy thử trên **bản sao Coffeetree** ở local (bắt buộc trước khi lên lịch). Dòng `✅ Đã chạy … trong X s` chỉ là phần migrate; ước cửa sổ bằng số **`Tổng kể cả sao lưu`** cộng thời gian bước 3 (boot chụp thêm một bản dump nếu còn migration thường để lại) — đo cả hai trên bản sao. Bản sao đo **vượt 30 phút ⇒ chia nhỏ migration**, không nới trần: gom theo **cụm bảng cùng ranh giới ngày** (`orders` + `account_journal_entries` + `pos_sessions` + `order_loyalty` chung một cửa sổ), mỗi cụm một cửa sổ, chạy lại bài kiểm đơn 00:30 sau mỗi cửa sổ.

**Kiểm chỗ trống trước (E-06).** Đổi kiểu cột viết lại cả bảng — cần khoảng **2 × bảng lớn nhất**, cộng thêm bản dump nằm cùng đĩa. Lệnh chạy tay in sẵn `Kích thước DB` và 5 bảng lớn nhất *trước* khi chạm schema; đối chiếu với:

```bash
df -h /var/lib/docker
```

Chỗ trống < kích thước DB + 2 × bảng lớn nhất + bản dump ⇒ **không mở cửa sổ** (giải phóng đĩa trước).

**Các bước** — chạy trong `tmux` (hoặc `screen`) để đứt SSH không cắt ngang lệnh; nối lại bằng `tmux attach`:

```bash
tmux new -s migrate
cd ~/fnberp
docker compose stop backend           # 1. dừng bán — không ai ghi vào DB trong lúc đổi
docker compose run --rm --no-deps backend node dist/oneway-migrate <TênMigration>   # 2.
docker compose up -d backend          # 3. mở lại; kiểm log "Backend đang chạy"
```

Lệnh ở bước 2 làm theo thứ tự cố định:

1. Kiểm tên — phải là migration một chiều (sai tên ⇒ mã 2, in danh sách tên có). Đã chạy rồi ⇒ in `đã chạy`, thoát 0, không làm gì.
2. In kích thước DB + bảng lớn nhất.
3. **Cổng sao lưu bắt buộc**: `pg_dump` vào volume `backups` + kiểm đọc lại ba lớp ([§8](#cổng-sao-lưu-tự-động-trước-mỗi-lần-nâng-cấp)). Hỏng ⇒ **không đổi gì**, thoát 1.
4. Chạy migration một chiều **cùng mọi migration thường đứng trước nó** trong **một transaction** (hạn chờ khoá 60 giây). Lỗi ⇒ rollback cả lô, thoát 1. Migration thường đứng sau nó để lần khởi động ở bước 3.
5. Đối chiếu lại bảng `migrations`, in `✅ Đã chạy … trong X s (Y ms, một transaction)`.

Có nhiều migration một chiều đang chờ thì chạy **theo thứ tự thời gian** — lệnh từ chối và nêu tên cái phải chạy trước.

#### Đứt giữa chừng — mất điện, đứt SSH, tiến trình bị giết

Migration nằm trọn trong một transaction: Postgres chỉ ghi khi nhận `COMMIT`. Đứt trước đó ⇒ **không có gì được ghi**. Nhưng phiên phía Postgres **không chết ngay** — nó chạy nốt câu lệnh đang chạy (một `ALTER` lớn có thể vài phút) rồi mới phát hiện mất kết nối và rollback. Trong lúc đó nó **vẫn giữ khoá bảng**. Bài diễn tập đã đo đúng hiện tượng này.

**Chạy tiếp thế nào:**

```bash
cd ~/fnberp
# 0. Container của lượt trước còn sống không? Đứt SSH thường KHÔNG giết
#    `docker compose run` — nó vẫn chạy và có thể COMMIT xong. Còn dòng nào ⇒
#    CHỜ nó thoát (docker logs -f <tên> để xem kết quả), đừng chạy lượt thứ hai.
docker ps --filter "label=com.docker.compose.oneoff=True" --format '{{.Names}}  {{.Status}}  {{.Command}}'
docker compose ps -a
#    (chạy song song thì lượt sau cũng tự từ chối: "đang có một lượt oneway-migrate khác")
# a. Còn phiên mồ côi nào của lượt trước? (có dòng ⇒ nó còn giữ khoá)
docker compose exec -T postgres psql -U trcf trcf_erp -c \
  "SELECT pid, state, now() - query_start AS da_chay, left(query, 80) FROM pg_stat_activity
    WHERE datname = current_database() AND pid <> pg_backend_pid() AND state <> 'idle'"
#    Chờ nó tự kết thúc, hoặc cắt hẳn (an toàn — chưa COMMIT thì chỉ rollback):
docker compose exec -T postgres psql -U trcf trcf_erp -c "SELECT pg_terminate_backend(<pid>)"
# b. Migration đã ghi nhận chưa?
docker compose exec -T postgres psql -U trcf trcf_erp -c \
  "SELECT id, name FROM migrations ORDER BY id DESC LIMIT 5"
# c. Cấu trúc bảng đang là gì? (vd kiểu cột của bảng mà migration đổi)
docker compose exec -T postgres psql -U trcf trcf_erp -c \
  "SELECT table_name, column_name, data_type FROM information_schema.columns WHERE table_name = '<bảng>'"
# d. Chạy lại đúng lệnh bước 2 — an toàn khi chạy lặp:
docker compose run --rm --no-deps backend node dist/oneway-migrate <TênMigration>
```

- (b) **có** dòng `<TênMigration>` ⇒ đứt **sau** `COMMIT`: migration đã xong, (d) sẽ in `đã chạy`. Chỉ cần bước 3.
- (b) **không có** dòng ⇒ đã rollback trọn: cấu trúc ở (c) là cấu trúc cũ. (d) chụp một bản dump mới rồi chạy lại từ đầu.
- (d) báo `lock timeout` ⇒ vẫn còn phiên giữ khoá (backend chưa dừng, hoặc phiên mồ côi) — quay lại (a).

**Quay về bản dump thế nào** (migration xong nhưng phát hiện sai, hoặc không muốn chạy tiếp): mỗi lượt đã chụp một bản dump **ngay trước khi đổi**, nằm trong volume `backups` — xem bằng lệnh chạy được cả khi backend đang dừng (đang trong cửa sổ): `docker compose run --rm --no-deps --entrypoint ls backend -lh /backups`. **Lấy đúng tệp lệnh chạy tay đã in** ở dòng `Đã sao lưu và kiểm đọc lại được: /backups/trcf_erp-<ts>.dump` — KHÔNG lấy bừa "bản mới nhất": bước 3 (`up -d backend`) chạy migration thường để lại thì tự chụp thêm một bản **sau khi đã đổi**, và mỗi lượt chạy lại cũng thêm một bản. Khôi phục đè lên DB của quán:

```bash
cd ~/fnberp
docker compose stop backend
docker compose cp backend:/backups/trcf_erp-<ts>.dump ./restore.dump
docker compose cp ./restore.dump postgres:/tmp/restore.dump
docker compose exec -T postgres dropdb -U trcf --force trcf_erp
docker compose exec -T postgres createdb -U trcf trcf_erp
docker compose exec -T postgres pg_restore -U trcf --no-owner --no-privileges --exit-on-error \
  -d trcf_erp /tmp/restore.dump
docker compose up -d backend
```

Sau khi khôi phục, backend mở lại trên **cấu trúc cũ** và log lại cảnh báo migration một chiều đang chờ — đúng ý (chưa chạy lại cho tới cửa sổ sau). Riêng khi bản mới có migration thường phụ thuộc vào nó (boot báo `Cần chạy tay … trước`), backend sẽ từ chối khởi động: phải chạy lại migration trong cửa sổ khác, hoặc tạm về ảnh của bản trước.

*(Cùng lệnh `createdb` + `pg_restore` như [§8 · Khôi phục một bản dump](#khôi-phục-một-bản-dump-xuống-postgres-17-máy-local), chỉ khác là khôi phục vào DB của quán thay vì DB local. Mọi đơn bán **sau** giờ chụp dump sẽ mất — chỉ dùng khi dữ liệu sai nặng hơn.)*

**Đảo bằng `down()`** (không mất đơn bán sau đó, khi migration có `down()` đã diễn tập trên bản sao): chỉ đảo được migration **chạy sau cùng** — có migration nào chạy sau nó thì lệnh từ chối và nêu tên.

> ⚠️ Cửa sổ `--down` đóng ngay khi `docker compose up -d backend` (bước 3) chạy các migration thường **đứng sau** mà lệnh đã để lại — từ đó `--down <TênMigration>` bị từ chối (`không phải dòng mới nhất`). Muốn đảo sau lúc đó phải `migration:revert` từng migration thường mới hơn trước rồi mới `--down` — nhưng ảnh backend hiện **không** chạy được `migration:revert` (`dist/data-source.js` cần gói `dotenv` không có trong ảnh; đo 27/09), nên ở máy quán đường thực tế là **quay về dump**. Muốn giữ đường `--down`: kiểm kết quả **trước** bước 3.

```bash
docker compose stop backend
docker compose run --rm --no-deps backend node dist/oneway-migrate --down <TênMigration>
```

Lệnh cũng chụp dump trước khi đảo. `pnpm migration:revert` / `typeorm migration:revert` **không** đảo được migration một chiều (báo "not found in source code").

---

## 8. Sao lưu dữ liệu — QUAN TRỌNG

Dữ liệu nằm trên **chính máy chủ này**, trong **hai** volume Docker:

| Volume | Chứa gì | Sao lưu bằng |
|---|---|---|
| `pgdata` | Đơn hàng, kho, khách, sổ quỹ, nhân sự | `pg_dump` |
| `uploads` | **Ảnh sản phẩm** | `tar` (⚠️ `pg_dump` KHÔNG chứa ảnh) |
| `backups` | Bản dump **tự động** trước mỗi lần nâng cấp có migration | tự sinh — xem mục cổng sao lưu dưới |

Máy hỏng ổ cứng mà không có bản sao là **mất sạch**.

> ⚠️ Trong CSDL chỉ lưu **tên tệp ảnh**, còn tệp ảnh nằm ở volume `uploads`. Phục hồi mỗi `pg_dump` sẽ ra một thực đơn **trắng ảnh** — sản phẩm còn đủ nhưng ô ảnh rỗng. Phải sao lưu cả hai.

**Sao lưu:**

```bash
cd ~/fnberp
# 1. Cơ sở dữ liệu
docker compose exec -T postgres pg_dump -U trcf trcf_erp | gzip > ~/backup-$(date +%F).sql.gz
# 2. Ảnh sản phẩm
docker run --rm -v trcf-erp_uploads:/data -v ~:/out alpine \
  tar czf /out/backup-uploads-$(date +%F).tar.gz -C /data .
```

**Phục hồi:**

```bash
cd ~/fnberp
# 1. Cơ sở dữ liệu
gunzip -c ~/backup-2026-07-21.sql.gz | docker compose exec -T postgres psql -U trcf trcf_erp
# 2. Ảnh sản phẩm
docker run --rm -v trcf-erp_uploads:/data -v ~:/in alpine \
  tar xzf /in/backup-uploads-2026-07-21.tar.gz -C /data
```

*(tên volume có tiền tố `trcf-erp_` theo `name:` trong `docker-compose.yml`; kiểm bằng `docker volume ls`)*

**Sao lưu tự động mỗi đêm 2h** (khuyến nghị — chạy một lần rồi quên):

```bash
mkdir -p ~/backups
(crontab -l 2>/dev/null; echo '0 2 * * * cd ~/fnberp && docker compose exec -T postgres pg_dump -U trcf trcf_erp | gzip > ~/backups/trcf-$(date +\%F).sql.gz && find ~/backups -name "trcf-*.sql.gz" -mtime +30 -delete') | crontab -
```

*(giữ 30 ngày gần nhất; định kỳ copy thư mục `~/backups` sang ổ cứng ngoài hoặc cloud)*

### Cổng sao lưu tự động trước mỗi lần nâng cấp

Mỗi lần backend khởi động, **trước khi** đổi cấu trúc dữ liệu:

1. **Không có migration chờ** → không sao lưu, chạy như thường.
2. **Có migration chờ** → `pg_dump` ra volume `backups` (trên chính máy quán), rồi **kiểm bản dump đọc lại được** theo ba lớp: mục lục đọc được · số bảng khớp CSDL · đọc **toàn phần** tệp thành công. Chỉ khi đủ ba lớp mới migrate.
3. **Bản dump hỏng ở bất kỳ lớp nào** (đĩa đầy, `pg_dump` bị giết, tệp cụt, thiếu/lệch client Postgres) → tiến trình backend **thoát, không migrate, không mở cổng**, log nêu lý do kèm dung lượng trống. Dữ liệu còn nguyên như trước khi cập nhật. Container có `restart: unless-stopped` nên Docker **khởi động lại và chạy lại cổng** (mỗi lần một lượt `pg_dump` đầy đủ, tải lên CSDL) cho tới khi hết lỗi.

Giữ **5** bản mới nhất (đổi bằng `BACKUP_KEEP=` trong `.env`). Tên tệp: `trcf_erp-<YYYYMMDDTHHmmssZ>.dump` (giờ UTC).

**Bản sao thứ hai lên Cloudflare R2 (tuỳ chọn).** Điền vào `.env` rồi `docker compose up -d`:

```bash
R2_ACCOUNT_ID=...            # Cloudflare → R2 → Account ID
R2_ACCESS_KEY_ID=...         # R2 API token — CHỈ GHI, giới hạn đúng bucket này (xem dưới)
R2_SECRET_ACCESS_KEY=...
R2_BACKUP_BUCKET=trcf-backups
# R2_ACCOUNT_ID phải là 32 ký tự hex thường; R2_BACKUP_PREFIX tự thêm "/" cuối
R2_BACKUP_PREFIX=quan-a/     # tuỳ chọn — tách thư mục theo quán
```

Đẩy R2 là **cố-gắng-hết-sức**: mạng hỏng hay R2 từ chối thì chỉ cảnh báo trong log rồi vẫn nâng cấp — bản trong volume `backups` mới là bản bắt buộc. Thiếu một biến ⇒ bỏ qua, log nêu biến thiếu.

- **Token:** cổng chỉ gửi **một lệnh PUT** — cấp quyền **chỉ ghi** (Object Write) nếu Cloudflare cho, và giới hạn đúng bucket sao lưu. Máy quán lộ token thì kẻ gian không đọc được các bản cũ.
- **Xoay vòng trên R2:** cổng **không** xoá gì trên R2 (`BACKUP_KEEP` chỉ áp cho volume local). Đặt **lifecycle rule** cho bucket (vd xoá object sau 90 ngày) để bucket không phình mãi.
- **Nội dung:** bản dump **không mã hoá** và chứa dữ liệu khách hàng (tên, SĐT, đơn hàng, sổ quỹ). Để bucket riêng tư, không bật public access.

> ⚠️ **Không có biến nào tắt cổng.** Backend không lên vì sao lưu hỏng: `docker compose stop backend` (thôi vòng thử lại), đọc `docker compose logs backend`, xử lý nguyên nhân (giải phóng đĩa…) rồi `docker compose up -d` lại. Đừng tìm cách vòng qua — đó là bản sao duy nhất trước một thay đổi một chiều.

**Xem các bản đang có:**

```bash
cd ~/fnberp
docker compose exec backend ls -lh /backups
```

### Khôi phục một bản dump xuống Postgres 17 (máy local)

Nguồn cho diễn tập "local trước": khôi phục bản sao của quán xuống máy local, chạy migration, E2E xanh rồi mới lên lịch cho máy quán.

Dump dạng `-Fc` (custom) — **phải** khôi phục bằng `pg_restore` **major 17** (bản 15/16 không đọc được). Không cần cài Postgres 17 lên máy: chạy trong container.

```bash
# 1. Trên máy quán: chép thư mục backups ra ngoài (chạy được cả khi backend đang dừng)
cd ~/fnberp
docker compose cp backend:/backups ~/trcf-backups
# 2. Mang tệp về máy local (vd: scp quan:~/trcf-backups/trcf_erp-<ts>.dump .)
# 3. Trên máy local: Postgres 17 tạm, cổng 55432
docker run -d --name trcf-restore -e POSTGRES_USER=trcf -e POSTGRES_PASSWORD=restore \
  -p 55432:5432 postgres:17-alpine
docker cp trcf_erp-<ts>.dump trcf-restore:/tmp/restore.dump
docker exec trcf-restore createdb -U trcf trcf_restore
docker exec trcf-restore pg_restore -U trcf --no-owner --no-privileges --exit-on-error \
  -d trcf_restore /tmp/restore.dump
# 4. Trỏ backend dev vào đó:
#    DATABASE_URL=postgresql://trcf:restore@localhost:55432/trcf_restore
```

*(`createdb`/`pg_restore` có thể phải chờ vài giây sau `docker run` để Postgres khởi động xong. Bài diễn tập `trcf_erp_backend/scripts/backup-gate-drill.sh` chạy đúng hai lệnh `createdb` + `pg_restore` này và so số bảng với nguồn.)*

> ⚠️ **Tuyệt đối không chạy `docker compose down -v`** — cờ `-v` xoá volume = **mất toàn bộ dữ liệu**.

---

## 9. Cấu trúc thư mục cài

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

## 10. Gặp sự cố

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
| `no matching manifest for linux/arm64` | Máy chạy chip **ARM** — bản phần mềm hiện chỉ cho **x86_64/amd64** (kiểm tra: `uname -m`). Dùng máy chủ x86_64, hoặc báo nhà cung cấp cần bản ARM. |

Cần hỗ trợ: gửi kèm kết quả của

```bash
cd ~/fnberp && docker compose ps && docker compose logs --tail=100
```

---

## 11. Cài thủ công (không dùng script)

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
