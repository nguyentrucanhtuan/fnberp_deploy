# TRCF ERP — Cài đặt (bản giao khách)

Ứng dụng chạy bằng **ảnh Docker dựng sẵn** kéo từ GitHub Container Registry (GHCR).
Khách **không cần build, không có source** — chỉ đăng nhập bằng token nhà cung cấp cấp, rồi chạy.

```
trcf_deploy/
├── install.sh            # cài tự động (1 lệnh)
├── docker-compose.yml    # điều phối backend + frontend (chỉ tham chiếu ảnh GHCR)
├── .env.example          # mẫu cấu hình
└── README.md
```

## Yêu cầu
- Docker + Docker Compose v2.
- Một database Postgres (Neon hoặc tự dựng) + chuỗi kết nối.
- **Tài khoản + token** do nhà cung cấp cấp (chỉ quyền `read:packages` — kéo ảnh, KHÔNG thấy source).

## Cài đặt (2 lần chạy install.sh)

```bash
# Lần 1 — đăng nhập + tạo .env
GHCR_USER=<tài-khoản> GHCR_TOKEN=<token> ./install.sh
#  → script tạo .env, rồi bảo bạn điền cấu hình

nano .env          # điền DATABASE_URL, JWT_SECRET, AUTH_SECRET, ADMIN_SEED_EMAIL/PASSWORD
openssl rand -hex 32   # sinh JWT_SECRET và AUTH_SECRET (mỗi cái một giá trị)

# Lần 2 — kéo ảnh + chạy
./install.sh
```

→ Mở **http://localhost:3000**, đăng nhập bằng `ADMIN_SEED_EMAIL` / `ADMIN_SEED_PASSWORD`.
Lần chạy đầu backend tự tạo bảng + tài khoản quản trị + nhóm quyền mẫu.

## Cập nhật phiên bản mới (CI/CD)
Nhà cung cấp push code → GitHub tự build ảnh mới lên GHCR. Khách chỉ cần:
```bash
./install.sh          # tự kéo ảnh :latest mới nhất rồi up lại (dữ liệu DB giữ nguyên)
# hoặc:  docker compose pull && docker compose up -d
```

## Vận hành
```bash
docker compose ps         # trạng thái + health
docker compose logs -f    # xem log
docker compose down       # dừng
docker compose up -d      # chạy lại
```

## Đưa ra internet (domain + HTTPS)
Đặt sau reverse-proxy (Caddy/Nginx) để có TLS; đổi `APP_URL` trong `.env` sang domain thật.
Backend (3333) chỉ để nội bộ, không publish ra ngoài.
