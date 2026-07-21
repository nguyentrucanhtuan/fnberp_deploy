#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# TRCF ERP — CÀI ĐẶT TỰ ĐỘNG (Ubuntu / Debian)
#
#   cd ~ && curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/ubuntu.sh \
#     | GHCR_TOKEN=<token-nhà-cung-cấp-cấp> bash
#
# Ảnh phần mềm để ở chế độ RIÊNG TƯ nên cần token để tải về (chỉ quyền đọc gói —
# KHÔNG xem được mã nguồn). Token do nhà cung cấp cấp cho từng khách hàng.
#
# Script tự làm HẾT:
#   1. Cài Docker Engine + Docker Compose plugin (repo chính thức của Docker)
#   2. Đăng nhập kho ảnh bằng token
#   3. Tải bộ cấu hình về ~/fnberp
#   4. Sinh .env (mật khẩu DB + JWT_SECRET + AUTH_SECRET ngẫu nhiên)
#   5. Kéo ảnh rồi khởi động cả stack
#   6. In ra địa chỉ truy cập + tài khoản quản trị
#
# Tuỳ chọn (đặt sau `bash -s --`):
#   --ghcr-token <token>      token tải phần mềm (hoặc đặt biến GHCR_TOKEN — an toàn hơn,
#                             không lưu vào lịch sử lệnh)
#   --ghcr-user <tài-khoản>   tài khoản kho ảnh (mặc định nguyentrucanhtuan)
#   --domain erp.quan.vn      dùng domain thật + tự cấp HTTPS (Let's Encrypt)
#   --dir /duong/dan          thư mục cài (mặc định ~/fnberp)
#   --admin-email a@b.vn      email quản trị (mặc định admin@trcf.vn)
#   --admin-password 'xxx'    mật khẩu quản trị (mặc định sinh ngẫu nhiên)
#   --http-port 8080          đổi cổng HTTP nếu 80 đã bị chiếm
#   --tag v1.2.3              cài đúng phiên bản ảnh (mặc định latest)
#   --update                  chỉ cập nhật bản mới, giữ nguyên .env + dữ liệu
#
# Ví dụ có domain:
#   curl -fsSL <url> | GHCR_TOKEN=xxx bash -s -- --domain erp.quan.vn
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Nguồn tải cấu hình (đổi được khi tự fork) ──────────────────────────────
RAW_BASE="${TRCF_RAW_BASE:-https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main}"

# ── Tham số ────────────────────────────────────────────────────────────────
INSTALL_DIR="${TRCF_DIR:-$HOME/fnberp}"
DOMAIN=""
ADMIN_EMAIL="admin@trcf.vn"
ADMIN_PASSWORD=""
HTTP_PORT="80"
HTTPS_PORT="443"
IMAGE_TAG="latest"
UPDATE_ONLY="no"
# Token có thể truyền qua biến môi trường (không lọt vào lịch sử lệnh / danh sách tiến trình).
GHCR_TOKEN="${GHCR_TOKEN:-}"
GHCR_USER="${GHCR_USER:-nguyentrucanhtuan}"

while [ $# -gt 0 ]; do
  case "$1" in
    --ghcr-token)     GHCR_TOKEN="${2:-}"; shift 2 ;;
    --ghcr-user)      GHCR_USER="${2:-}"; shift 2 ;;
    --domain)         DOMAIN="${2:-}"; shift 2 ;;
    --dir)            INSTALL_DIR="${2:-}"; shift 2 ;;
    --admin-email)    ADMIN_EMAIL="${2:-}"; shift 2 ;;
    --admin-password) ADMIN_PASSWORD="${2:-}"; shift 2 ;;
    --http-port)      HTTP_PORT="${2:-}"; shift 2 ;;
    --https-port)     HTTPS_PORT="${2:-}"; shift 2 ;;
    --tag)            IMAGE_TAG="${2:-}"; shift 2 ;;
    --update)         UPDATE_ONLY="yes"; shift ;;
    -h|--help)        sed -n '2,30p' "$0" 2>/dev/null || true; exit 0 ;;
    *) printf 'Tham số lạ: %s\n' "$1" >&2; exit 1 ;;
  esac
done

# ── Tiện ích in ────────────────────────────────────────────────────────────
step() { printf '\n\033[1;36m▶ %s\033[0m\n' "$*"; }
ok()   { printf '  \033[1;32m✓\033[0m %s\n' "$*"; }
info() { printf '  \033[0;90m%s\033[0m\n' "$*"; }
warn() { printf '  \033[1;33m!\033[0m %s\n' "$*"; }
die()  { printf '\n\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

# ── 0. Kiểm tra môi trường ─────────────────────────────────────────────────
step "Kiểm tra máy chủ"

[ -r /etc/os-release ] || die "Không đọc được /etc/os-release — script chỉ hỗ trợ Ubuntu/Debian."
# shellcheck disable=SC1091
. /etc/os-release
case "${ID:-}${ID_LIKE:-}" in
  *ubuntu*|*debian*) : ;;
  *) die "Chỉ hỗ trợ Ubuntu/Debian (máy này: ${PRETTY_NAME:-không rõ}). Với distro khác: cài Docker thủ công rồi chạy docker compose theo README." ;;
esac
ok "Hệ điều hành: ${PRETTY_NAME:-$ID}"

if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  command -v sudo >/dev/null 2>&1 || die "Cần quyền root hoặc sudo để cài Docker."
  SUDO="sudo"
  # Xin quyền một lần ngay từ đầu (curl|bash không có stdin để hỏi giữa chừng).
  $SUDO -v </dev/tty 2>/dev/null || $SUDO -n true 2>/dev/null \
    || die "Cần sudo. Chạy lại bằng: curl -fsSL <url> | sudo bash"
fi

for c in curl openssl; do
  command -v "$c" >/dev/null 2>&1 || MISSING="${MISSING:-} $c"
done
if [ -n "${MISSING:-}" ]; then
  info "Cài gói còn thiếu:${MISSING}"
  $SUDO apt-get update -qq
  # shellcheck disable=SC2086
  $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $MISSING >/dev/null
fi
ok "Công cụ cơ bản sẵn sàng"

# ── 1. Cài Docker Engine + Compose plugin ──────────────────────────────────
step "Docker Engine + Docker Compose"

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  ok "Đã có sẵn ($(docker --version | cut -d, -f1))"
else
  info "Cài từ repo chính thức của Docker (mất 1–2 phút)…"
  $SUDO apt-get update -qq
  $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    ca-certificates curl gnupg >/dev/null

  $SUDO install -m 0755 -d /etc/apt/keyrings
  DOCKER_REPO_ID="$ID"
  case "$ID" in ubuntu|debian) : ;; *) DOCKER_REPO_ID="ubuntu" ;; esac
  curl -fsSL "https://download.docker.com/linux/${DOCKER_REPO_ID}/gpg" \
    | $SUDO gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
  $SUDO chmod a+r /etc/apt/keyrings/docker.gpg

  CODENAME="${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}"
  [ -n "$CODENAME" ] || die "Không xác định được mã phiên bản hệ điều hành."
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DOCKER_REPO_ID} ${CODENAME} stable" \
    | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null

  $SUDO apt-get update -qq
  $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null
  ok "Đã cài $(docker --version | cut -d, -f1)"
fi

$SUDO systemctl enable --now docker >/dev/null 2>&1 || true

# Thêm user hiện tại vào nhóm docker (có hiệu lực ở phiên đăng nhập SAU).
NEED_RELOGIN="no"
if [ -n "$SUDO" ] && ! id -nG "$USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
  $SUDO usermod -aG docker "$USER" || true
  NEED_RELOGIN="yes"
  info "Đã thêm '$USER' vào nhóm docker (cần đăng nhập lại để dùng docker không cần sudo)."
fi

# Trong phiên NÀY nhóm mới chưa hiệu lực → dùng sudo cho mọi lệnh docker.
if docker info >/dev/null 2>&1; then DOCKER="docker"; else DOCKER="$SUDO docker"; fi
$DOCKER info >/dev/null 2>&1 || die "Docker đã cài nhưng chưa chạy được. Thử: sudo systemctl status docker"
ok "Docker sẵn sàng"

# ── 2. Tải bộ cấu hình ─────────────────────────────────────────────────────
step "Bộ cấu hình → $INSTALL_DIR"

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

for f in docker-compose.yml Caddyfile .env.example; do
  curl -fsSL "$RAW_BASE/$f" -o "$f.new" \
    || die "Không tải được $f từ $RAW_BASE (kiểm tra mạng)."
  mv "$f.new" "$f"
done
ok "Đã tải docker-compose.yml, Caddyfile, .env.example"

# ── 3. Sinh .env ───────────────────────────────────────────────────────────
step "Cấu hình (.env)"

# Địa chỉ LAN để các máy khác trong cùng wifi truy cập được.
LAN_IP="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -1)"
[ -n "$LAN_IP" ] || LAN_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
[ -n "$LAN_IP" ] || LAN_IP="localhost"

if [ -n "$DOMAIN" ]; then
  SITE_ADDRESS="$DOMAIN"                       # Caddy tự xin chứng chỉ HTTPS
  PUBLIC_URL="https://$DOMAIN"
else
  SITE_ADDRESS=":80"                           # HTTP thuần trong LAN
  PUBLIC_URL="http://$LAN_IP"
  [ "$HTTP_PORT" = "80" ] || PUBLIC_URL="http://$LAN_IP:$HTTP_PORT"
fi

if [ -f .env ]; then
  ok "Đã có .env — GIỮ NGUYÊN (không ghi đè mật khẩu/secret cũ)"
  KEPT_ENV="yes"
  # Giữ tài khoản admin cũ để in lại cuối script.
  ADMIN_EMAIL="$(grep -E '^ADMIN_SEED_EMAIL=' .env | cut -d= -f2- || echo "$ADMIN_EMAIL")"
  ADMIN_PASSWORD="$(grep -E '^ADMIN_SEED_PASSWORD=' .env | cut -d= -f2- || echo '')"

  if [ -n "$DOMAIN" ]; then
    # Chạy lại kèm --domain = ĐỔI địa chỉ truy cập (giữ nguyên mọi secret).
    sed -i "s|^SITE_ADDRESS=.*|SITE_ADDRESS=$SITE_ADDRESS|" .env
    sed -i "s|^APP_URL=.*|APP_URL=$PUBLIC_URL|" .env
    ok "Đã chuyển sang domain $DOMAIN (Caddy sẽ tự xin chứng chỉ HTTPS)"
  else
    # Không đổi gì → in đúng địa chỉ đang cấu hình trong .env, không đoán lại.
    ENV_APP_URL="$(grep -E '^APP_URL=' .env | cut -d= -f2- || echo '')"
    [ -n "$ENV_APP_URL" ] && PUBLIC_URL="$ENV_APP_URL"
  fi
else
  KEPT_ENV="no"
  [ -n "$ADMIN_PASSWORD" ] || ADMIN_PASSWORD="$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9' | cut -c1-14)"
  umask 077
  cat > .env <<EOF
# TRCF ERP — sinh tự động bởi install/ubuntu.sh lúc $(date '+%F %T')
# ⚠️  File này chứa mật khẩu + khoá bí mật. KHÔNG chia sẻ, KHÔNG commit.

# ── Truy cập ──
SITE_ADDRESS=$SITE_ADDRESS
HTTP_PORT=$HTTP_PORT
HTTPS_PORT=$HTTPS_PORT
APP_URL=$PUBLIC_URL

# ── Phiên bản ảnh ──
IMAGE_TAG=$IMAGE_TAG

# ── Database (Postgres chạy trong Docker, dữ liệu ở volume pgdata) ──
DB_USER=trcf
DB_NAME=trcf_erp
DB_PASSWORD=$(openssl rand -hex 24)

# ── Khoá bí mật (sinh ngẫu nhiên, mỗi máy một giá trị) ──
JWT_SECRET=$(openssl rand -hex 32)
JWT_EXPIRES=8h
AUTH_SECRET=$(openssl rand -hex 32)

# ── Tài khoản quản trị đầu tiên ──
ADMIN_SEED_EMAIL=$ADMIN_EMAIL
ADMIN_SEED_PASSWORD=$ADMIN_PASSWORD

# ── Email (mặc định 'log' = in ra log, không gửi thật) ──
MAIL_DRIVER=log
MAIL_FROM=onboarding@resend.dev
RESEND_API_KEY=

# ── AI marketing (tuỳ chọn) ──
LLM_PROVIDER=gemini
GEMINI_API_KEY=
GEMINI_MODEL=gemini-2.5-flash

# ── Zalo Mini App (tuỳ chọn) ──
ZALO_APP_SECRET=
EOF
  chmod 600 .env
  ok "Đã sinh .env (mật khẩu DB + JWT_SECRET + AUTH_SECRET ngẫu nhiên)"
fi

# Cập nhật tag ảnh khi chạy với --tag / --update
if [ "$IMAGE_TAG" != "latest" ] || [ "$UPDATE_ONLY" = "yes" ]; then
  if grep -qE '^IMAGE_TAG=' .env; then
    sed -i "s|^IMAGE_TAG=.*|IMAGE_TAG=$IMAGE_TAG|" .env
  else
    echo "IMAGE_TAG=$IMAGE_TAG" >> .env
  fi
fi

# ── 4. Mở cổng tường lửa (nếu ufw đang bật) ────────────────────────────────
if command -v ufw >/dev/null 2>&1 && $SUDO ufw status 2>/dev/null | grep -q 'Status: active'; then
  step "Tường lửa (ufw)"
  $SUDO ufw allow "$HTTP_PORT/tcp" >/dev/null 2>&1 && ok "Mở cổng $HTTP_PORT/tcp"
  if [ -n "$DOMAIN" ]; then
    $SUDO ufw allow "$HTTPS_PORT/tcp" >/dev/null 2>&1 && ok "Mở cổng $HTTPS_PORT/tcp"
  fi
fi

# ── 5. Đăng nhập kho ảnh ───────────────────────────────────────────────────
# Ảnh riêng tư → cần token quyền ĐỌC GÓI. Docker lưu lại thông tin đăng nhập nên
# những lần cập nhật sau thường không phải nhập lại.
if [ -n "$GHCR_TOKEN" ]; then
  step "Đăng nhập kho ảnh"
  printf '%s' "$GHCR_TOKEN" | $DOCKER login ghcr.io -u "$GHCR_USER" --password-stdin >/dev/null 2>&1 \
    || die "Token không hợp lệ hoặc đã bị thu hồi. Liên hệ nhà cung cấp để lấy token mới."
  ok "Đã đăng nhập"

  # Lệnh trên chạy dưới quyền root (qua sudo) → thông tin đăng nhập nằm ở
  # /root/.docker/config.json (đã đo: sudo đặt HOME=/root trên Ubuntu).
  # Sau khi khách đăng nhập lại và vào nhóm docker, họ gõ `docker compose pull`
  # bằng TÀI KHOẢN RIÊNG → phải có bản sao trong home của họ, nếu không sẽ báo
  # "denied" dù token vẫn còn hiệu lực.
  REAL_USER="${SUDO_USER:-$(id -un)}"
  REAL_HOME="$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6 || true)"
  ROOT_CFG="/root/.docker/config.json"
  if [ -n "$REAL_HOME" ] && [ "$REAL_HOME" != "/root" ] && $SUDO test -f "$ROOT_CFG"; then
    $SUDO mkdir -p "$REAL_HOME/.docker"
    # Giữ lại cấu hình cũ nếu máy đã từng đăng nhập kho ảnh khác.
    $SUDO test -f "$REAL_HOME/.docker/config.json" \
      && $SUDO cp "$REAL_HOME/.docker/config.json" "$REAL_HOME/.docker/config.json.bak" || true
    $SUDO cp "$ROOT_CFG" "$REAL_HOME/.docker/config.json"
    $SUDO chown -R "$REAL_USER:" "$REAL_HOME/.docker"
    $SUDO chmod 600 "$REAL_HOME/.docker/config.json"
    ok "Đã lưu cho tài khoản $REAL_USER — lần cập nhật sau không cần nhập token"
  fi
fi

# ── 6. Kéo ảnh + khởi động ─────────────────────────────────────────────────
step "Kéo phần mềm và khởi động (lần đầu ~2–4 phút)"

if ! $DOCKER compose pull --quiet 2>/tmp/trcf-pull-err; then
  if grep -qiE 'denied|unauthorized|authentication required' /tmp/trcf-pull-err 2>/dev/null; then
    rm -f /tmp/trcf-pull-err
    die "Chưa có quyền tải phần mềm. Chạy lại kèm token do nhà cung cấp cấp:

  curl -fsSL <đường-dẫn-script> | GHCR_TOKEN=<token> bash
"
  fi
  cat /tmp/trcf-pull-err >&2 || true
  rm -f /tmp/trcf-pull-err
  die "Không tải được phần mềm — kiểm tra kết nối mạng."
fi
rm -f /tmp/trcf-pull-err
ok "Đã tải backend + frontend + postgres + caddy"

$DOCKER compose up -d
ok "Đã khởi động"

# ── 7. Chờ hệ thống sẵn sàng ───────────────────────────────────────────────
step "Chờ hệ thống sẵn sàng (backend tạo bảng + tài khoản quản trị)"

READY="no"
for i in $(seq 1 60); do
  if $DOCKER compose ps --format '{{.Service}} {{.Status}}' 2>/dev/null \
      | grep -q '^frontend .*healthy'; then
    READY="yes"; break
  fi
  sleep 5
  [ $((i % 6)) -eq 0 ] && info "… vẫn đang khởi động ($((i * 5))s)"
done

if [ "$READY" = "yes" ]; then
  ok "Hệ thống đã sẵn sàng"
else
  warn "Quá 5 phút chưa thấy 'healthy'. Xem log: cd $INSTALL_DIR && $DOCKER compose logs -f"
fi

# ── 8. Ghi + in thông tin ──────────────────────────────────────────────────
CRED_FILE="$INSTALL_DIR/thong-tin-dang-nhap.txt"
umask 077
cat > "$CRED_FILE" <<EOF
TRCF ERP — thông tin cài đặt ($(date '+%F %T'))

Địa chỉ           : $PUBLIC_URL
Tài khoản         : $ADMIN_EMAIL
Mật khẩu          : ${ADMIN_PASSWORD:-(xem ADMIN_SEED_PASSWORD trong .env)}
Thư mục cài       : $INSTALL_DIR

Lệnh thường dùng (chạy trong $INSTALL_DIR):
  docker compose ps            # trạng thái
  docker compose logs -f       # xem log
  docker compose down          # dừng (GIỮ dữ liệu)
  docker compose up -d         # chạy lại

⚠️  Đổi mật khẩu quản trị ngay sau lần đăng nhập đầu.
⚠️  ĐỪNG chạy 'docker compose down -v' — cờ -v xoá sạch dữ liệu.
EOF
chmod 600 "$CRED_FILE"

printf '\n\033[1;32m╔══════════════════════════════════════════════════════════╗\033[0m\n'
printf '\033[1;32m║              TRCF ERP đã cài đặt xong                    ║\033[0m\n'
printf '\033[1;32m╚══════════════════════════════════════════════════════════╝\033[0m\n\n'
printf '  Mở trình duyệt   \033[1;36m%s\033[0m\n' "$PUBLIC_URL"
if [ -z "$DOMAIN" ]; then
printf '  Máy khác cùng wifi dùng đúng địa chỉ trên (điện thoại, tablet màn bếp)\n'
fi
printf '\n  Tài khoản        \033[1m%s\033[0m\n' "$ADMIN_EMAIL"
if [ "$KEPT_ENV" = "yes" ] && [ -z "$ADMIN_PASSWORD" ]; then
printf '  Mật khẩu         (giữ nguyên như lần cài trước)\n'
else
printf '  Mật khẩu         \033[1m%s\033[0m\n' "$ADMIN_PASSWORD"
fi
printf '\n  Đã lưu tại       %s\n' "$CRED_FILE"
printf '  Thư mục cài      %s\n' "$INSTALL_DIR"
printf '\n  \033[1;33mĐổi mật khẩu ngay sau lần đăng nhập đầu tiên.\033[0m\n'
if [ "$NEED_RELOGIN" = "yes" ]; then
printf '  \033[1;33mĐăng xuất/đăng nhập lại (hoặc: newgrp docker) để dùng lệnh docker không cần sudo.\033[0m\n'
fi
printf '\n'
