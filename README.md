# TRCF ERP — Cài đặt

Hai phần: **A. Cài ERP** (máy chủ của quán) · **B. Cài Bridge** (máy quầy có máy in USB).
Mỗi bước là một khối lệnh, dán nguyên khối vào terminal.

Bản đầy đủ (sao lưu, migration, xử lý sự cố, lịch sử): [docs/README-CHI-TIET.md](docs/README-CHI-TIET.md).

---

## A. Cài ERP

Cần: Ubuntu 22.04/24.04 · chip x86_64 · 2 CPU · 4 GB RAM · 20 GB đĩa · tài khoản `root` hoặc có `sudo`
· token do nhà cung cấp cấp. Nên đặt IP tĩnh cho máy (hoặc DHCP reservation ở router).

### Bước 1 — Kiểm tra chip

```bash
uname -m
```

Phải ra `x86_64`. Ra `aarch64`/`arm64` thì dừng: chưa có bản cho chip ARM.

### Bước 2 — Cài Docker

```bash
curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/docker.sh | bash
newgrp docker
```

Máy đã có Docker thì script tự bỏ qua.

### Bước 3 — Khai token và phiên bản

```bash
export GHCR_TOKEN=<token>
export BE_TAG=sha-1a4837c     # backend — bản cài 17/11/2026
export APP_TAG=sha-95f3e06    # giao diện — bản cài 17/11/2026
```

Thay `<token>`. Có bản mới hơn thì đổi hai tag (xem [MAINTAINER.md](MAINTAINER.md)).

### Bước 4 — Chạy bộ cài

```bash
cd ~ && curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/erp.sh \
  | bash -s -- --backend-tag "$BE_TAG" --app-tag "$APP_TAG"
```

Có tên miền thì thêm `--domain erp.tenquan.vn` vào cuối (DNS phải trỏ về máy trước).

> ⚠️ **Trên máy mới, bước này sẽ báo đỏ ở đoạn "Khởi động" — đó là lỗi đã biết, làm tiếp bước 5.**
> Bộ cài chưa dựng được database trắng với bản backend hiện tại. Bước 5 dựng tay.
> Bước 4 chạy xanh tới dòng "TRCF ERP đã cài đặt xong" thì bỏ qua bước 5.

### Bước 5 — Dựng database (chỉ máy mới)

Dán **từng khối**, chờ khối trước chạy xong mới dán khối sau.

**5a. Tạo bảng gốc** (chờ 1–3 phút):

```bash
cd ~/fnberp
BACKEND_IMAGE_TAG=latest docker compose up -d --no-deps backend
until docker compose logs backend 2>&1 | grep -q 'Backend đang chạy'; do sleep 5; echo "…chờ"; done
docker compose exec -T postgres psql -U trcf -d trcf_erp -At -c 'select count(*) from migrations' </dev/null
docker compose stop backend
```

Dòng số phải ra **`122`**. Khác thì dừng, gửi nhà cung cấp.

**5b. Đặt múi giờ quán:**

```bash
docker compose exec -T postgres psql -U trcf -d trcf_erp -c \
  "INSERT INTO system_settings (module, key, value, value_type, description) VALUES ('general','timezone','Asia/Ho_Chi_Minh','str','Múi giờ quán (IANA)')"
```

**5c. Sáu bước nâng cấu trúc** (mỗi lượt vài giây, phải in ✅):

```bash
for m in TimestamptzEverywhere1783741000000 BigintLargeTables1783741100000 \
         AddShopIdColumns1783741200000 CompositeKeys1783741400000 \
         ExternalRefsAndZaloAppShops1783741500000 TenantScopedUniques1783741600000; do
  docker compose run --rm --no-deps backend node dist/oneway-migrate "$m" || { echo "⛔ DỪNG ở $m"; break; }
done
```

**5d. Tạo vai database cho backend:**

```bash
DBPW=$(grep '^DB_PASSWORD=' .env | cut -d= -f2-)
APP_PW=$(openssl rand -hex 24); BYP_PW=$(openssl rand -hex 24)
docker compose run --rm --no-deps \
  -e ADMIN_DATABASE_URL="postgresql://trcf:$DBPW@postgres:5432/trcf_erp" \
  -e DB_APP_PASSWORD="$APP_PW" -e DB_BYPASS_PASSWORD="$BYP_PW" \
  backend node dist/setup-db-roles \
&& (umask 077; echo "BYP_PW=$BYP_PW" > ~/trcf-bypass.secret) \
&& docker compose run --rm --no-deps \
  -e DATABASE_URL="postgresql://trcf_app:$APP_PW@postgres:5432/trcf_erp" \
  backend node dist/phase4-preflight \
&& printf '\nDB_APP_USER=trcf_app\nDB_APP_PASSWORD=%s\n' "$APP_PW" >> .env \
&& echo "✅ Xong 5d"
```

Phải thấy `✅ Xong 5d`. Mật khẩu vai quản trị cất ở `~/trcf-bypass.secret`.

**5e. Chạy phần còn lại và bật hệ thống:**

```bash
docker compose run --rm --no-deps backend node dist/boot-migrate \
&& docker compose run --rm --no-deps backend node dist/phase4-gate \
&& docker compose up -d \
&& echo "✅ Xong — chờ 1 phút rồi mở trình duyệt"
```

### Bước 6 — Kiểm tra và đăng nhập

```bash
cd ~/fnberp
docker compose ps
hostname -I | awk '{print "Mở trình duyệt: http://"$1}'
grep '^ADMIN_SEED' .env
```

- `docker compose ps`: cả `caddy`, `postgres`, `backend`, `frontend_app` đều **Up**, có chữ `healthy`.
- Mở địa chỉ in ra, đăng nhập bằng email + mật khẩu ở dòng `ADMIN_SEED_*` (mặc định
  `admin@trcf.vn` / `1234567890@`). Đổi mật khẩu ngay trong mục Tài khoản.
- Máy thu ngân, tablet bếp, điện thoại cùng wifi mở **cùng địa chỉ đó**.

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

Máy quầy chưa có Docker thì chạy bước A2 (cài Docker) trước.

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
