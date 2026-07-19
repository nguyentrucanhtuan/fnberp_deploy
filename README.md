# TRCF ERP — Cài đặt (bản giao khách)

Ứng dụng chạy bằng **ảnh Docker dựng sẵn** kéo từ GitHub Container Registry (GHCR),
kèm **Postgres chạy luôn trong Docker** — stack tự-chứa, **không cần Neon/DB ngoài**.
Khách **không cần build, không có source** — chỉ đăng nhập bằng token nhà cung cấp cấp, rồi chạy.

```
trcf_deploy/
├── install.sh            # cài tự động (1 lệnh)
├── docker-compose.yml    # frontend + backend + Postgres (kéo ảnh GHCR)
├── .env.example          # mẫu cấu hình
└── README.md
```

## Yêu cầu
- Docker + Docker Compose v2.
- **Tài khoản + token** do nhà cung cấp cấp (chỉ quyền `read:packages` — kéo ảnh, KHÔNG thấy source).
- KHÔNG cần DB ngoài — Postgres chạy sẵn trong stack, dữ liệu lưu ở volume `pgdata`.

## Cài đặt (2 lần chạy install.sh)

```bash
# Lần 1 — đăng nhập + tạo .env
GHCR_USER=<tài-khoản> GHCR_TOKEN=<token> ./install.sh
#  → script tạo .env, rồi bảo bạn điền cấu hình

nano .env              # điền DB_PASSWORD, JWT_SECRET, AUTH_SECRET, ADMIN_SEED_EMAIL/PASSWORD
openssl rand -hex 32   # sinh JWT_SECRET và AUTH_SECRET (mỗi cái một giá trị)

# Lần 2 — kéo ảnh + chạy
./install.sh
```

→ Mở **http://localhost:3000**, đăng nhập bằng `ADMIN_SEED_EMAIL` / `ADMIN_SEED_PASSWORD`.
Lần chạy đầu backend tự tạo bảng + tài khoản quản trị + nhóm quyền mẫu (trên Postgres Docker trống).

## Cập nhật phiên bản mới (CI/CD)
Nhà cung cấp push code → GitHub tự build ảnh mới lên GHCR. Khách chỉ cần:
```bash
./install.sh          # tự kéo ảnh :latest mới nhất rồi up lại (dữ liệu DB giữ nguyên)
# hoặc:  docker compose pull && docker compose up -d
```

## Sao lưu dữ liệu (QUAN TRỌNG)
Dữ liệu nằm trong volume `pgdata`. Tự-host Postgres nghĩa là **bạn tự sao lưu**:
```bash
# Sao lưu ra file (dùng DB_USER/DB_NAME mặc định: trcf / trcf_erp)
docker compose exec -T postgres pg_dump -U trcf trcf_erp | gzip > backup-$(date +%F).sql.gz
# Phục hồi
gunzip -c backup-YYYY-MM-DD.sql.gz | docker compose exec -T postgres psql -U trcf trcf_erp
```
⚠️ Đừng chạy `docker compose down -v` — cờ `-v` **xoá volume = mất sạch dữ liệu**.

## Vận hành
```bash
docker compose ps         # trạng thái + health
docker compose logs -f    # xem log
docker compose down       # dừng (GIỮ dữ liệu)
docker compose up -d      # chạy lại
```

## Đưa ra internet (domain + HTTPS)
Đặt sau reverse-proxy (Caddy/Nginx) để có TLS; đổi `APP_URL` trong `.env` sang domain thật.
Backend (3333) và Postgres chỉ chạy nội bộ, không publish ra ngoài.
