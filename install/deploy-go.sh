#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# CHUYỂN MỘT BẢN CÀI SANG BACKEND GO (chỉ chạy Go, NestJS dừng hẳn) — delta 061 deploy-go.
#
#   cd ~ && curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/deploy-go.sh \
#     | bash -s -- --go-tag sha-a1b2c3d
#
# Bộ NestJS (docker-compose.yml + install/erp.sh) KHÔNG đổi gì — vẫn là mặc định. Script này chạy trên một bản cài
# NestJS ĐANG CÓ (thư mục ~/fnberp, database đứng ở migration TypeORM 157), rồi:
#   1. kiểm đầu vào (tag ảnh, .env, database đúng mốc) — sai thì dừng, CHƯA đụng gì
#   2. bổ sung .env: JWT_SECRET_GO (secret riêng của Go), vai trcf_app nếu quán chưa tách vai
#   3. kéo ảnh Go (lỗi token/mạng thì dừng khi NestJS vẫn chạy)
#   4. dừng backend NestJS → pg_dump vào backups-go/ → đọc lại được mới đi tiếp
#   5. migrate bootstrap → migrate up → seed-shop → setup-db-roles
#   6. ghi COMPOSE_FILE=docker-compose.go.yml vào .env, bật bộ Go, chờ healthy
#
# Sau đó MỌI lệnh `docker compose …` trong thư mục cài tự nhắm bộ Go. Người dùng phải đăng nhập lại (secret khác).
#
# Tuỳ chọn:
#   --go-tag sha-xxxxxxx   ảnh ghcr.io/nguyentrucanhtuan/trcf-erp-backend-go (bắt buộc lần đầu; lần sau mặc định
#                          giữ tag trong .env). Chạy lại với tag mới = cập nhật bản Go (vẫn dump trước khi migrate).
#   --dir /duong/dan       thư mục cài (mặc định ~/fnberp)
#   --rollback             LÙI về NestJS (bản lưu sẵn: bash ~/fnberp/deploy-go.sh --rollback): xoá COMPOSE_FILE khỏi .env rồi bật lại bộ docker-compose.yml.
#                          Database giữ nguyên (NestJS bỏ qua bảng goose_db_version).
#
# Chạy lại nhiều lần vô hại: database đã bootstrap thì bỏ qua bước đó; migrate/seed/roles đều idempotent.
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

RAW_BASE="${TRCF_RAW_BASE:-https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main}"
INSTALL_DIR="${TRCF_DIR:-$HOME/fnberp}"
GO_TAG=""
ROLLBACK="no"
GO_COMPOSE="docker-compose.go.yml"
GO_IMAGE_REPO="ghcr.io/nguyentrucanhtuan/trcf-erp-backend-go"
# Mốc database NestJS mà baseline goose của Go nhận — PHẢI khớp LastTypeORMMigration / TypeORMMigrationCount trong
# trcf_erp_backend_golang/internal/migrations/embed.go. `migrate bootstrap` tự kiểm lại lần nữa; ở đây kiểm sớm để
# dừng TRƯỚC khi tắt NestJS.
NEST_LAST_MIGRATION="CreateAttendanceGpsPunches1783744100000"
NEST_MIGRATION_COUNT="157"
KEEP_DUMPS=5

while [ $# -gt 0 ]; do
  case "$1" in
    --go-tag)   GO_TAG="${2:-}"; shift 2 ;;
    --dir)      INSTALL_DIR="${2:-}"; shift 2 ;;
    --rollback) ROLLBACK="yes"; shift ;;
    -h|--help)  sed -n '2,32p' "$0" 2>/dev/null || true; exit 0 ;;
    *) printf 'Tham số lạ: %s\n' "$1" >&2; exit 1 ;;
  esac
done

step() { printf '\n\033[1;36m▶ %s\033[0m\n' "$*"; }
ok()   { printf '  \033[1;32m✓\033[0m %s\n' "$*"; }
info() { printf '  \033[0;90m%s\033[0m\n' "$*"; }
warn() { printf '  \033[1;33m!\033[0m %s\n' "$*"; }
die()  { printf '\n\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

cd "$INSTALL_DIR" 2>/dev/null || die "Không thấy $INSTALL_DIR — máy chưa cài TRCF ERP (chạy install/erp.sh trước)."
[ -f .env ] || die "Thiếu $INSTALL_DIR/.env — máy chưa cài TRCF ERP (chạy install/erp.sh trước)."
[ -f docker-compose.yml ] || die "Thiếu $INSTALL_DIR/docker-compose.yml — chạy install/erp.sh trước."

# Chạy qua `curl | bash` ⇒ stdin là chính nội dung script: MỌI lệnh docker phải `</dev/null`.
if docker info >/dev/null 2>&1; then
  SUDO=""
else
  sudo -v </dev/tty 2>/dev/null || sudo -n true 2>/dev/null || die "Cần quyền docker hoặc sudo."
  SUDO="sudo"
fi
DOCKER="$SUDO docker"
# Luôn nêu -f tường minh: COMPOSE_FILE trong .env chỉ để phục vụ lệnh gõ tay của người vận hành.
# ⚠️ Hai hàm này ĐÈ stdin bằng /dev/null — lệnh nào cần đọc stdin (pg_restore < dump) phải gọi $DOCKER compose trực tiếp.
nest() { $DOCKER compose -f docker-compose.yml "$@" </dev/null; }
gocp() { $DOCKER compose -f "$GO_COMPOSE" "$@" </dev/null; }

envv() { { grep -E "^$1=" .env || true; } | tail -1 | cut -d= -f2-; }
set_env() {  # $1 tên, $2 giá trị — thay dòng có sẵn hoặc nối thêm
  if grep -qE "^$1=" .env; then
    local tmp; tmp="$(mktemp)"
    awk -v k="$1" -v v="$2" 'BEGIN{FS=OFS="="} $1==k{print k"="v; next} {print}' .env >"$tmp"
    cat "$tmp" >.env; rm -f "$tmp"
  else
    printf '%s=%s\n' "$1" "$2" >>.env
  fi
}
unset_env() {
  local tmp; tmp="$(mktemp)"
  { grep -vE "^$1=" .env || true; } >"$tmp"
  cat "$tmp" >.env; rm -f "$tmp"
}
add_env_if_missing() {  # $1 tên, $2 giá trị, $3 chú thích
  grep -qE "^$1=" .env && return 0
  printf '\n# %s\n%s=%s\n' "$3" "$1" "$2" >>.env
  ok "Thêm $1 vào .env"
}

wait_healthy() {  # $1 = hàm compose (nest|gocp), $2… = service; tối đa 5 phút
  local fn="$1"; shift
  local i s all
  for i in $(seq 1 60); do
    all="yes"
    for s in "$@"; do
      $fn ps --format '{{.Service}} {{.Status}}' 2>/dev/null | grep -qE "^$s .*\(healthy\)" || all="no"
    done
    [ "$all" = "yes" ] && return 0
    sleep 5
    [ $((i % 6)) -eq 0 ] && info "… vẫn đang chờ $* ($((i * 5))s)"
  done
  return 1
}

DBU="$(envv DB_USER)"; DBU="${DBU:-trcf}"
DBN="$(envv DB_NAME)"; DBN="${DBN:-trcf_erp}"
sql() { gocp exec -T postgres psql -U "$DBU" -d "$DBN" -v ON_ERROR_STOP=1 -At -c "$1"; }

# ── Lùi về NestJS ──────────────────────────────────────────────────────────
if [ "$ROLLBACK" = "yes" ]; then
  step "Lùi về backend NestJS"
  unset_env COMPOSE_FILE
  ok "Đã xoá COMPOSE_FILE khỏi .env — lệnh docker compose về lại docker-compose.yml"
  nest up -d --remove-orphans || die "Không bật được bộ NestJS: cd $INSTALL_DIR && docker compose logs backend"
  if wait_healthy nest backend frontend_app; then
    ok "NestJS đã chạy lại ($(envv BACKEND_IMAGE_TAG))"
  else
    die "Quá 5 phút NestJS chưa healthy. Xem: cd $INSTALL_DIR && docker compose logs backend"
  fi
  info "Database giữ nguyên. Mọi người đăng nhập lại (NestJS ký token bằng JWT_SECRET riêng)."
  exit 0
fi

# ── 1. Kiểm đầu vào ────────────────────────────────────────────────────────
step "Kiểm đầu vào"

[ -n "$GO_TAG" ] || GO_TAG="$(envv GO_BACKEND_IMAGE_TAG)"
case "$GO_TAG" in
  sha-[0-9a-f]*) ok "Ảnh Go: $GO_IMAGE_REPO:$GO_TAG" ;;
  "") die "Thiếu tag ảnh Go. Chạy lại kèm --go-tag sha-<commit> (hỏi nhà cung cấp)." ;;
  *)  die "Tag ảnh Go phải dạng sha-<commit> (đang là '$GO_TAG') — ảnh Go không có latest." ;;
esac
APP_TAG="$(envv APP_IMAGE_TAG)"
case "$APP_TAG" in ""|latest) die "Thiếu APP_IMAGE_TAG trong .env — chạy install/erp.sh --update --app-tag sha-<commit> trước." ;; esac

curl -fsSL "$RAW_BASE/$GO_COMPOSE" -o "$GO_COMPOSE.new" || die "Không tải được $GO_COMPOSE từ $RAW_BASE (kiểm tra mạng)."
mv "$GO_COMPOSE.new" "$GO_COMPOSE"
# Lưu bản script vào thư mục cài: chạy qua `curl | bash` thì máy không có tệp nào để gọi `--rollback` về sau.
curl -fsSL "$RAW_BASE/install/deploy-go.sh" -o deploy-go.sh.new && mv deploy-go.sh.new deploy-go.sh || rm -f deploy-go.sh.new
ok "Đã tải $GO_COMPOSE + deploy-go.sh (lệnh lùi)"

# Bổ sung .env TRƯỚC mọi lệnh compose Go: tệp go khai `${VAR:?}` nên thiếu biến là compose từ chối cả `up postgres`.
# Chỉ THÊM dòng, không sửa secret có sẵn ⇒ dừng giữa chừng vẫn vô hại (NestJS không đọc các biến này).
step "Cấu hình .env cho Go"
umask 077
add_env_if_missing JWT_SECRET_GO "$(openssl rand -hex 32)" "Backend Go ký token bằng secret RIÊNG (ADR-4 của 061) — khác JWT_SECRET của NestJS"
if ! grep -qE '^DB_APP_USER=' .env; then
  warn "Quán chưa tách vai database — tạo vai trcf_app (Go không chạy dưới vai chủ). NestJS lùi về cũng sẽ dùng vai này."
  add_env_if_missing DB_APP_USER trcf_app "Vai ứng dụng (chỉ DML, chịu RLS) — thêm bởi deploy-go.sh"
fi
add_env_if_missing DB_APP_PASSWORD "$(openssl rand -hex 24)" "Mật khẩu vai trcf_app — thêm bởi deploy-go.sh"
# db-moi.sh lưu mật khẩu vai bypass ở trcf-bypass.secret (không ở .env): dùng lại, đừng để setup-db-roles đổi mất nó.
BYP_PW_OLD="$({ grep -E '^BYP_PW=' trcf-bypass.secret 2>/dev/null || true; } | tail -1 | cut -d= -f2-)"
add_env_if_missing DB_BYPASS_PASSWORD "${BYP_PW_OLD:-$(openssl rand -hex 24)}" "Mật khẩu vai trcf_bypass — thêm bởi deploy-go.sh${BYP_PW_OLD:+ (lấy từ trcf-bypass.secret)}"
chmod 600 .env

step "Kiểm database"
gocp up -d postgres >/dev/null 2>/tmp/trcf-go-pg || { cat /tmp/trcf-go-pg >&2; rm -f /tmp/trcf-go-pg; die "Không bật được postgres: cd $INSTALL_DIR && docker compose logs postgres"; }
rm -f /tmp/trcf-go-pg
for i in $(seq 1 30); do
  gocp exec -T postgres pg_isready -U "$DBU" -d "$DBN" >/dev/null 2>&1 && break
  sleep 2
done

HAS_GOOSE="$(sql "select to_regclass('public.goose_db_version') is not null" 2>/dev/null || echo '?')"
if [ "$HAS_GOOSE" = "t" ]; then
  DB_STATE="go"
  ok "Database đã chuyển Go từ trước (có goose_db_version) — bỏ qua bootstrap"
elif [ "$HAS_GOOSE" = "f" ]; then
  HAS_MIG="$(sql "select to_regclass('public.migrations') is not null")"
  [ "$HAS_MIG" = "t" ] || die "Database trắng (không có bảng migrations). Cài bằng install/erp.sh trước — deploy-go.sh chưa hỗ trợ máy trắng."
  MIG_COUNT="$(sql "select count(*) from public.migrations")"
  MIG_LAST="$(sql "select name from public.migrations order by id desc limit 1")"
  if [ "$MIG_COUNT" != "$NEST_MIGRATION_COUNT" ] || [ "$MIG_LAST" != "$NEST_LAST_MIGRATION" ]; then
    die "Database NestJS đứng ở migration $MIG_COUNT ($MIG_LAST), bản Go cần đúng $NEST_MIGRATION_COUNT ($NEST_LAST_MIGRATION).
  Nâng NestJS tới mốc đó trước (install/erp.sh --update --backend-tag …), rồi chạy lại."
  fi
  DB_STATE="nest"
  ok "Database NestJS đúng mốc $NEST_MIGRATION_COUNT migration"
else
  die "Không đọc được database. Xem: cd $INSTALL_DIR && docker compose logs postgres"
fi

# ── 2. Ghi tag ảnh Go (SAU khi qua hết bước kiểm: máy đang chạy Go mà kiểm hỏng thì .env không lệch tag) ──
PREV_GO_TAG="$(envv GO_BACKEND_IMAGE_TAG)"
set_env GO_BACKEND_IMAGE_TAG "$GO_TAG"
chmod 600 .env
ok "GO_BACKEND_IMAGE_TAG=$GO_TAG${PREV_GO_TAG:+ (trước: $PREV_GO_TAG)}"

# ── 3. Kéo ảnh (NestJS vẫn đang chạy) ──────────────────────────────────────
step "Kéo ảnh Go + giao diện"
if $DOCKER image inspect "$GO_IMAGE_REPO:$GO_TAG" >/dev/null 2>&1; then
  ok "Ảnh Go đã có sẵn trên máy"
else
  $DOCKER pull -q "$GO_IMAGE_REPO:$GO_TAG" </dev/null >/dev/null 2>/tmp/trcf-go-pull \
    || { cat /tmp/trcf-go-pull >&2; rm -f /tmp/trcf-go-pull; die "Không kéo được ảnh Go $GO_TAG (token read:packages? tag có thật?). NestJS vẫn chạy bình thường."; }
  rm -f /tmp/trcf-go-pull
  ok "Đã kéo $GO_IMAGE_REPO:$GO_TAG"
fi
gocp pull -q frontend_app || die "Không kéo được ảnh giao diện $APP_TAG. NestJS vẫn chạy bình thường."

# ── 4. Dừng backend cũ + sao lưu ───────────────────────────────────────────
step "Dừng backend (hết ghi) + sao lưu database"
nest stop backend >/dev/null 2>&1 || true
gocp stop backend >/dev/null 2>&1 || true
ok "Đã dừng backend — quán tạm ngưng tới khi Go lên (thường dưới 2 phút)"

mkdir -p backups-go
DUMP="backups-go/truoc-go-$(date +%Y%m%d-%H%M%S).dump"
if ! gocp exec -T postgres pg_dump -U "$DBU" -d "$DBN" -Fc >"$DUMP" 2>/tmp/trcf-go-dump \
   || [ ! -s "$DUMP" ] \
   || ! $DOCKER compose -f "$GO_COMPOSE" exec -T postgres pg_restore -l <"$DUMP" >/dev/null 2>&1; then
  cat /tmp/trcf-go-dump >&2 2>/dev/null || true
  rm -f /tmp/trcf-go-dump "$DUMP"
  [ "$DB_STATE" = "nest" ] && nest start backend >/dev/null 2>&1 || true
  die "Sao lưu hỏng — KHÔNG migrate. Backend cũ đã bật lại."
fi
rm -f /tmp/trcf-go-dump
ok "Bản sao lưu: $INSTALL_DIR/$DUMP ($(du -h "$DUMP" | cut -f1))"
# Giữ KEEP_DUMPS bản mới nhất.
# shellcheck disable=SC2012
ls -1t backups-go/truoc-go-*.dump 2>/dev/null | tail -n +$((KEEP_DUMPS + 1)) | while read -r f; do rm -f "$f"; done

RESTORE_HINT="Khôi phục: cd $INSTALL_DIR && docker compose -f $GO_COMPOSE exec -T postgres pg_restore -U $DBU -d $DBN --clean --if-exists < $DUMP
  rồi lùi về NestJS: bash $INSTALL_DIR/deploy-go.sh --rollback"

# ── 5. Schema + quyền ──────────────────────────────────────────────────────
step "Chuyển schema sang Go"
if [ "$DB_STATE" = "nest" ]; then
  gocp run -T --rm --no-deps go_migrate bootstrap || die "migrate bootstrap hỏng (database CHƯA đổi bảng nào).
  Bật lại NestJS: bash $INSTALL_DIR/deploy-go.sh --rollback"
  ok "Đã bootstrap (ghi baseline goose, không đổi bảng)"
fi
gocp run -T --rm --no-deps go_migrate up || die "migrate up hỏng.
  $RESTORE_HINT"
ok "migrate up xong"
gocp run -T --rm --no-deps go_seed >/dev/null || die "seed-shop hỏng.
  $RESTORE_HINT"
ok "Đã gieo quyền theo catalog Go (chỉ thêm)"
gocp run -T --rm --no-deps go_roles >/tmp/trcf-go-roles 2>&1 || { cat /tmp/trcf-go-roles >&2; rm -f /tmp/trcf-go-roles; die "setup-db-roles hỏng.
  $RESTORE_HINT"; }
rm -f /tmp/trcf-go-roles
ok "Vai database: $(envv DB_APP_USER) (chỉ DML, RLS) + trcf_bypass"

# ── 6. Bật bộ Go ───────────────────────────────────────────────────────────
step "Bật backend Go"
set_env COMPOSE_FILE "$GO_COMPOSE"
ok "COMPOSE_FILE=$GO_COMPOSE — lệnh docker compose trong $INSTALL_DIR nay nhắm bộ Go"
gocp up -d --remove-orphans || die "Không bật được bộ Go. Xem: cd $INSTALL_DIR && docker compose logs backend
  Lùi về NestJS: bash $INSTALL_DIR/deploy-go.sh --rollback"

if ! wait_healthy gocp backend frontend_app; then
  die "Quá 5 phút bộ Go chưa healthy. Xem: cd $INSTALL_DIR && docker compose logs backend
  Lùi về NestJS: bash $INSTALL_DIR/deploy-go.sh --rollback"
fi
gocp exec -T backend /healthcheck >/dev/null 2>&1 || die "Backend Go không trả /healthz. Lùi: bash $INSTALL_DIR/deploy-go.sh --rollback"
RUNNING_IMG="$(gocp ps --format '{{.Service}} {{.Image}}' | awk '$1=="backend"{print $2}')"
case "$RUNNING_IMG" in
  "$GO_IMAGE_REPO":*) ok "Backend đang chạy: $RUNNING_IMG" ;;
  *) die "Service backend đang chạy ảnh lạ '$RUNNING_IMG' (cần $GO_IMAGE_REPO)." ;;
esac

printf '\n\033[1;32m╔══════════════════════════════════════════════════════════╗\033[0m\n'
printf '\033[1;32m║          TRCF ERP đang chạy backend GO                   ║\033[0m\n'
printf '\033[1;32m╚══════════════════════════════════════════════════════════╝\033[0m\n\n'
printf '  Địa chỉ          %s (như cũ)\n' "$(envv APP_URL)"
printf '  Backend          %s\n' "$RUNNING_IMG"
printf '  Sao lưu trước Go %s\n' "$INSTALL_DIR/$DUMP"
printf '\n  \033[1;33mMọi máy (thu ngân, tablet bếp, màn khách) phải ĐĂNG NHẬP LẠI.\033[0m\n'
printf '  Lùi về NestJS    bash %s/deploy-go.sh --rollback\n\n' "$INSTALL_DIR"
