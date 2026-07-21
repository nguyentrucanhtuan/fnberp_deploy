#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# BƯỚC 1/2 — CÀI DOCKER (Ubuntu / Debian)
#
#   curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/docker.sh | bash
#
# Chỉ làm đúng một việc: cài Docker Engine + Docker Compose plugin từ repo
# CHÍNH THỨC của Docker, bật dịch vụ, thêm tài khoản hiện tại vào nhóm docker.
# KHÔNG đụng gì tới TRCF ERP — cài ERP là bước 2 (install/erp.sh).
#
# Máy đã có Docker sẵn thì script tự nhận ra và bỏ qua.
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

step() { printf '\n\033[1;36m▶ %s\033[0m\n' "$*"; }
ok()   { printf '  \033[1;32m✓\033[0m %s\n' "$*"; }
info() { printf '  \033[0;90m%s\033[0m\n' "$*"; }
die()  { printf '\n\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

# ── Kiểm tra môi trường ────────────────────────────────────────────────────
step "Kiểm tra máy chủ"

[ -r /etc/os-release ] || die "Không đọc được /etc/os-release — script chỉ hỗ trợ Ubuntu/Debian."
# shellcheck disable=SC1091
. /etc/os-release
case "${ID:-}${ID_LIKE:-}" in
  *ubuntu*|*debian*) : ;;
  *) die "Chỉ hỗ trợ Ubuntu/Debian (máy này: ${PRETTY_NAME:-không rõ}). Distro khác: cài Docker theo hướng dẫn của Docker rồi chạy thẳng bước 2." ;;
esac
ok "Hệ điều hành: ${PRETTY_NAME:-$ID}"

if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  command -v sudo >/dev/null 2>&1 || die "Cần quyền root hoặc sudo để cài Docker."
  SUDO="sudo"
  $SUDO -v </dev/tty 2>/dev/null || $SUDO -n true 2>/dev/null \
    || die "Cần sudo. Chạy lại bằng: curl -fsSL <url> | sudo bash"
fi

# ── Cài Docker ─────────────────────────────────────────────────────────────
step "Docker Engine + Docker Compose"

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  ok "Máy đã có sẵn ($(docker --version | cut -d, -f1)) — bỏ qua bước cài"
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
  ok "Đã thêm khoá ký của Docker"

  CODENAME="${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}"
  [ -n "$CODENAME" ] || die "Không xác định được mã phiên bản hệ điều hành."
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DOCKER_REPO_ID} ${CODENAME} stable" \
    | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null
  ok "Đã thêm repo Docker ($DOCKER_REPO_ID $CODENAME)"

  $SUDO apt-get update -qq
  $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null
  ok "Đã cài $(docker --version | cut -d, -f1)"
fi

# ── Bật dịch vụ ────────────────────────────────────────────────────────────
$SUDO systemctl enable --now docker >/dev/null 2>&1 || true

# ── Nhóm docker (để lần sau gõ docker không cần sudo) ──────────────────────
NEED_RELOGIN="no"
if [ -n "$SUDO" ] && ! id -nG "$USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
  $SUDO usermod -aG docker "$USER" || true
  NEED_RELOGIN="yes"
  ok "Đã thêm '$USER' vào nhóm docker"
fi

# ── Kiểm chứng ─────────────────────────────────────────────────────────────
step "Kiểm chứng"

if docker info >/dev/null 2>&1; then DOCKER="docker"; else DOCKER="$SUDO docker"; fi
$DOCKER info >/dev/null 2>&1 \
  || die "Docker đã cài nhưng chưa chạy được. Kiểm tra: sudo systemctl status docker"
ok "Docker Engine chạy tốt"
$DOCKER compose version >/dev/null 2>&1 || die "Thiếu Docker Compose plugin."
ok "Docker Compose: $($DOCKER compose version | head -1)"

printf '\n\033[1;32m✓ BƯỚC 1 XONG — Docker đã sẵn sàng\033[0m\n\n'
if [ "$NEED_RELOGIN" = "yes" ]; then
printf '  \033[1;33mLưu ý: đăng xuất rồi đăng nhập lại (hoặc gõ: newgrp docker) để dùng\n'
printf '  lệnh docker mà không cần sudo. Không làm cũng được — bước 2 tự xoay xở.\033[0m\n\n'
fi
printf '  Tiếp bước 2 — cài TRCF ERP:\n\n'
printf '    \033[1;36mcurl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/erp.sh \\\n'
printf '      | GHCR_TOKEN=<token> bash\033[0m\n\n'
