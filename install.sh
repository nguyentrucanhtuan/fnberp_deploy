#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# TRCF ERP — Cài đặt tự động (kéo ảnh từ GHCR private, KHÔNG cần source)
#
# Dùng:
#   ./install.sh                      # hỏi token khi cần
#   GHCR_USER=... GHCR_TOKEN=... ./install.sh
#
# Token do NHÀ CUNG CẤP cấp (quyền read:packages) — chỉ để KÉO ẢNH, không thấy source.
# ─────────────────────────────────────────────────────────────
set -euo pipefail
cd "$(dirname "$0")"

GHCR_USER="${GHCR_USER:-}"
GHCR_TOKEN="${GHCR_TOKEN:-}"

say()  { printf '\033[1;36m>> %s\033[0m\n' "$*"; }
err()  { printf '\033[1;31m!! %s\033[0m\n' "$*" >&2; }

# 1. Kiểm tra Docker
command -v docker >/dev/null 2>&1 || { err "Chưa cài Docker. Cài Docker Engine trước."; exit 1; }
docker compose version >/dev/null 2>&1 || { err "Cần Docker Compose v2 (docker compose)."; exit 1; }

# 2. Đăng nhập GHCR để kéo ảnh private
say "Đăng nhập GitHub Container Registry (ghcr.io)"
if [ -z "$GHCR_TOKEN" ]; then
  read -rp "  Tài khoản (nhà cung cấp cấp): " GHCR_USER
  read -rsp "  Token (read:packages): " GHCR_TOKEN; echo
fi
echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin \
  || { err "Đăng nhập thất bại — kiểm tra lại tài khoản/token."; exit 1; }

# 3. Cấu hình .env
if [ ! -f .env ]; then
  cp .env.example .env
  say "Đã tạo .env từ mẫu."
  err "HÃY MỞ .env điền: DB_PASSWORD, JWT_SECRET, AUTH_SECRET, ADMIN_SEED_EMAIL/PASSWORD"
  err "Gợi ý sinh khoá:  openssl rand -hex 32"
  err "Điền xong chạy lại: ./install.sh"
  exit 0
fi

# 4. Kéo ảnh mới nhất + chạy
say "Kéo ảnh mới nhất từ GHCR..."
docker compose pull
say "Khởi động..."
docker compose up -d
say "Trạng thái:"
docker compose ps

FE_PORT="$(grep -E '^FRONTEND_PORT=' .env | cut -d= -f2 || true)"; FE_PORT="${FE_PORT:-3000}"
say "Xong! Mở giao diện: http://localhost:${FE_PORT}"
say "Đăng nhập bằng ADMIN_SEED_EMAIL / ADMIN_SEED_PASSWORD trong .env"
