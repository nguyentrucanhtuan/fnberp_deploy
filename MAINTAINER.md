# TRCF ERP — Ghi chú cho người phát hành bản cài

Tài liệu nội bộ (khách không cần đọc). Mô tả bộ cài hoạt động ra sao và **những việc
phải làm một lần** để lệnh cài một dòng chạy được.

---

## 1. Kiến trúc bản giao khách

```
                 máy khách trong quán (cùng wifi)
                              │
                     http://<IP máy chủ>          ← MỘT địa chỉ duy nhất
                              │
                      ┌───────▼────────┐
                      │     caddy      │  cổng 80/443 · tự cấp HTTPS khi có domain
                      └───┬────────┬───┘
        /socket.io/*      │        │      còn lại
        /shop/*           │        │
                  ┌───────▼──┐  ┌──▼─────────┐
                  │ backend  │  │  frontend  │
                  │  :3333   │◄─┤ BFF /api   │  (nội bộ Docker, không lộ ra ngoài)
                  └────┬─────┘  └────────────┘
                       │
                 ┌─────▼─────┐
                 │ postgres  │  volume pgdata
                 └───────────┘
```

**Vì sao có Caddy** — không chỉ để lấy HTTPS. Nó gộp frontend + backend về **một origin**,
nhờ đó `NEXT_PUBLIC_WS_URL` không cần baked vào bundle lúc build: trình duyệt nối WebSocket
về chính origin đang mở, Caddy đẩy `/socket.io/*` sang backend. Một ảnh `:latest` dùng chung
cho **mọi khách, mọi IP LAN, mọi domain**. (Trước đây baked cứng `http://localhost:3333` →
màn bếp trên tablet nối hụt vì `localhost` của tablet không phải máy chủ.)

Định tuyến trong `Caddyfile`:

| Đường dẫn | Đích | Lý do |
|---|---|---|
| `/socket.io/*` | backend | WebSocket màn bếp + màn khách (045) |
| `/shop/*` | backend | BFF công khai cho Zalo Mini App (046) |
| còn lại | frontend | Giao diện + BFF `/api` (gắn Bearer, RBAC ở backend) |

Thêm route public mới cho backend → bổ sung vào matcher `@backend`.

---

## 2. Việc phải làm MỘT LẦN

### 2.1 Giữ 2 package GHCR ở chế độ **private** (quyết định đã chốt)

Không cần làm gì trên GitHub — package mặc định private. **Đừng** chuyển sang public.

**Lý do:** `dist/` của backend là output `tsc`, **không minify**. Tên hàm, tên biến,
toàn bộ luồng nghiệp vụ (engine sổ cái tiền, sổ cái kho, RBAC…) đọc được nguyên vẹn
nếu ai đó `docker pull` được ảnh. `removeComments: true` chỉ xoá chú thích.
(Frontend thì Next.js minify thật — khó đọc hơn nhiều, nhưng phải cùng chế độ với backend
thì mới có tác dụng.)

Muốn sau này chuyển sang public mà vẫn kín logic → phải **bundle + minify backend**
(esbuild/webpack) trước khi đóng ảnh. Rủi ro: NestJS phụ thuộc decorator metadata và
TypeORM entity — bundle sai là gãy lúc runtime, phải test kỹ. Hiện **chưa làm**.

### 2.2 Cấp token cho khách

Xem quy trình đầy đủ ở **[§6 Quản lý token](#6-quản-lý-token-cấp-cho-khách)**.

### 2.3 Build lại ảnh frontend sau thay đổi same-origin WS

Ba file đã sửa ở repo frontend — **phải push để CI build lại ảnh** thì bộ cài mới hoạt động đúng:

| File | Thay đổi |
|---|---|
| `src/lib/realtime.ts` | Mặc định WS base = `""` (same-origin) thay vì `http://localhost:3333`; thêm fallback transport `polling` |
| `Dockerfile` | `ARG NEXT_PUBLIC_API_URL` / `NEXT_PUBLIC_WS_URL` mặc định **rỗng** |
| `.github/workflows/release.yml` | Bỏ default `http://localhost:3333` khỏi build args |

Kiểm tra: repo frontend → **Settings → Variables** phải **KHÔNG** có `NEXT_PUBLIC_WS_URL`
/ `NEXT_PUBLIC_API_URL` (nếu có, xoá đi — chúng sẽ ghi đè same-origin).

### 2.4 Đẩy repo deploy này lên public

Lệnh cài đọc file thẳng từ `raw.githubusercontent.com` nên repo `fnberp_deploy`
phải **public** (hiện đã public) và các file phải nằm ở nhánh `main`:

```
install/ubuntu.sh      ← đích của lệnh curl | bash
docker-compose.yml
Caddyfile
.env.example
```

URL trong script và README:
`https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/…`

Đổi tên repo/nhánh → phải sửa hằng `RAW_BASE` ở đầu `install/ubuntu.sh` **và** các URL
trong `README.md`. Khi thử nghiệm có thể trỏ nguồn khác không cần sửa file:

```bash
TRCF_RAW_BASE=https://raw.githubusercontent.com/<user>/<repo>/<branch> bash install/ubuntu.sh
```

---

## 3. Quy trình phát hành bản mới

```
push main (backend hoặc frontend)
        │
        ▼
GitHub Actions release.yml  →  build ảnh  →  ghcr.io/…:latest + :sha-<short>
        │
        ▼
khách chạy:  curl … | bash -s -- --update      (hoặc docker compose pull && up -d)
```

Ghim phiên bản cho một khách cụ thể: `--tag sha-a1b2c3d` (script ghi `IMAGE_TAG` vào `.env`).

Trước khi phát hành ảnh mới, tự kiểm tra bộ cài:

```bash
# Kiểm cú pháp
bash -n install/ubuntu.sh
docker compose --env-file <(sed 's/thay-.*/x/' .env.example) config -q

# Kiểm Caddyfile cả 2 chế độ
docker run --rm -v "$PWD/Caddyfile:/etc/caddy/Caddyfile:ro" -e SITE_ADDRESS=":80" \
  caddy:2-alpine caddy validate --config /etc/caddy/Caddyfile
docker run --rm -v "$PWD/Caddyfile:/etc/caddy/Caddyfile:ro" -e SITE_ADDRESS="erp.test.vn" \
  caddy:2-alpine caddy validate --config /etc/caddy/Caddyfile
```

Thử cài thật trên VM Ubuntu sạch (Multipass/VirtualBox/VPS) trước khi giao khách.

---

## 4. Script cài — điểm cần biết

- **Idempotent**: chạy lại nhiều lần an toàn. Đã có `.env` thì **giữ nguyên** (không ghi đè
  mật khẩu/secret cũ), chỉ pull + up lại.
- **Không tương tác**: chạy được qua `curl | bash` (stdin đã bị chiếm bởi chính script nên
  không dùng `read`). Mọi lựa chọn truyền qua cờ dòng lệnh.
- **Sinh secret**: `DB_PASSWORD` (hex 24), `JWT_SECRET`/`AUTH_SECRET` (hex 32), mật khẩu admin
  (14 ký tự chữ-số). `.env` và `thong-tin-dang-nhap.txt` đều `chmod 600`.
- **Phát hiện IP LAN**: `ip route get 1.1.1.1` → fallback `hostname -I` → fallback `localhost`.
- **Nhóm docker**: thêm user vào nhóm nhưng phiên hiện tại chưa có hiệu lực → script tự dùng
  `sudo docker` cho tới hết lần chạy, và nhắc khách đăng nhập lại.
- **ufw**: nếu đang bật thì tự mở cổng 80 (và 443 khi có `--domain`).
- **Chờ healthy**: tối đa 5 phút dựa trên healthcheck của service `frontend` (service này
  `depends_on` backend healthy → backend đã chạy xong migration + seed).

---

## 5. Bảo mật đã tính

| | |
|---|---|
| Cổng lộ ra ngoài | Chỉ 80/443 (caddy). `backend:3333` và `postgres:5432` **không publish** |
| Secret | Sinh ngẫu nhiên trên máy khách, mỗi cài đặt một giá trị; file `chmod 600` |
| Source code | Không có trên máy khách; ảnh đã strip `.map` / `.d.ts` |
| Token đăng nhập | httpOnly cookie, BFF `/api` gắn Bearer; trình duyệt không giữ JWT |
| HTTPS | Tự động khi cài với `--domain` |

**Còn thiếu trước khi coi là production đầy đủ** (xem các file `specs/*/IMPROVEMENTS.md`):
mã hoá secret at-rest trong bảng `system_settings`, giám sát/cảnh báo, kiểm thử tải,
xác minh tài khoản thật cho Minvoice / Zalo / cổng thanh toán, và **kiểm tra bản sao lưu
phục hồi được** (khách hay bỏ qua mục này).

---

## 6. Quản lý token cấp cho khách

### 6.1 Tạo token

GitHub → **Settings** → **Developer settings** → **Personal access tokens** →
**Tokens (classic)** → **Generate new token (classic)**:

| Trường | Điền |
|---|---|
| **Note** | Tên khách, ví dụ `TRCF — Quán Mimosa` (để biết thu hồi cái nào) |
| **Expiration** | **No expiration** (xem 6.3) |
| **Scopes** | ✅ **`read:packages`** — **CHỈ MỘT ô này**, không tick gì thêm |

Bấm **Generate token** → copy chuỗi `ghp_…` **ngay** (GitHub chỉ hiện một lần).

> ⚠️ **Phải là "Tokens (classic)"**. GitHub Docs: *"GitHub Packages only supports
> authentication using a personal access token (classic)."* Fine-grained token **không có**
> scope `read:packages` → không kéo được ảnh.
>
> ⚠️ **Chỉ tick `read:packages`**. Tick thêm `repo` là token đọc được **toàn bộ mã nguồn
> private** của bạn — mất trắng mục đích giữ private.

### 6.2 Token dùng được tới đâu

| Câu hỏi | Trả lời |
|---|---|
| Tạo được bao nhiêu token? | **Không giới hạn** — GitHub không công bố mức trần |
| Một token cài đi cài lại trên cùng một máy? | **Được, không giới hạn số lần** |
| Token có bị khoá theo máy không? | **KHÔNG** — token không gắn với máy nào cả |
| Vậy khách đưa token cho người khác? | Người đó **kéo được ảnh**. "Mỗi khách một token" là quy ước của bạn để **truy vết + thu hồi riêng**, GitHub không tự ép |
| Token làm được gì ngoài kéo ảnh? | Không gì cả (chỉ `read:packages`): không đọc source, không push, không xoá |

Docker lưu thông tin đăng nhập vào `~/.docker/config.json` sau lần đầu, nên các lần
`docker compose pull` sau **không cần nhập lại token**.

### 6.3 Vì sao chọn "No expiration"

Token hết hạn = khách **không cập nhật được** cho tới khi bạn cấp token mới (hệ thống
đang chạy thì vẫn chạy bình thường — chỉ chặn `pull`). Đặt không hết hạn rồi **chủ động
thu hồi** khi ngừng hợp tác thì kiểm soát tốt hơn là để nó chết bất ngờ giữa chừng.

Lưu ý: GitHub **tự xoá token không dùng suốt 1 năm**. Khách cả năm không cập nhật →
lần cập nhật sau sẽ cần token mới.

### 6.4 Thu hồi

**Settings → Developer settings → Personal access tokens (classic)** → chọn token của
khách đó → **Delete**. Có hiệu lực ngay, và **chỉ khách đó** bị ảnh hưởng (đây là lý do
nên cấp riêng từng khách thay vì dùng chung một token).

Thu hồi **không** làm sập hệ thống đang chạy của khách — chỉ chặn tải bản mới.

### 6.5 Giao token cho khách

Gửi kèm lệnh đã điền sẵn token, dặn khách dán nguyên văn:

```bash
cd ~ && curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/ubuntu.sh \
  | GHCR_TOKEN=ghp_xxxxxxxxxxxx bash
```

Dùng dạng `GHCR_TOKEN=` (biến môi trường) thay vì `--ghcr-token` — token không lọt vào
`~/.bash_history` và không hiện trong `ps` của người dùng khác trên máy.

Nên gửi qua kênh riêng (Zalo cá nhân/email), **không** đăng lên nhóm chat chung.
