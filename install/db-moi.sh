#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# DỰNG DATABASE TRẮNG cho máy mới cài — chạy SAU install/erp.sh.
#
#   Tự chạy: install/erp.sh gọi script này khi database chưa có bảng `migrations`
#   (hoặc còn tệp đánh dấu .db-moi-chua-xong của lần dở). Chạy tay cũng được:
#   curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/db-moi.sh | bash
#
# Vì sao có script này: bộ cài chưa dựng được DB trắng với ảnh backend sau 055 —
# backend mới từ chối boot vì 6 migration một chiều đang chờ, mà migration một chiều
# đầu tiên lại đòi `general.timezone` (DB trắng chưa có bảng nào). Đi vòng y như lần
# cài lại Quảng Trị 17/11/2026:
#   1. boot backend `latest` đóng băng → tạo 122 migration gốc + dữ liệu mẫu
#   2. ghi general.timezone
#   3. 6 lượt oneway-migrate
#   4. dựng vai trcf_app/trcf_bypass + phase4-preflight + ghi .env
#   5. boot-migrate + phase4-gate + up
#
# Chạy lại nhiều lần vô hại: bước nào xong rồi thì bỏ qua. .env đã có DB_APP_USER
# (đã dựng xong, hoặc quán cũ) ⇒ chỉ bật hệ thống + in thông tin.
#
# Tuỳ chọn:  --dir /duong/dan   thư mục cài (mặc định ~/fnberp)
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

INSTALL_DIR="${TRCF_DIR:-$HOME/fnberp}"
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) INSTALL_DIR="${2:-}"; shift 2 ;;
    *) printf 'Tham số lạ: %s\n' "$1" >&2; exit 1 ;;
  esac
done

step() { printf '\n\033[1;36m▶ %s\033[0m\n' "$*"; }
ok()   { printf '  \033[1;32m✓\033[0m %s\n' "$*"; }
info() { printf '  \033[0;90m%s\033[0m\n' "$*"; }
die()  { printf '\n\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

cd "$INSTALL_DIR" 2>/dev/null || die "Không thấy $INSTALL_DIR — chạy install/erp.sh trước."
[ -f .env ] || die "Thiếu $INSTALL_DIR/.env — chạy install/erp.sh trước."

# Script chạy qua `curl | bash` ⇒ stdin là chính nội dung script. MỌI lệnh docker
# phải `</dev/null`, nếu không nó nuốt phần script còn lại.
if docker info >/dev/null 2>&1; then
  SUDO=""
else
  sudo -v </dev/tty 2>/dev/null || sudo -n true 2>/dev/null || die "Cần quyền docker hoặc sudo."
  SUDO="sudo"
fi
DOCKER="$SUDO docker"
dc()  { $DOCKER compose "$@" </dev/null; }
run() { $DOCKER compose run -T --rm --no-deps --pull never "$@" </dev/null; }

envv() { { grep -E "^$1=" .env || true; } | tail -1 | cut -d= -f2-; }

# Bước cài (erp.sh) phải đã tải được ảnh — không thì lỗi nằm ở phía trên, đừng chạy tiếp.
for img in $(dc config --images 2>/dev/null | grep trcf-erp); do
  $DOCKER image inspect "$img" >/dev/null 2>&1 \
    || die "Chưa có ảnh $img — bước cài phía trên chưa tải được phần mềm. Sửa lỗi đó rồi chạy lại."
done
DBU="$(envv DB_USER)"; DBU="${DBU:-trcf}"
DBN="$(envv DB_NAME)"; DBN="${DBN:-trcf_erp}"
DBPW="$(envv DB_PASSWORD)"
[ -n "$DBPW" ] || die ".env thiếu DB_PASSWORD."
sql() { dc exec -T postgres psql -U "$DBU" -d "$DBN" -v ON_ERROR_STOP=1 -At -c "$1"; }

wait_backend_log() {  # chờ câu log backend đã lên, tối đa 10 phút
  for i in $(seq 1 120); do
    dc logs backend 2>&1 | grep -q 'Backend đang chạy' && return 0
    sleep 5
    [ $((i % 6)) -eq 0 ] && info "… vẫn đang chờ backend ($((i * 5))s)"
  done
  return 1
}

if ! grep -q '^DB_APP_USER=' .env; then
  # Đánh dấu "đang dựng" — erp.sh chạy lại sẽ thấy tệp này và gọi tiếp db-moi.sh.
  touch .db-moi-chua-xong
  # ── 0. Postgres phải chạy ──
  step "Bật Postgres"
  dc up -d postgres >/dev/null 2>&1 || die "Không bật được postgres: cd $INSTALL_DIR && docker compose logs postgres"
  for i in $(seq 1 30); do
    dc exec -T postgres pg_isready -U "$DBU" -d "$DBN" >/dev/null 2>&1 && break
    sleep 2
  done
  ok "Postgres sẵn sàng"

  # ── 1. 122 migration gốc bằng backend latest đóng băng ──
  MIG="$(sql "select count(*) from migrations" 2>/dev/null || echo 0)"
  # Chốt an toàn: quán ĐANG BÁN (có đơn) không phải máy mới — migration một chiều ở quán
  # thật phải đi quy trình cửa sổ có sao lưu + cửa kiểm (docs/README-CHI-TIET.md §7).
  if [ "${MIG:-0}" -gt 0 ]; then
    ORD="$(sql "select count(*) from orders" 2>/dev/null || echo 0)"
    [ "${ORD:-0}" = 0 ] || { rm -f .db-moi-chua-xong; die "Database đã có $ORD đơn hàng — đây không phải máy mới. Dừng, không đụng gì."; }
  fi
  if [ "${MIG:-0}" -lt 122 ]; then
    step "Tạo bảng gốc bằng bản backend cũ (1–3 phút)"
    # `sudo` xoá biến môi trường ⇒ truyền qua `env` SAU sudo.
    $SUDO env BACKEND_IMAGE_TAG=latest docker compose up -d --no-deps backend </dev/null >/dev/null 2>&1 \
      || die "Không bật được backend latest: docker compose logs backend"
    wait_backend_log || die "Quá 10 phút backend latest chưa lên. Xem: cd $INSTALL_DIR && docker compose logs backend"
    MIG="$(sql "select count(*) from migrations")"
    dc stop backend >/dev/null 2>&1
    [ "$MIG" = 122 ] || die "Số migration sau bước này là $MIG, phải là 122 — dừng, gửi nhà cung cấp."
    ok "Đã tạo 122 migration gốc"
  else
    ok "Bảng gốc đã có ($MIG migration) — bỏ qua"
    dc stop backend >/dev/null 2>&1 || true
  fi

  # ── 2. Múi giờ quán ──
  step "Múi giờ quán"
  if [ "$(sql "select count(*) from system_settings where module='general' and key='timezone'")" = 0 ]; then
    sql "INSERT INTO system_settings (module, key, value, value_type, description) VALUES ('general','timezone','Asia/Ho_Chi_Minh','str','Múi giờ quán (IANA) — đặt lúc mở quán')" >/dev/null
    ok "Đã đặt Asia/Ho_Chi_Minh"
  else
    ok "Đã có: $(sql "select value from system_settings where module='general' and key='timezone'")"
  fi

  # ── 3. Sáu migration một chiều (chạy lại = "đã chạy", vô hại) ──
  step "Nâng cấu trúc database (6 lượt)"
  for m in TimestamptzEverywhere1783741000000 BigintLargeTables1783741100000 \
           AddShopIdColumns1783741200000 CompositeKeys1783741400000 \
           ExternalRefsAndZaloAppShops1783741500000 TenantScopedUniques1783741600000; do
    run backend node dist/oneway-migrate "$m" >/tmp/trcf-oneway.log 2>&1 \
      || { cat /tmp/trcf-oneway.log >&2; die "Dừng ở $m"; }
    ok "$m"
  done
  rm -f /tmp/trcf-oneway.log

  # ── 4. Vai database ──
  step "Tạo vai database cho backend"
  APP_PW="$(openssl rand -hex 24)"; BYP_PW="$(openssl rand -hex 24)"
  run -e ADMIN_DATABASE_URL="postgresql://$DBU:$DBPW@postgres:5432/$DBN" \
      -e DB_APP_PASSWORD="$APP_PW" -e DB_BYPASS_PASSWORD="$BYP_PW" \
      backend node dist/setup-db-roles >/tmp/trcf-roles.log 2>&1 \
    || { cat /tmp/trcf-roles.log >&2; die "setup-db-roles hỏng"; }
  rm -f /tmp/trcf-roles.log
  ( umask 077; printf 'BYP_PW=%s\n' "$BYP_PW" > trcf-bypass.secret )
  run -e DATABASE_URL="postgresql://trcf_app:$APP_PW@postgres:5432/$DBN" \
      backend node dist/phase4-preflight >/tmp/trcf-pf.log 2>&1 \
    || { cat /tmp/trcf-pf.log >&2; die "phase4-preflight không qua"; }
  rm -f /tmp/trcf-pf.log
  printf '\n# %s — backend chạy dưới vai app (RLS áp)\nDB_APP_USER=trcf_app\nDB_APP_PASSWORD=%s\n' \
    "$(date '+%F %T')" "$APP_PW" >> .env
  ok "Đã tạo vai trcf_app (mật khẩu vai quản trị: $INSTALL_DIR/trcf-bypass.secret)"

  # ── 5. Migration còn lại + kiểm ──
  step "Chạy migration còn lại + kiểm"
  run backend node dist/boot-migrate >/tmp/trcf-boot.log 2>&1 \
    || { cat /tmp/trcf-boot.log >&2; die "boot-migrate hỏng"; }
  run backend node dist/phase4-gate >/tmp/trcf-gate.log 2>&1 \
    || { cat /tmp/trcf-gate.log >&2; die "phase4-gate không qua"; }
  rm -f /tmp/trcf-boot.log /tmp/trcf-gate.log .db-moi-chua-xong
  ok "Database đã sẵn sàng ($(sql "select count(*) from migrations") migration)"
fi

# ── 6. Bật + chờ healthy ──
step "Bật hệ thống"
dc up -d --remove-orphans >/dev/null 2>&1 || true
READY="no"
for i in $(seq 1 60); do
  dc ps --format '{{.Service}} {{.Status}}' 2>/dev/null | grep -q '^frontend_app .*healthy' && { READY="yes"; break; }
  sleep 5
  [ $((i % 6)) -eq 0 ] && info "… vẫn đang khởi động ($((i * 5))s)"
done
dc ps --format '  {{.Service}}  {{.Status}}'
[ "$READY" = "yes" ] || die "Quá 5 phút chưa healthy. Xem: cd $INSTALL_DIR && docker compose logs --tail 100 backend"
rm -f .db-moi-chua-xong

# ── 7. In thông tin ──
URL="$(envv APP_URL)"; EMAIL="$(envv ADMIN_SEED_EMAIL)"; PASS="$(envv ADMIN_SEED_PASSWORD)"
( umask 077; cat > thong-tin-dang-nhap.txt <<EOF
TRCF ERP — thông tin cài đặt ($(date '+%F %T'))

Địa chỉ     : $URL
Tài khoản   : $EMAIL
Mật khẩu    : $PASS
Thư mục cài : $INSTALL_DIR

⚠️  ĐỪNG chạy 'docker compose down -v' — cờ -v xoá sạch dữ liệu.
EOF
)
printf '\n\033[1;32m╔══════════════════════════════════════════════════════════╗\033[0m\n'
printf '\033[1;32m║              TRCF ERP đã cài đặt xong                    ║\033[0m\n'
printf '\033[1;32m╚══════════════════════════════════════════════════════════╝\033[0m\n\n'
printf '  Mở trình duyệt   \033[1;36m%s\033[0m\n' "$URL"
printf '  Tài khoản        \033[1m%s\033[0m\n' "$EMAIL"
printf '  Mật khẩu         \033[1m%s\033[0m\n' "$PASS"
printf '\n  Đã lưu tại       %s/thong-tin-dang-nhap.txt\n\n' "$INSTALL_DIR"
