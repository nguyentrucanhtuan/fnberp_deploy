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

### Múi giờ quán — ba luật

Máy chủ lưu **mốc thời gian tuyệt đối**; múi giờ quán (`general.timezone`, tên vùng
IANA như `Asia/Ho_Chi_Minh`) chỉ là "kính lúp" quyết định **ngày nào là hôm nay** trong báo
cáo, biên lọc theo ngày của các màn (đơn hàng, sổ quỹ, kho, sản xuất…) và giờ in trên bill.
Giờ của container/máy chủ (`TZ`) **không** được dùng vào việc này — nhưng **đừng đặt `TZ`**
cho container `backend` hay `postgres`. Quán chưa chạy
[`TimestamptzEverywhere1783741000000`](#ví-dụ-đầu-tiên--timestamptzeverywhere1783741000000-đổi-mọi-cột-giờ-sang-timestamptz)
còn cột giờ lưu **giờ treo tường không múi giờ**: chúng chỉ đọc đúng khi backend và Postgres
**cùng chạy UTC** (mặc định của ảnh). Đặt `TZ=Asia/Ho_Chi_Minh` cho một bên là mọi biên lọc
theo ngày lệch 7 giờ mà **không báo lỗi gì**.

1. **Đặt múi giờ lúc mở quán, rồi đừng đổi.** Đổi `general.timezone` về sau làm **ngày cũ
   dịch chỗ** trong báo cáo (một đơn 23:30 có thể nhảy sang ngày hôm sau), trong khi những thứ
   đã chốt **không dịch theo**: snapshot đóng ca và hoá đơn GTGT đã phát hành giữ nguyên con
   số lúc chốt. Báo cáo và chứng từ sẽ lệch nhau. ⇒ Chỉ đổi để **sửa khai sai**, và sửa **càng
   sớm càng tốt** (ít ngày cũ phải dịch). Đọc giá trị đang dùng:

   ```bash
   docker compose exec -T postgres psql -U trcf trcf_erp -c \
     "SELECT value FROM system_settings WHERE module = 'general' AND key = 'timezone'"
   ```

   Đổi đúng cách: vào màn **Cấu hình** (tài khoản superuser), chọn múi giờ rồi lưu — backend
   nạp lại múi giờ ngay khi lưu. Sửa thẳng `system_settings` bằng SQL thì backend **không biết**:
   nó vẫn dùng giá trị cũ trong bộ nhớ cho tới khi khởi động lại (`docker compose restart
   backend`).

2. **Nâng Node là nghĩa vụ bảo trì.** Backend đọc luật múi giờ (kể cả giờ mùa hè) qua `Intl`,
   mà `Intl` dùng bảng ICU **nhúng trong bản Node** của ảnh — KHÔNG đọc `/usr/share/zoneinfo`.
   Khi một nước đổi luật giờ, cài `tzdata` **không cứu được**: phải cập nhật lên ảnh có Node
   mới hơn. Quán Việt Nam (không có giờ mùa hè) thì vô hại; quán ở vùng có đổi giờ phải theo
   dõi. Xem bản dữ liệu múi giờ đang chạy:

   ```bash
   docker compose exec -T backend node -p process.versions.tz
   ```

3. **Chưa nhận quán ngoài UTC+7.** Frontend (khoảng 40 màn) còn định dạng giờ theo **múi giờ
   của trình duyệt** chứ chưa theo `general.timezone`. Ở Việt Nam hai thứ trùng nhau nên đúng;
   quán ở múi giờ khác sẽ thấy giờ hiển thị lệch với giờ in/báo cáo. Chưa mở bán cho quán
   ngoài UTC+7 cho tới khi frontend được sửa.

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

#### Ví dụ đầu tiên — `TimestamptzEverywhere1783741000000` (đổi mọi cột giờ sang `timestamptz`)

Đổi **mọi** cột `timestamp without time zone` sang `timestamptz` bằng một nhánh `AT TIME ZONE 'UTC'` — dữ liệu không đổi giá trị (mốc tuyệt đối giữ nguyên), chỉ đổi kiểu. Trên bản sao Coffeetree 27/09: 75 cột, **0,5 s** phần migrate, **0,8 s** kể cả sao lưu. Migration **dừng trước khi đổi bất cứ gì** nếu một trong các điều sau chưa đạt:

- quán **chưa có** `general.timezone`, hoặc giá trị không phải tên vùng IANA sạch (khoảng trắng thừa, `+07:00`, `Etc/GMT-7`, tên Postgres/Node không biết) — không có giá trị mặc định;
- chấm công (`attendance.check_in/check_out`) chưa là `timestamptz` (migration 31/08 chưa chạy);
- có dòng mà giờ lưu lệch **> 1 giờ** so với mốc đối chiếu độc lập (giờ tạo đơn ↔ giờ đơn, bút toán thu ↔ giờ đơn, giờ mở ca ↔ giờ ghi ca, ngày trong mã `PO`/`MO`/`CK` ↔ giờ tạo).

**1. Đặt ĐÚNG múi giờ quán TRƯỚC.** ⚠️ Lần khởi động đầu tiên của ảnh mới **tự gieo** `general.timezone = 'Asia/Ho_Chi_Minh'` cho mọi quán còn thiếu dòng này (dữ liệu mẫu của Cấu hình). Quán ở Việt Nam thì không cần làm gì thêm ngoài đọc lại; quán **không** ở Việt Nam phải đặt đúng vùng **trước cửa sổ** — nếu không migration sẽ chạy với giờ Việt Nam. Ghi đè (chạy lặp được) rồi đọc lại:

```bash
docker compose exec -T postgres psql -U trcf trcf_erp -c \
  "INSERT INTO system_settings (module, key, value, value_type, description)
   VALUES ('general', 'timezone', 'Asia/Ho_Chi_Minh', 'str', 'Múi giờ quán (IANA) — đặt lúc mở quán')
   ON CONFLICT (module, key) DO UPDATE SET value = EXCLUDED.value"
docker compose exec -T postgres psql -U trcf trcf_erp -c \
  "SELECT value FROM system_settings WHERE module = 'general' AND key = 'timezone'"
```

(Thay `'Asia/Ho_Chi_Minh'` bằng vùng của quán, vd `'Asia/Bangkok'`.)

**2. Kiểm trước-khi-bay — chỉ đọc**, chạy được cả lúc quán đang bán (nên chạy vài ngày trước cửa sổ):

```bash
docker compose run --rm --no-deps backend node dist/timestamptz-preflight
```

Thoát 0 + `✅ Sạch` ⇒ lên lịch cửa sổ. Thoát 1 ⇒ đọc từng điều chặn: thiếu/sai múi giờ thì ghi đè bằng lệnh ở bước 1; dòng lệch mốc thì lệnh in tên phép (`orders-created`, `journal-order-payment`, `pos-session-start`, `code-date:<bảng>`) và tối đa 20 dòng `id` + hai giá trị — **soi tay từng dòng**. Dòng nào đúng là dữ liệu thật (vd phiếu nhập ghi ngày khác ngày tạo), liệt kê để bỏ qua:

```bash
docker compose run --rm --no-deps -e TIMESTAMPTZ_PREFLIGHT_ACCEPT="orders-created:170,code-date:purchases:12" \
  backend node dist/timestamptz-preflight
```

Dòng đã liệt kê được **in ra** là "đã chấp nhận sau khi soi tay"; gõ sai khuôn (`<phép>:<id>`) thì lệnh dừng. Dòng lệch vì dữ liệu hỏng thì sửa dữ liệu, đừng liệt kê. Riêng dòng `code-date:*` có giờ tạo trong khoảng **01:00–07:00 giờ quán** là hệ quả của mã phiếu mang ngày **UTC** (bộ sinh mã `PO`/`MO`/`CK` đọc đồng hồ container chạy UTC) — dữ liệu đúng: soi lại rồi đưa vào `TIMESTAMPTZ_PREFLIGHT_ACCEPT`.

**3. Trong cửa sổ** — các bước ở trên, cùng biến `-e TIMESTAMPTZ_PREFLIGHT_ACCEPT=…` nếu bước 2 cần:

```bash
docker compose stop backend
docker compose run --rm --no-deps backend node dist/oneway-migrate TimestamptzEverywhere1783741000000
# bước 2 cần ACCEPT thì thay dòng trên bằng (cùng danh sách đã soi tay):
# docker compose run --rm --no-deps -e TIMESTAMPTZ_PREFLIGHT_ACCEPT="orders-created:170" \
#   backend node dist/oneway-migrate TimestamptzEverywhere1783741000000
docker compose up -d backend
```

Log in danh sách từng `bảng.cột` sẽ đổi, kết quả kiểm trước, rồi **kiểm lại sau trong cùng transaction** (đếm cột trần = 0, checksum giá trị từng cột trước = sau, chấm công không đổi, mốc đối chiếu vẫn 0 lệch) — sai ⇒ rollback cả lô. Danh sách cột đã đổi lưu ở `migration_oneway.timestamptz_552_columns`; `--down` chỉ đảo đúng các cột đó rồi xoá bảng này.

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

#### Triển khai pha 1 ở một quán (552.4) — `TimestamptzEverywhere1783741000000`

Thứ tự bắt buộc: **Coffeetree trước**, chạy **trọn 7 ngày không sự cố** rồi mới tới ba quán khách, **từng quán một**. Mỗi quán đi đủ chuỗi dưới; ghi từng ô vào sổ `specs/055-saas/trien-khai-pha-1.md` (repo umbrella `fnberp_fullstack`). Quán nào dừng ở bước nào thì **không đi tiếp** bước sau ở quán đó.

**0. Điều kiện trước khi lên lịch** — cả bốn phải đạt:

- Quán khách: Coffeetree đã đủ 7 ngày không sự cố (mục 5). Coffeetree: tệp mốc gốc đã chép lên máy và `sha256sum` khớp (bước 1).
- Cửa sổ **ngoài giờ bán**, trần **30 phút** từ `stop backend` tới `up -d backend`. Bản sao Coffeetree đo: runner 0,5 s (0,8 s kể cả sao lưu), báo cáo + cửa vài giây mỗi lệnh.
- **Diễn tập trọn chuỗi trên bản sao dump của CHÍNH quán đó** (không dùng bản sao Coffeetree thay cho quán khách) — trên máy local, trong `trcf_erp_backend/`. Dump lấy theo [§8](#khôi-phục-một-bản-dump-xuống-postgres-17-máy-local). Quán khách chưa có mốc gốc thì chụp một lần từ bản sao đã khôi phục (Postgres 17 tạm cổng 55432 như §8), rồi chạy diễn tập với chính tệp đó:

  ```bash
  BASELINE_DATABASE_URL=postgresql://trcf:restore@localhost:55432/trcf_restore \
    node_modules/.bin/ts-node scripts/baseline-report.ts --until <ngày chụp dump> --out ../_bmad-output/implementation-artifacts/baseline-<quán>-<ngày>.json
  DRILL_SOURCE_DUMP=<quán>.dump BASELINE_FILE=../_bmad-output/implementation-artifacts/baseline-<quán>-<ngày>.json \
    BASELINE_UNTIL=<ngày chụp dump> bash scripts/timestamptz-rehearsal.sh
  ```

  **Qua** = dòng cuối `Tất cả PASS`; ghi thời gian runner (`thời gian runner up: …`). Đỏ ⇒ không lên lịch quán đó. (Coffeetree: `bash scripts/timestamptz-rehearsal.sh` — nguồn mặc định là bản sao 27/09, mốc gốc `baseline-055-2026-09-27.json`.) Diễn tập giả định quán ở `Asia/Ho_Chi_Minh`.
- **Lưới hồi quy xanh trên cùng bản sao đó** (mã mới, schema cũ). Lưới ghi dòng `RG551` vào sổ quỹ/kho nên **không bao giờ chạy lên DB quán** — chỉ lên bản sao khôi phục vào một database tên kết thúc `_test`:

  ```bash
  E2E_REUSE_DATABASE=1 TEST_DATABASE_URL=postgresql://…/<quán>_copy_test \
    npx jest --config ./test/jest-e2e.json test/regression-grid.e2e-spec.ts
  ```

  **Qua** = mọi ca xanh. Dữ liệu gốc lệch (Σ moves ≠ quants, bút toán mồ côi) làm lưới đỏ từ luồng ① — xử lý dữ liệu quán trước, không mở cửa sổ.

**1. Ghim ảnh (chỉ Coffeetree, lúc mã pha 1 chưa vào `main`) — đây là một lần DEPLOY THẬT.** Ảnh nhánh được build bằng cách bấm tay workflow trên nhánh — mang tag theo nhánh (vd `feat-055-saas`) và tag commit `sha-<7 ký tự>`, **không** đè `latest`. **Ghim bằng tag `sha-…`** (bất biến): tag nhánh đổi mỗi lần bấm lại workflow, mà compose có `pull_policy: always` ⇒ ghim tag nhánh là Coffeetree kéo mã mới giữa 7 ngày. Trên máy Coffeetree:

```bash
cd ~/fnberp
printf '\nBACKEND_IMAGE_TAG=sha-<commit>\n' >> .env   # chỉ backend; frontend vẫn theo IMAGE_TAG
docker compose config --images                  # kiểm: backend …:sha-<commit>, frontend như cũ
docker compose pull backend && docker compose up -d backend
docker compose logs backend | grep -E "Đã sao lưu và kiểm đọc lại được|Migration MỘT CHIỀU đang chờ|Backend đang chạy"
docker inspect --format '{{index .RepoDigests 0}}' ghcr.io/nguyentrucanhtuan/trcf-erp-backend:sha-<commit>   # digest → sổ
```

(`printf` có `\n` đầu để không dán vào dòng cuối khi `.env` không kết thúc bằng xuống dòng.) Ảnh nhánh mang **migration thường mới** của nhánh ⇒ lần `up -d` này chạy chúng, vài ngày trước cửa sổ:

- Cổng sao lưu 551.1 tự chụp dump **trước** các migration đó — chép đường tệp ở dòng `Đã sao lưu và kiểm đọc lại được: /backups/trcf_erp-<ts>.dump` vào sổ (kèm tag `sha-…` + digest).
- **Qua** = log có `Backend đang chạy` + cảnh báo `Migration MỘT CHIỀU đang chờ … TimestamptzEverywhere1783741000000`, rồi **bán một đơn thử** trên màn bán hàng (thu tiền, in bill) và thấy nó ở màn Đơn hàng.
- **Không qua ⇒ lùi**: [quay về đúng dump đó](#đứt-giữa-chừng--mất-điện-đứt-ssh-tiến-trình-bị-giết) **và** gỡ dòng `BACKEND_IMAGE_TAG` khỏi `.env` rồi `docker compose up -d backend`. Chỉ gỡ dòng mà không quay về dump là không đủ — ảnh cũ không chạy được trên schema đã nhận migration thường mới.

Ba quán khách không có dòng đó nên vẫn ở `latest`. `install … --update` chỉ sửa `IMAGE_TAG`, không đụng `BACKEND_IMAGE_TAG` — **gỡ dòng này** khi nhánh đã vào `main` (nếu không, quán sẽ đứng yên ở ảnh đã ghim).

**Chép tệp mốc gốc lên máy Coffeetree** (trước ngày chạy — bước 3c cần): tệp `_bmad-output/implementation-artifacts/baseline-055-2026-09-27.json` của repo umbrella, đặt ở `~/baseline-055-2026-09-27.json`, rồi kiểm:

```bash
sha256sum ~/baseline-055-2026-09-27.json
# phải ra đúng: 56a0418ecc9641b9347bace4e78d5798083267dee94c827c44406f5e6c09fe8a
```

Lệch ⇒ chép lại. Ghi giá trị vào sổ.

**2. Vài ngày trước cửa sổ** — đặt/đọc lại múi giờ (bước 1 của ví dụ trên) rồi kiểm trước-khi-bay chỉ-đọc (bước 2 ở trên):

```bash
docker compose run --rm --no-deps backend node dist/timestamptz-preflight
```

**Qua** = thoát 0, `✅ Sạch` (có thể kèm `TIMESTAMPTZ_PREFLIGHT_ACCEPT` đã soi tay — ghi danh sách vào sổ; **cùng danh sách đó** phải truyền cho runner ở 3b, gate ở 3c và kiểm hằng ngày ở mục 5). Không qua ⇒ không lên lịch.

**3. Trong cửa sổ** — trong `tmux`, **đúng thứ tự**, ghi giờ bắt đầu:

```bash
tmux new -s phase1
cd ~/fnberp
docker compose stop backend
# a. Báo cáo TRƯỚC — ghi vào volume backups (không đè tệp có sẵn). --until: hôm qua.
#    Coffeetree: --until 2026-09-27 (để so được với mốc gốc ở bước c).
docker compose run --rm --no-deps backend node dist/baseline-report \
  --until <YYYY-MM-DD> --out /backups/phase1-before-<ngày>.json
# b. Migration tay (cùng -e TIMESTAMPTZ_PREFLIGHT_ACCEPT=… nếu bước 2 cần) — chụp dump + đổi cột
docker compose run --rm --no-deps backend node dist/oneway-migrate TimestamptzEverywhere1783741000000
# c. CỬA — chỉ đọc. Bước 2 cần ACCEPT ⇒ thêm đúng `-e TIMESTAMPTZ_PREFLIGHT_ACCEPT="…"` như (b)
#    ngay sau `run --rm --no-deps`, nếu không `reference-checks` FAIL oan. Quán khách:
docker compose run --rm --no-deps backend node dist/phase1-gate --before /backups/phase1-before-<ngày>.json
#    Coffeetree: thêm mốc gốc 27/09 — kiểm tệp có thật TRƯỚC (thiếu tệp thì `-v` tạo thư
#    mục rỗng và gate thoát 2 giữa cửa sổ):
[ -f ~/baseline-055-2026-09-27.json ] && sha256sum ~/baseline-055-2026-09-27.json   # = 56a0418e…fe8a (bước 1)
docker compose run --rm --no-deps -v ~/baseline-055-2026-09-27.json:/ref/baseline-055.json:ro \
  backend node dist/phase1-gate --before /backups/phase1-before-<ngày>.json --reference /ref/baseline-055.json
# d. CHỈ KHI c thoát 0:
docker compose up -d backend
```

- (a) **Qua** = in 6 hash + `→ /backups/phase1-before-<ngày>.json`. `tz` mặc định là `general.timezone` của quán; thiếu/sai múi giờ ⇒ thoát 1 với câu nêu cách đặt. Tệp đã có ⇒ thoát 1, không ghi — đặt tên khác.
- (b) **Qua** = `✅ Đã chạy … trong X s`. Chép dòng `Đã sao lưu và kiểm đọc lại được: /backups/trcf_erp-<ts>.dump` vào sổ — đó là dump để quay về. Thoát 1 ⇒ schema nguyên, `docker compose up -d backend` rồi điều tra (quán vẫn bán trên schema cũ).
- (c) In mỗi phép một dòng `PASS|FAIL <tên> — <chi tiết>`: `naive-columns` (0 cột trần) · `oneway-applied` · `attendance-instant` · `timezone` · `reference-checks` (mốc đối chiếu chạy lại **sau** migration) · `same-day-0030` (bút toán thu ↔ đơn, giờ mở ca ↔ giờ ghi ca cùng ngày giờ quán) · `baseline-before-after` (doanh thu · tồn · quỹ · điểm = báo cáo trước; số dòng chỉ khác ở bảng `migrations`, và bảng đó **phải tăng** — `--before` chụp sau runner thì FAIL; cùng database) · `baseline-reference` (chỉ khi có `--reference`: doanh thu theo ngày = mốc gốc). Phép 7/8 chứng minh **số nghiệp vụ không đổi và không có ghi chen giữa hai lần chụp** — KHÔNG chứng minh migration quy đổi đúng nhánh (bốn hash không đọc cột nào migration đổi). Đúng nhánh do checksum từng cột trong chính transaction migration (b) + phép `reference-checks`/`same-day-0030` bảo đảm. **Qua** = thoát 0, dòng cuối `✅ Cửa pha 1: 7/7 PASS` (Coffeetree `8/8`). Thoát 2 = gõ sai tham số hoặc tệp báo cáo hỏng — sửa lệnh, chạy lại (chưa phải kết luận).
- (c) thoát 1 ⇒ **KHÔNG** `up -d backend`. Lùi ngay, lúc cửa `--down` còn mở (trước bước d):

  ```bash
  docker compose run --rm --no-deps backend node dist/oneway-migrate --down TimestamptzEverywhere1783741000000
  docker compose up -d backend
  ```

  `--down` hỏng ⇒ [quay về dump](#đứt-giữa-chừng--mất-điện-đứt-ssh-tiến-trình-bị-giết) đúng tệp đã chép ở (b). Ghi sự cố (mục 5).

- Riêng Coffeetree: `baseline-reference` FAIL với chi tiết `đã lệch từ --before` mà `baseline-before-after` PASS ⇒ migration không đổi số; doanh thu 29/08–27/09 đã đổi **trước** cửa sổ (đơn tháng 9 bị hoàn/sửa sau ngày chụp mốc gốc). Vẫn là FAIL — **không tự `up`**: báo người phụ trách, người đó quyết (ghi sổ) trong trần 30 phút; không quyết kịp ⇒ `--down` như trên.

Cửa (c) chạy lại được bao nhiêu lần cũng được (không ghi gì). Chạy khi backend **đang bán** thì `baseline-before-after` đỏ vì có đơn mới — chỉ tin kết quả trong cửa sổ.

**4. Ghi sổ** — mỗi ô của quán trong `specs/055-saas/trien-khai-pha-1.md`: kết quả preflight, diễn tập bản sao (thời gian runner), lưới bản sao, giờ cửa sổ, tệp dump, thời gian runner, gate (7/7 hoặc 8/8), hash trước/sau, ngày bắt đầu đếm 7 ngày. Dán nguyên dòng in ra — không điền số ước.

**5. Luật 7 ngày và sự cố.** Ngày 1 là ngày sau cửa sổ đã `up -d backend` với gate PASS. Mỗi ngày trong 7 ngày, chạy kiểm chỉ-đọc (dữ liệu mới vẫn phải khớp mốc đối chiếu):

```bash
docker compose run --rm --no-deps backend node dist/timestamptz-preflight
# bước 2 có ACCEPT ⇒ cùng danh sách:
# docker compose run --rm --no-deps -e TIMESTAMPTZ_PREFLIGHT_ACCEPT="…" backend node dist/timestamptz-preflight
```

(`code-date:*` có giờ tạo 01:00–07:00 giờ quán là mã mang ngày UTC — đã biết, xem bước 2 ở trên.) **Sự cố** là một trong các việc sau:

- gate thoát 1 ở cửa sổ, hoặc phải `--down` / quay về dump;
- kiểm hằng ngày báo `timestamp without time zone` ≠ 0 hoặc dòng lệch mốc đối chiếu mới (ngoài `code-date` khung 01:00–07:00);
- một đơn / bút toán / ca nằm hai ngày khác nhau giữa các màn (Đơn hàng, Tổng quan, Sổ quỹ, Ca), hoặc tổng ngày của hai màn khác nhau;
- bảng công dịch giờ (giờ vào/ra lệch so với máy chấm công);
- backend không khởi động, hoặc lỗi 5xx ở màn có lọc ngày;
- chủ quán báo số tiền ngày/ca không khớp két mà nguyên nhân là ngày/giờ.

Có sự cố ⇒ (1) **không** sang quán khách; (2) lùi quán đó (`--down` nếu cửa còn mở, không thì quay về dump — mất đơn sau giờ dump, cân nhắc với chủ quán); (3) ghi vào bảng nhật ký sự cố của sổ + một dòng `NHAT-KY.md`; (4) sửa, diễn tập lại trên bản sao, mở cửa sổ mới và **đếm lại 7 ngày từ đầu**.

#### Triển khai pha 2 ở một quán (553.6) — năm migration một chiều 553.2–553.5

> ⛔ **CHƯA DÙNG ĐƯỢC NGUYÊN VĂN — chờ vá trước cửa sổ pha 2 đầu tiên** (review 28/09, retro 553 mục 12). Ba lỗi high:
> ① `BACKUP_KEEP` mặc định 5 ⇒ lượt thứ sáu (chạy lại / chia cửa sổ) xoá mất dump BIG — đường lùi duy nhất;
> ② kiểm log `grep '2350[235]'` không bao giờ bắt được gì (app không in SQLSTATE ra log);
> ③ lùi bằng "xoá dòng tag" có thể kéo ảnh pha 2 (`latest` + `pull_policy: always`).
> Cùng ba lỗi vừa: fingerprint preflight còn tuỳ chọn · khối khôi phục chung với pha 1 `up` backend trước khi trả tag · thiếu kiểm đĩa cho 5 dump. **Không lên lịch cửa sổ tới khi khối cảnh báo này được gỡ.**

Pha 2 gắn `shop_id` vào mọi bảng nghiệp vụ. Nó gồm **năm** migration một chiều, chạy tay **đúng thứ tự** trong **một** cửa sổ:

1. `BigintLargeTables1783741100000` (BIG) — lô kèm `CreateShops1783740950000` nếu ảnh pha 1 của quán chưa có nó.
2. `AddShopIdColumns1783741200000` (SHOP).
3. `CompositeKeys1783741400000` (CK) — lô kèm rào thường `ShopIdFence1783741300000`.
4. `ExternalRefsAndZaloAppShops1783741500000` (ER).
5. `TenantScopedUniques1783741600000` (TU) — lô kèm rào thường `ExternalRefFence1783741550000`.

Thứ tự quán như pha 1: **Coffeetree trước**, chạy **trọn 7 ngày không sự cố**, rồi tới ba quán khách, **từng quán một**. Ghi từng ô vào sổ `specs/055-saas/trien-khai-pha-2.md` (repo umbrella `fnberp_fullstack`). Quán nào dừng ở bước nào thì **không đi tiếp** ở quán đó.

> ⚠️ **Ảnh pha 2 CHỈ đổi TRONG cửa sổ.** Khác pha 1: ảnh pha 2 **không khởi động được** trên schema trước pha 2. E-18 từ chối vì rào `ShopIdFence` đứng sau migration một chiều chưa chạy; diễn tập đo được câu `Cần chạy tay BigintLargeTables1783741100000 trước`. "Ghim ảnh rồi `up -d` vài ngày trước" như pha 1 là **dừng bán ngay**. Trước cửa sổ chỉ làm hai việc: `docker pull` ảnh theo tag, và chạy preflight bằng `BACKEND_IMAGE_TAG=… docker compose run --rm …`. **Không sửa `.env`, không `up`.**

> ⚠️ **Đường lùi ở máy quán là DUMP của lượt runner đầu tiên.** Sau khi đã qua `TenantScopedUniques`, `--down` chỉ đảo được **đúng nó**: rào `ExternalRefFence` là dòng `migrations` mới hơn ER, và ảnh **không** chạy được `migration:revert` để gỡ rào (thiếu `dotenv`, xem mục "Đảo bằng `down()`" ở trên). Lùi sâu hơn thì phải làm đủ hai việc: **quay về dump của lượt runner đầu tiên** (BIG — chụp ngay trước khi pha 2 đổi gì), **và** trả `BACKEND_IMAGE_TAG` về tag pha 1. Diễn tập đã đo đúng điều này: `--down ExternalRefsAndZaloAppShops…` bị từ chối (`không phải dòng mới nhất`) khi rào còn.

**Chia cửa sổ.** Nhỏ nhất là {BIG, SHOP, CK, ER} | {TU}. Ảnh pha 2 boot được khi **chỉ còn TU** chờ: boot tự chạy rào `ExternalRefFence` (có cổng sao lưu chụp trước) và log `Migration MỘT CHIỀU đang chờ … TenantScopedUniques1783741600000`. Nó **không** boot được khi ER còn chờ (E-18 nêu `ExternalRefsAndZaloAppShops1783741500000`). Cả hai điều này đã thử trên bản chép giữa chừng trong diễn tập, kèm cửa sổ 2 (`oneway-migrate TenantScopedUniques…` rồi `phase2-gate --schema-only` ⇒ 0). Chỉ chia khi **tổng đo được** ở diễn tập của quán vượt 30′ — **không nới trần**. Diễn tập dev trên bản sao Coffeetree 27/09 đo **1,7–2,0 s** cho cả năm lượt (kể cả sao lưu), ước cửa sổ **4,5 s**, nên một cửa sổ là đủ. Nếu chia:

- cuối cửa sổ 1 (sau ER, trước `up -d backend`) chạy `node dist/phase2-gate --before /backups/phase2-before-<ngày>.json` (Coffeetree thêm `--reference`). Cửa sổ 1 **qua** khi lệnh thoát 1 và FAIL **đúng hai** phép `oneway-applied` + `tenant-uniques` (TU chưa chạy), mọi phép khác PASS — kể cả `baseline-before-after`. Chỉ khi đó mới `up -d backend`; FAIL phép nào khác ⇒ đường lùi như cửa (d) thoát 1;
- cửa sổ 2 chụp `--before` mới ngay trước lượt TU, rồi chạy cửa đầy đủ.

**0. Điều kiện trước khi lên lịch** — cả năm phải đạt:

- **Cửa 552 đã xanh ở CẢ BỐN quán** (sổ `trien-khai-pha-1.md`: 7 ngày của Coffeetree + gate của ba quán khách). Pha 2 không bắt đầu ở quán nào khi còn một quán chưa qua pha 1.
- **CI "Lưới hồi quy" xanh trên đúng commit của ảnh.** Trên GitHub → `trcf_erp_backend` → Actions → `Regression grid`, lượt chạy của đúng commit `<p2>` mà tag `sha-<p2>` trỏ tới phải xanh. Ghi URL lượt chạy vào sổ.
- **Diễn tập pha 2 trên bản sao dump MỚI của CHÍNH quán đó — kể cả Coffeetree** (trên máy local, trong `trcf_erp_backend/`). Dump phải lấy **sau** khi quán đã qua pha 1 (diễn tập tự bỏ bước pha 1 khi nguồn đã áp), để catalog, fingerprint và các migration thường còn chờ trong diễn tập đúng bằng quán thật. Quán khách chụp mốc gốc một lần từ bản sao đã khôi phục, như bước 0 của pha 1:

  ```bash
  DRILL_SOURCE_DUMP=<quán>.dump BASELINE_FILE=../_bmad-output/implementation-artifacts/baseline-<quán>-<ngày>.json \
    BASELINE_UNTIL=<ngày chụp dump> bash scripts/phase2-rehearsal.sh
  ```

  Coffeetree: `DRILL_SOURCE_DUMP=<coffeetree-sau-pha-1>.dump bash scripts/phase2-rehearsal.sh` — `BASELINE_FILE` để mặc định (`baseline-055-2026-09-27.json`, `--until 2026-09-27` vẫn đúng cho Coffeetree). Chạy **không** `DRILL_SOURCE_DUMP` thì nguồn là `ct_pristine` (bản sao 27/09, TRƯỚC pha 1, diễn tập tự áp pha 1) — đó chỉ là diễn tập của máy dev; fingerprint của nó **không** dùng ở quán.

  **Qua** khi dòng cuối là `Tất cả PASS`. Chép vào sổ năm dòng `thời gian up …` (migrate + tổng kể cả sao lưu), dòng tổng, và dòng `Fingerprint trước pha 2: <hash>`. Bước 2 dùng hash đó.
- **Tổng thời gian dưới 30′.** Diễn tập in sẵn dòng `ước cửa sổ (up + báo cáo + cửa + boot)`: năm lượt up (kể cả sao lưu) + báo cáo trước + cửa + boot, tất cả đo trên chính bản sao, và tự kiểm < 1800 s. Vượt 30′ ⇒ chia cửa sổ như trên.
- **Lưới bản sao xanh.** Đây là bước 12 của diễn tập: `regression-grid` chạy trên bản sao đã áp năm migration, dòng `PASS lưới hồi quy: jest thoát 0`. Lưới **không bao giờ** chạy lên DB quán.

**1. Build + kéo ảnh (KHÔNG `up`).** Bấm tay workflow `Build & Push Backend Image` trên nhánh. Nó đẩy tag `sha-<7 ký tự>`, không đè `latest`. Trên máy quán:

```bash
cd ~/fnberp
docker pull ghcr.io/nguyentrucanhtuan/trcf-erp-backend:sha-<p2>
docker inspect --format '{{index .RepoDigests 0}}' ghcr.io/nguyentrucanhtuan/trcf-erp-backend:sha-<p2>   # digest → sổ
grep '^BACKEND_IMAGE_TAG=' .env    # tag pha 1 đang chạy → sổ (đường lùi); không có dòng ⇒ ghi "không có"
```

**Qua** khi `pull` xong và digest đã ghi. **Không** sửa `.env`, **không** `up`: quán vẫn bán trên ảnh pha 1.

**2. Vài ngày trước cửa sổ — kiểm trước-khi-bay, chỉ đọc.** Lệnh chạy được cả lúc quán đang bán. Ảnh pha 2 chạy trong một container dùng-một-lần; container backend đang bán không đổi:

```bash
BACKEND_IMAGE_TAG=sha-<p2> docker compose run --rm --no-deps backend \
  node dist/phase2-preflight --expect-fingerprint <hash của diễn tập>
```

Mỗi phép in một dòng `PASS|FAIL <tên> — <chi tiết>`:

- `server-version` — Postgres ≥ 15.
- `phase1-applied` — có dòng `TimestamptzEverywhere…` và 0 cột trần.
- `phase2-not-started` — chưa có dòng nào của pha 2.
- `shops` — bảng chưa có, hoặc có đúng quán `id = 1`.
- `unique-inventory` — mọi ràng buộc duy nhất đều thuộc kế hoạch 553.5 hoặc là khoá toàn cục. Unique lạ là thứ sẽ làm `TenantScopedUniques` ném **giữa** cửa sổ.
- `catalog-fingerprint` — hash của bảng, cột, ràng buộc, chỉ mục bằng hash của diễn tập. Nghĩa là cửa sổ sẽ gặp đúng catalog đã diễn tập, nên các tiền kiểm **cấu trúc/catalog** của năm migration không thể lần đầu ném ở quán. Fingerprint **không** nhìn dữ liệu — tiền kiểm dữ liệu kiểm riêng dưới đây.

**Qua** khi thoát 0 và dòng cuối là `✅ Kiểm trước pha 2: 6/6 PASS`.

- **Không qua ⇒ không lên lịch.**
- `catalog-fingerprint` lệch ⇒ schema quán đã khác bản đã diễn tập. Lấy dump mới của quán, chạy lại diễn tập trên dump đó, rồi dùng hash mới.
- `unique-inventory` FAIL nêu `lạ: <bảng>.<tên>` ⇒ phải phân loại ràng buộc đó trong mã (553.5) và build ảnh mới. Không xoá tay ở quán.
- `phase2-not-started` FAIL ⇒ pha 2 đã chạy dở hoặc xong ở quán này. Dùng `phase2-gate` và mục [Đứt giữa chừng](#đứt-giữa-chừng--mất-điện-đứt-ssh-tiến-trình-bị-giết). Phép `unique-inventory` khi đó in `SKIP`.

Thoát 2 là gõ sai tham số: sửa lệnh rồi chạy lại.

Cùng lúc, chạy một kiểm dữ liệu chỉ-đọc cho `ExternalRefsAndZaloAppShops` (nó ném nếu ô `zalo.app_id` dài quá 64 ký tự):

```bash
docker compose exec -T postgres psql -U trcf trcf_erp -c \
  "SELECT id, length(btrim(value)) FROM system_settings WHERE module='zalo' AND key='app_id' AND length(btrim(value)) > 64"
```

**Qua** khi ra **0 dòng**. Tiền tố `ref_code` suy từ tên/slug quán đã được diễn tập trên dump mới của quán (bước 0) bảo đảm — tên quán đổi sau ngày chụp dump ⇒ lấy dump mới và diễn tập lại.

**Coffeetree — chép mốc gốc** lên `~/baseline-055-2026-09-27.json` rồi kiểm lại, như bước 1 của pha 1 (`sha256sum` phải ra `56a0418ecc9641b9347bace4e78d5798083267dee94c827c44406f5e6c09fe8a`). Tệp đã có từ pha 1 thì chỉ cần kiểm lại.

**3. Trong cửa sổ** — ngoài giờ bán, trần **30 phút** tính từ `stop backend` tới `up -d backend`. Chạy trong `tmux`, **đúng thứ tự**, ghi giờ bắt đầu. **Dừng ở lệnh đầu tiên không qua**, rồi đi đường lùi bên dưới.

```bash
tmux new -s phase2
cd ~/fnberp
docker compose stop backend
# a. Đổi ảnh backend sang pha 2 — CHỈ lúc này. Quán đã có dòng BACKEND_IMAGE_TAG:
sed -i 's/^BACKEND_IMAGE_TAG=.*/BACKEND_IMAGE_TAG=sha-<p2>/' .env
#    quán chưa có dòng đó (đang chạy IMAGE_TAG/latest):
#    printf '\nBACKEND_IMAGE_TAG=sha-<p2>\n' >> .env
docker compose config --images        # kiểm: backend …:sha-<p2>, frontend như cũ
# b. Báo cáo TRƯỚC — --until: hôm qua (Coffeetree: 2026-09-27 để so với mốc gốc ở d)
docker compose run --rm --no-deps backend node dist/baseline-report \
  --until <YYYY-MM-DD> --out /backups/phase2-before-<ngày>.json
# c. Năm lượt runner, TỪNG lệnh một — chỉ sang lệnh sau khi lệnh trước in ✅
docker compose run --rm --no-deps backend node dist/oneway-migrate BigintLargeTables1783741100000
docker compose run --rm --no-deps backend node dist/oneway-migrate AddShopIdColumns1783741200000
docker compose run --rm --no-deps backend node dist/oneway-migrate CompositeKeys1783741400000
docker compose run --rm --no-deps backend node dist/oneway-migrate ExternalRefsAndZaloAppShops1783741500000
docker compose run --rm --no-deps backend node dist/oneway-migrate TenantScopedUniques1783741600000
# d. CỬA — chỉ đọc. Quán khách:
docker compose run --rm --no-deps backend node dist/phase2-gate --before /backups/phase2-before-<ngày>.json
#    Coffeetree: thêm mốc gốc (kiểm tệp có thật TRƯỚC — thiếu thì -v tạo thư mục rỗng, gate thoát 2):
[ -f ~/baseline-055-2026-09-27.json ] && sha256sum ~/baseline-055-2026-09-27.json   # = 56a0418ecc9641b9347bace4e78d5798083267dee94c827c44406f5e6c09fe8a
docker compose run --rm --no-deps -v ~/baseline-055-2026-09-27.json:/ref/baseline-055.json:ro \
  backend node dist/phase2-gate --before /backups/phase2-before-<ngày>.json --reference /ref/baseline-055.json
# e. CHỈ KHI d thoát 0:
docker compose up -d backend
docker compose logs backend | grep -E "Backend đang chạy|MỘT CHIỀU đang chờ"
```

Tiêu chí từng lệnh:

- **(a)** Qua: `config --images` in backend `…:sha-<p2>`, frontend như trước. Sai ⇒ sửa `.env` lại. Chưa đổi gì trong DB.
- **(b)** Qua: in 6 hash và `→ /backups/phase2-before-<ngày>.json`. Tệp đã có ⇒ thoát 1: đặt tên khác. Thiếu hoặc sai múi giờ ⇒ thoát 1 kèm câu nêu cách đặt.
- **(c)** Mỗi lượt qua khi in `✅ Đã chạy … trong X s (… ms, một transaction). Tổng kể cả sao lưu: Y s.` Chép X, Y từng lượt vào sổ.
  - **Lượt BIG** in thêm `Đã sao lưu và kiểm đọc lại được: /backups/trcf_erp-<ts>.dump`. **Chép đường tệp này vào sổ**: đó là đường lùi của cả pha 2.
  - Lượt CK in thêm `ShopIdFence1783741300000`; lượt TU in thêm `ExternalRefFence1783741550000` (rào nằm trong lô).
  - Lượt nào in `đã chạy` là đã ghi từ lần trước. Xem [Đứt giữa chừng](#đứt-giữa-chừng--mất-điện-đứt-ssh-tiến-trình-bị-giết).
- **(d)** In 11 phép (quán khách 10, vì không có `--reference`):
  - `oneway-applied` · `phase1-intact` · `shops` (đúng một quán id = 1 + `ref_code`).
  - `shop-id-columns` — mọi bảng theo quán có `shop_id bigint NOT NULL` + khoá ngoại `FK_<bảng>_shop`. **10 bảng cửa ngõ KHÔNG default**, các bảng khác default 1.
  - `bigint-large-tables` · `composite-fks` (khoá ngoại kép, `SET NULL` nêu cột con, 4 cột int thô không khoá ngoại).
  - `tenant-uniques` — unique theo quán; các unique toàn cục (tra-khi-chưa-biết-quán) + `print_pairing_codes.code_hash` (index thường) giữ nguyên.
  - `external-refs` — in mẫu `<REF>-SO000000-001`.
  - `zalo-app-shops` — `shop_id` NOT NULL không default; ở cửa đầy đủ thêm: mỗi ô `zalo.app_id` có đúng một dòng ánh xạ (quán chưa bật kênh ⇒ `0 dòng`). `--schema-only` KHÔNG đối chiếu ô ↔ dòng.
  - `baseline-before-after` — 4 hash số liệu = báo cáo trước. Số dòng chỉ được khác ở `migrations` (phải tăng); `shops`, `zalo_app_shops` được phép vắng ở trước.
  - `baseline-reference` — chỉ Coffeetree: doanh thu theo ngày = mốc gốc.

  **Qua** khi thoát 0 và dòng cuối là `✅ Cửa pha 2: 11/11 PASS` (quán khách `10/10`). Thoát 2 là sai tham số hoặc tệp: sửa lệnh (chưa phải kết luận). Cửa chạy lại được bao nhiêu lần cũng được, vì nó không ghi gì.
- **(e)** Qua cần đủ ba điều:
  - log có `Backend đang chạy`;
  - **không** còn dòng `MỘT CHIỀU đang chờ`;
  - **bán một đơn thử** trên màn bán hàng (thu tiền, in bill), rồi thấy nó ở màn Đơn hàng.

  Không có `INSERT` thử nào trong cửa. Đường ghi thật đi qua hai nửa: lưới trên bản sao (bước 0) và đơn thử này.

**Đường lùi** — ghi sự cố (mục 5) trong mọi trường hợp:

- **Lượt runner thứ k thoát 1** ⇒ lô của lượt đó đã rollback, schema dừng ở sau lượt k−1. Lỗi `lock timeout` ⇒ tìm phiên giữ khoá (mục Đứt giữa chừng, bước a), rồi chạy lại **đúng lệnh đó**. Lỗi khác:
  - **k = 1** (BIG): chưa gì đổi. Trả `BACKEND_IMAGE_TAG` về tag pha 1 đã ghi ở bước 1 (sửa lại dòng bằng `sed`, hoặc xoá dòng nếu trước đó không có), rồi `docker compose up -d backend`.
  - **k ≥ 2**: ảnh pha 1 không được chạy trên schema đã có `shop_id`: bảng cửa ngõ là `NOT NULL` không default, mã cũ ghi mà không nêu `shop_id` sẽ chết `23502`. Ảnh pha 2 cũng không boot được khi ER còn chờ. ⇒ [quay về dump](#đứt-giữa-chừng--mất-điện-đứt-ssh-tiến-trình-bị-giết) **đúng tệp của lượt BIG**, trả `BACKEND_IMAGE_TAG` về tag pha 1, rồi `up -d backend`.
- **Cửa (d) thoát 1** ⇒ **KHÔNG** `up -d backend`. Quay về dump của lượt BIG + trả tag pha 1 + `up -d backend`.
  - `--down TenantScopedUniques1783741600000` chỉ đảo được mỗi TU. Chỉ dùng khi FAIL duy nhất là `tenant-uniques` và cần soi thêm trước khi quyết. Còn FAIL khác thì vẫn phải về dump.
  - Riêng Coffeetree: `baseline-reference` FAIL với chi tiết `đã lệch từ --before`, trong khi `baseline-before-after` PASS ⇒ migration không đổi số, mà doanh thu 29/08–27/09 đã đổi **trước** cửa sổ. Vẫn là FAIL: báo người phụ trách, người đó quyết trong trần 30 phút và ghi sổ. Không quyết kịp ⇒ về dump.
- **Sau `up -d backend`** (đơn thử hỏng, hoặc sự cố trong 7 ngày) ⇒ quay về dump của lượt BIG + trả tag pha 1. **Mọi đơn bán sau giờ chụp dump sẽ mất** — cân nhắc với chủ quán trước khi làm.

**4. Ghi sổ** — mỗi ô của quán trong `specs/055-saas/trien-khai-pha-2.md`:

- preflight và fingerprint;
- diễn tập (5 thời gian + tổng);
- lưới bản sao;
- CI run;
- tag + digest;
- cửa sổ;
- dump của lượt đầu;
- gate;
- hash trước/sau;
- ngày 1.

Dán nguyên dòng in ra — không điền số ước.

**5. Luật 7 ngày và sự cố.** Ngày 1 là ngày sau cửa sổ đã `up -d backend` với cửa PASS. Mỗi ngày trong 7 ngày, chạy hai kiểm chỉ-đọc:

```bash
docker compose run --rm --no-deps backend node dist/phase2-gate --schema-only
docker compose logs --since 24h backend | grep -E '2350[235]'
```

- Lệnh đầu **qua** khi thoát 0 và dòng cuối là `✅ Schema pha 2 (chỉ schema — không phải cửa): 9/9 PASS`. Nó không so báo cáo, nên chạy được lúc đang bán.
- Lệnh sau phải **không** in dòng nào: `23502` là thiếu `shop_id`, `23503` là khoá ngoại kép chặn, `23505` là trùng unique. `--since 24h` chỉ đọc log của 24 giờ qua — sự cố hôm trước đã ghi sổ không làm đỏ mãi các ngày sau.
- Chủ quán đổi Mini App Zalo (ô `zalo.app_id`) sau pha 2: bảng ánh xạ chưa tự theo ô cấu hình tới 554 (DW-100), nên `--schema-only` cố ý **không** đối chiếu hai thứ này — kiểm hằng ngày vẫn `9/9`, KHÔNG phải sự cố, không đếm lại. Chưa đường chạy nào của app đọc bảng ánh xạ (554 mới dùng và đồng bộ), nên lệch lúc này không ảnh hưởng bán hàng.

**Sự cố pha 2** là một trong các việc sau:

- cửa (d) thoát 1, hoặc phải quay về dump / `--down`;
- `--schema-only` thoát 1 ở bất kỳ ngày nào;
- log backend có `23502`, `23503` hoặc `23505` ở một đường ghi bình thường (bán, nhập, ca, chấm công, in, đơn Zalo, MoMo);
- một màn báo lỗi 5xx khi ghi, hoặc backend không khởi động;
- mã gửi ra ngoài sai: MoMo, hoá đơn điện tử hoặc Zalo Checkout báo không tìm thấy giao dịch, hoặc tiền về không khớp đơn;
- số liệu ngày/ca/kho/điểm lệch giữa các màn, hoặc chủ quán báo két không khớp mà nguyên nhân là dữ liệu sau pha 2.

Có sự cố ⇒ (1) **không** sang quán khách; (2) lùi quán đó bằng dump của lượt BIG + tag pha 1 (mất đơn sau giờ dump — cân nhắc với chủ quán); (3) ghi vào bảng nhật ký sự cố của sổ + một dòng `NHAT-KY.md`; (4) sửa, diễn tập lại trên bản sao, mở cửa sổ mới và **đếm lại 7 ngày từ đầu**.

#### Tách vai database (555.1) — backend chạy bằng vai KHÔNG phải chủ bảng

Từ 555.1 mọi bảng nghiệp vụ bật RLS + FORCE theo quán (migration thường `EnableShopRls1783741700000`, tự chạy lúc boot bằng vai chủ). RLS chỉ có tác dụng khi backend **không** chạy bằng superuser/chủ bảng — nên có ba vai:

| Vai | Biến | Dùng cho |
|---|---|---|
| chủ (`DB_USER`, mặc định `trcf`) | `MIGRATION_DATABASE_URL` | migration, cổng sao lưu, migration một chiều, CLI kiểm |
| ứng dụng (`trcf_app`) | `DATABASE_URL` | backend chạy hằng ngày — chỉ đọc/ghi dữ liệu, không đổi cấu trúc bảng |
| bypass (`trcf_bypass`, BYPASSRLS) | — | quản trị TRCF (mở quán `seed-shop`), đếm toàn bảng |

```bash
cd ~/trcf-erp
# 1. Dựng vai — chạy lại nhiều lần vô hại; cố ý KHÔNG đọc .env, gõ chuỗi tay:
APP_PW=$(openssl rand -hex 24); BYP_PW=$(openssl rand -hex 24)
docker compose run --rm --no-deps \
  -e ADMIN_DATABASE_URL="postgresql://trcf:<DB_PASSWORD>@postgres:5432/trcf_erp" \
  -e DB_APP_PASSWORD="$APP_PW" -e DB_BYPASS_PASSWORD="$BYP_PW" \
  backend node dist/setup-db-roles
# ✅ PASS … ⇒ ghi vai ứng dụng vào .env:
printf '\nDB_APP_USER=trcf_app\nDB_APP_PASSWORD=%s\n' "$APP_PW" >> .env
# (giữ BYP_PW ở nơi an toàn — dùng cho seed-shop / đếm toàn bảng)

# 2. Preflight pha 4 — đủ 4/4 PASS mới đổi vai (pooled · session-context · app-role · migration-role):
docker compose run --rm --no-deps backend node dist/phase4-preflight

# 3. Khởi động lại backend dưới vai ứng dụng; log phải có "Backend chạy dưới vai "trcf_app" (RLS áp)":
docker compose up -d backend && docker compose logs backend | grep DbRole
```

- Chưa đặt `DB_APP_USER` ⇒ backend chạy bằng `DB_USER` như cũ (log **cảnh báo** "SUPERUSER — RLS KHÔNG áp"). Migration và cổng sao lưu luôn đi bằng `MIGRATION_DATABASE_URL`.
- CLI đếm toàn bảng (`baseline-report`, `phase1-gate`, `phase2-gate`, `phase2-preflight`) chạy bằng vai bị RLS lọc sẽ **từ chối** và nêu tên vai — không in số 0 giả.
- **Ở quán, KHÔNG làm riêng ba bước trên** (đổi vai lúc đang bán, boot tự chạy migration pha 4 trước khi có cửa). Đổi vai + migration pha 4 đi chung **một** cửa sổ, có báo cáo trước/sau và cửa đọc chéo: [Triển khai pha 4 ở một quán (555.2)](#triển-khai-pha-4-ở-một-quán-5552--rls-theo-quán--backend-dưới-vai-app-một-cửa-sổ). Khối trên chỉ mô tả cơ chế.

#### Triển khai pha 4 ở một quán (555.2) — RLS theo quán + backend dưới vai app, một cửa sổ

Pha 4 gồm **hai việc lên cùng một cửa sổ, không dừng giữa**:

- 555.1: migration thường `EnableShopRls1783741700000` bật RLS + FORCE trên 79 bảng nghiệp vụ;
- đổi `DATABASE_URL` của backend sang vai `trcf_app`.

Bằng chứng máy móc là **cửa pha 4** — một lệnh trong ảnh. Nó dùng hai kết nối:

- **thước** (`MIGRATION_DATABASE_URL` — vai chủ `trcf`) để đếm sự thật;
- **đối tượng đo** (`DATABASE_URL` — vai `trcf_app`) để **cố tình** đọc dữ liệu của quán khác, kể cả một "quán ma" không tồn tại.

Cửa **qua** khi đọc chéo ra 0 dòng ở mọi bảng, và không bảng nghiệp vụ nào còn `relrowsecurity = false`.

Thứ tự quán như pha 1/2: **Coffeetree trước**, chạy **trọn 7 ngày không sự cố**, rồi tới ba quán khách, **từng quán một**. Ghi từng ô vào sổ `specs/055-saas/trien-khai-pha-4.md` (repo umbrella). Quán nào dừng ở bước nào thì **không đi tiếp** ở quán đó.

> ⛔ **`--write-probe` KHÔNG BAO GIỜ dùng ở quán.** Cờ này cho cửa thử `UPDATE`/`DELETE` chéo trong một transaction `ROLLBACK`. Chỉ diễn tập trên bản sao, CI và e2e được dùng nó. Database quán không bị ghi thử, dù có `ROLLBACK`. Ở quán, phép `cross-write` **vắng** khỏi danh sách: cửa không in `PASS` giả cho phép không chạy. Tính chất "`UPDATE`/`DELETE` chéo khớp 0 dòng" đã đo trên bản sao hai quán. Ở quán, phép `rls-catalog` kiểm policy `FOR ALL` phủ nó.

> ⚠️ **Cửa chạy TRƯỚC `up`, trên DB đứng yên.** Migration pha 4 là migration thường, tự chạy lúc boot. Để cửa chạy trước khi backend phục vụ request nào dưới RLS, cửa sổ tách hai bước đầu của boot ra thành `node dist/boot-migrate`: cổng sao lưu, rồi migration bằng vai chủ. Lệnh này **không** mở HTTP. Cửa FAIL thì chưa request nào đi qua, và dump của `boot-migrate` là đường lùi trọn vẹn.

**0. Điều kiện trước khi lên lịch** — cả năm phải đạt:

- **Cửa 554 đã xanh ở quán này**, và quán đang chạy ảnh ≥ 554.
- **CI "Lưới hồi quy" xanh trên đúng commit của ảnh**, có dòng `PASS cửa pha 4: … đọc/ghi chéo 0`. Ghi URL lượt chạy vào sổ.
- **Diễn tập pha 4 trên bản sao dump MỚI của CHÍNH quán đó**, trên máy local, trong `trcf_erp_backend/`:

  ```bash
  DRILL_SOURCE_DUMP=<quán>.dump BASELINE_FILE=../_bmad-output/implementation-artifacts/baseline-<quán>-<ngày>.json \
    BASELINE_UNTIL=<ngày chụp dump> bash scripts/phase4-rehearsal.sh
  ```

  Coffeetree để `BASELINE_FILE` mặc định (`baseline-055-2026-09-27.json`). Chạy không `DRILL_SOURCE_DUMP` thì nguồn là `ct_pristine` — đó chỉ là diễn tập của máy dev.

  Diễn tập đi trọn cửa sổ bằng chính các CLI trong ảnh:
  - `setup-db-roles` ×2, `phase4-preflight`;
  - cửa trước migration ⇒ 1;
  - `boot-migrate`;
  - cửa `--before --reference`;
  - boot dưới `trcf_app`;
  - lưới hồi quy dưới `trcf_app`;
  - gieo quán 2 rồi cửa `--write-probe --expect-shops 2`;
  - hai ca hỏng cố ý;
  - đường lùi bằng dump.

  **Qua** khi dòng cuối là `Tất cả PASS`. Chép vào sổ bốn dòng `thời gian …` và dòng `ước cửa sổ …`.
- **Tổng thời gian dưới 30′.** Diễn tập tự kiểm dòng `ước cửa sổ`: báo cáo + `boot-migrate` + cửa + boot < 1800 s.
- **`trcf_deploy` của quán đã có `MIGRATION_DATABASE_URL`** (555.1):

  ```bash
  cd ~/fnberp && docker compose config | grep -c MIGRATION_DATABASE_URL   # ≥ 1
  ```

**1. Build + kéo ảnh (KHÔNG `up`).** Như pha 2 bước 1: tag `sha-<p4>`, `docker pull`, ghi digest và tag đang chạy (đường lùi) vào sổ. **Không** sửa `.env`, **không** `up`.

**2. Vài ngày trước cửa sổ — dựng vai + preflight.** Quán vẫn bán trên ảnh cũ và vai `trcf`. Dựng vai là việc cấp cụm, không đổi dữ liệu nghiệp vụ, và chạy lại vô hại:

```bash
cd ~/fnberp
APP_PW=$(openssl rand -hex 24); BYP_PW=$(openssl rand -hex 24)
BACKEND_IMAGE_TAG=sha-<p4> docker compose run --rm --no-deps \
  -e ADMIN_DATABASE_URL="postgresql://trcf:<DB_PASSWORD>@postgres:5432/trcf_erp" \
  -e DB_APP_PASSWORD="$APP_PW" -e DB_BYPASS_PASSWORD="$BYP_PW" \
  backend node dist/setup-db-roles
# Giữ mật khẩu cho tới cửa sổ — CHƯA ghi vào .env:
umask 077; printf 'APP_PW=%s\nBYP_PW=%s\n' "$APP_PW" "$BYP_PW" > ~/fnberp/db-roles.secret
# Preflight bằng vai app — ghi đè DATABASE_URL cho MỘT lệnh, không sửa .env:
BACKEND_IMAGE_TAG=sha-<p4> docker compose run --rm --no-deps \
  -e DATABASE_URL="postgresql://trcf_app:$APP_PW@postgres:5432/trcf_erp" \
  backend node dist/phase4-preflight
```

- `setup-db-roles` **qua** khi in `✅ PASS — trcf_app chỉ DML, trcf_bypass BYPASSRLS, …`.
- `phase4-preflight` **qua** khi in `✅ Preflight pha 4: 4/4 PASS` (`pooled` · `session-context` · `app-role` · `migration-role`).
- Không qua ⇒ không lên lịch.
- Chạy preflight **không** kèm `-e DATABASE_URL=…trcf_app…` thì nó đo vai `trcf` và FAIL `app-role`. Diễn tập đã đo ca này — đó là lệnh gõ thiếu, chưa phải kết luận.

**3. Trong cửa sổ** — ngoài giờ bán, trần **30 phút** tính từ `stop backend` tới `up -d backend`. Chạy trong `tmux`, **đúng thứ tự**, ghi giờ bắt đầu. **Dừng ở lệnh đầu tiên không qua**, rồi đi đường lùi bên dưới.

```bash
tmux new -s phase4
cd ~/fnberp
docker compose stop backend
# a. Báo cáo TRƯỚC — .env CHƯA sửa (vai trcf). --until: hôm qua (Coffeetree: 2026-09-27)
docker compose run --rm --no-deps backend node dist/baseline-report \
  --until <YYYY-MM-DD> --out /backups/phase4-before-<ngày>.json
# b. Đổi ảnh + vai app — CHỈ lúc này:
. ~/fnberp/db-roles.secret
sed -i 's/^BACKEND_IMAGE_TAG=.*/BACKEND_IMAGE_TAG=sha-<p4>/' .env
printf '\nDB_APP_USER=trcf_app\nDB_APP_PASSWORD=%s\n' "$APP_PW" >> .env
docker compose config | grep -E 'image: .*trcf-erp-backend|DATABASE_URL'   # backend …:sha-<p4>; DATABASE_URL trcf_app; MIGRATION_DATABASE_URL trcf
# c. Cổng sao lưu + migration bằng vai chủ — KHÔNG mở HTTP
docker compose run --rm --no-deps backend node dist/boot-migrate
# d. CỬA. Quán khách:
docker compose run --rm --no-deps backend node dist/phase4-gate --before /backups/phase4-before-<ngày>.json
#    Coffeetree: thêm mốc gốc (kiểm tệp có thật TRƯỚC):
[ -f ~/baseline-055-2026-09-27.json ] && sha256sum ~/baseline-055-2026-09-27.json   # = 56a0418ecc9641b9347bace4e78d5798083267dee94c827c44406f5e6c09fe8a
docker compose run --rm --no-deps -v ~/baseline-055-2026-09-27.json:/ref/baseline-055.json:ro \
  backend node dist/phase4-gate --before /backups/phase4-before-<ngày>.json --reference /ref/baseline-055.json
# e. CHỈ KHI d thoát 0:
docker compose up -d backend
docker compose logs backend | grep -E 'DbRole|Backend đang chạy'
```

Tiêu chí từng lệnh:

- **(a)** Qua: in hash và `→ /backups/phase4-before-<ngày>.json`. Tệp đã có ⇒ thoát 1: đặt tên khác.
- **(b)** Qua: `config` cho thấy ba điều. Sai ⇒ sửa `.env` lại. Chưa đổi gì trong DB.
  - image backend `…:sha-<p4>`;
  - `DATABASE_URL: postgresql://trcf_app:…`;
  - `MIGRATION_DATABASE_URL: postgresql://trcf:…`.
- **(c)** Qua: thoát 0 và in ba dòng.
  - `Đã sao lưu và kiểm đọc lại được: /backups/trcf_erp-<ts>.dump` — **chép đường tệp này vào sổ**: đó là đường lùi của cả pha 4.
  - `Migration chạy bằng vai "trcf" (MIGRATION_DATABASE_URL): 1 migration mới.`
  - `✅ boot-migrate: 1 migration mới — backend CHƯA chạy`.

  Thoát 1 (`⛔ Từ chối boot-migrate: …`) ⇒ chưa đổi gì trong DB, hoặc lô đã rollback.
- **(d)** In mỗi phép một dòng `PASS|FAIL <tên> — <chi tiết>`:
  - `migration-applied` — có dòng `EnableShopRls1783741700000`.
  - `app-role` — `DATABASE_URL` là `trcf_app`: không SUPERUSER, không BYPASSRLS, không sở hữu bảng.
  - `relrowsecurity` (FR-030) — đọc thẳng `pg_class`: mọi bảng `public` ngoài 12 bảng loại trừ đều bật RLS; `migrations`, `shops` và 10 bảng cửa ngõ thì không. Chi tiết in `bảng quên bật: 0`.
  - `rls-catalog` — FORCE, policy `shop_isolation` (USING + WITH CHECK), `DEFAULT shop_id` đọc ngữ cảnh.
  - `migrations-visible` — vai app không ngữ cảnh thấy đủ `migrations` + `shops`, 0 migration chờ.
  - `no-context-empty` — vai app không ngữ cảnh ⇒ 0 dòng ở **mọi** bảng nghiệp vụ.
  - `own-shop` — ngữ cảnh quán ⇒ thấy **đủ** số dòng của quán, từng bảng.
  - `cross-read` (FR-029) — ngữ cảnh quán thật và **quán ma** (id = max + 1) ⇒ đọc dữ liệu quán khác ra 0 dòng ở mọi bảng có dữ liệu.
  - `baseline-before-after` — 4 hash số liệu = báo cáo trước; số dòng chỉ được khác ở `migrations` (phải tăng).
  - `baseline-reference` — chỉ Coffeetree: doanh thu theo ngày = mốc gốc.

  **Qua** khi thoát 0 và dòng cuối là `✅ Cửa pha 4: 10/10 PASS` (quán khách `9/9`). Thoát 2 là sai tham số hoặc tệp: sửa lệnh, chưa phải kết luận. Cửa không ghi gì, nên chạy lại bao nhiêu lần cũng được.
- **(e)** Qua cần đủ ba điều:
  - log có `Backend chạy dưới vai "trcf_app" (RLS áp).`;
  - log có `Backend đang chạy`;
  - **bán một đơn thử** trên màn bán hàng (thu tiền, in bill), rồi thấy nó ở màn Đơn hàng. Màn nào **trắng** mà không báo lỗi là dấu hiệu ngữ cảnh quán không tới nơi ⇒ sự cố.

  Log có `SUPERUSER — RLS KHÔNG áp` ⇒ `.env` bước (b) chưa ăn ⇒ sự cố.

Khi xong: `rm ~/fnberp/db-roles.secret`. `BYP_PW` chép sang nơi giữ mật khẩu của TRCF; nó dùng cho `seed-shop` và đếm toàn bảng sau này.

**Đường lùi** — ghi sự cố (mục 5) trong mọi trường hợp:

- **(a) hoặc (c) thoát 1** ⇒ DB chưa đổi (lô migration rollback trọn). Trả `.env` rồi `up`:

  ```bash
  sed -i 's/^BACKEND_IMAGE_TAG=.*/BACKEND_IMAGE_TAG=<tag cũ trong sổ>/' .env
  sed -i '/^DB_APP_USER=/d; /^DB_APP_PASSWORD=/d' .env
  docker compose up -d backend
  ```

- **Cửa (d) thoát 1** ⇒ **KHÔNG** `up -d backend`. Quay về **dump của (c)** bằng lệnh khôi phục ở mục [Đứt giữa chừng](#đứt-giữa-chừng--mất-điện-đứt-ssh-tiến-trình-bị-giết):

  ```bash
  docker compose cp backend:/backups/trcf_erp-<ts>.dump ./restore.dump
  docker compose cp ./restore.dump postgres:/tmp/restore.dump
  docker compose exec -T postgres dropdb -U trcf --force trcf_erp
  docker compose exec -T postgres createdb -U trcf trcf_erp
  docker compose exec -T postgres pg_restore -U trcf --no-owner --no-privileges --exit-on-error \
    -d trcf_erp /tmp/restore.dump
  ```

  Rồi trả `.env` như trên (tag cũ + gỡ `DB_APP_USER`/`DB_APP_PASSWORD`) và `up -d backend`. Backend đã dừng từ trước (a), nên **không mất đơn nào**. Diễn tập đã đo: khôi phục dump của `boot-migrate` ra schema `pg_dump -s` **đúng bằng** trước pha 4, 0 bảng RLS. `--no-privileges` bỏ luôn quyền của `trcf_app` — đúng ý, vì backend lùi về vai `trcf`. Vai vẫn còn trong cụm, vô hại; cửa sổ sau chạy lại `setup-db-roles`.
- **Sau `up -d backend`** (đơn thử hỏng, màn trắng, sự cố trong 7 ngày) ⇒ cùng đường: dump của (c) + tag cũ + gỡ `DB_APP_USER`. **Mọi đơn bán sau giờ chụp dump sẽ mất** — cân nhắc với chủ quán trước khi làm.

**4. Ghi sổ** — mỗi ô của quán trong `specs/055-saas/trien-khai-pha-4.md`: diễn tập (bốn thời gian + ước cửa sổ), CI run, tag + digest, `setup-db-roles` + preflight, cửa sổ, **dump của `boot-migrate`**, cửa (`n/n`), dòng `(RLS áp)`, đơn thử, ngày 1. Dán nguyên dòng in ra — không điền số ước.

**5. Luật 7 ngày và sự cố.** Ngày 1 là ngày sau cửa sổ đã `up -d backend` với cửa PASS. Mỗi ngày trong 7 ngày, chạy hai kiểm chỉ-đọc. Cả hai chạy được lúc đang bán; kiểm không so báo cáo:

```bash
docker compose run --rm --no-deps backend node dist/phase4-gate
docker compose logs backend | grep DbRole | tail -1
```

- Lệnh đầu **qua** khi thoát 0 và dòng cuối là `✅ Kiểm RLS pha 4 (không so báo cáo — không phải cửa): 8/8 PASS`. Hai kết nối nhìn **cùng một snapshot**, nên đơn bán chen giữa hai lần đếm không làm đỏ giả.
- Lệnh sau phải in `Backend chạy dưới vai "trcf_app" (RLS áp).`

**Sự cố pha 4** là một trong các việc sau:

- cửa (d) thoát 1, hoặc phải quay về dump;
- kiểm hằng ngày thoát 1 ở bất kỳ ngày nào, nhất là `relrowsecurity` nêu tên một bảng: một bản cập nhật sau đã thêm bảng mà quên bật RLS;
- backend không khởi động, hoặc log mất dòng `(RLS áp)`;
- một màn **trắng** hoặc thiếu dữ liệu mà trước đó có (đọc ngoài ngữ cảnh quán bị RLS lọc về 0);
- một đường ghi báo lỗi 5xx, ví dụ `INSERT` thiếu ngữ cảnh chết `23502`, hoặc `WITH CHECK` chặn;
- số liệu ngày/ca/kho/điểm lệch giữa các màn.

Có sự cố ⇒ (1) **không** sang quán khách; (2) lùi quán đó bằng dump của `boot-migrate` + tag cũ + gỡ `DB_APP_USER` (mất đơn sau giờ dump — cân nhắc với chủ quán); (3) ghi vào bảng nhật ký sự cố của sổ + một dòng `NHAT-KY.md`; (4) sửa, diễn tập lại trên bản sao, mở cửa sổ mới và **đếm lại 7 ngày từ đầu**.

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
