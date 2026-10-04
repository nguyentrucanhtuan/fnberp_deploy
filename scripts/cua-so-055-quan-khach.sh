#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# CỬA SỔ 055 MỘT LẦN cho QUÁN KHÁCH — pha 1 (timestamptz) → pha 2 (shop_id) → pha 4
# (RLS + vai app) liền nhau, bằng CHÍNH các CLI trong ảnh mới. Quyết định 03/10 (chủ dự
# án): SoCoffee rồi Gác Đỏ đi một cửa sổ, Coffeetree đã tiên phong từng pha
# (specs/055-saas/trien-khai-pha-4.md · README §7).
#
#   sudo -E bash cua-so-055-quan-khach.sh             # cửa sổ — trên MÁY QUÁN, ngoài giờ bán
#   sudo -E bash cua-so-055-quan-khach.sh --lui <TS>  # đường lùi: về đúng trước cửa sổ <TS>
#
# Biến (bắt buộc trừ khi ghi mặc định):
#   DIR            thư mục compose của quán (vd /home/gacdero/fnberp)
#   NEW_BE_TAG     tag ảnh backend 055 (vd sha-ecd8a6c) — đã `docker pull` sẵn
#   NEW_FE_TAG     tag ảnh frontend 055 (vd sha-85d8081) — đã `docker pull` sẵn
#   EXPECT_MIG     số dòng `migrations` phải có lúc đầu (vd 122) — lệch ⇒ DỪNG
#   EXPECT_LAST    tên migration mới nhất phải có lúc đầu — lệch ⇒ DỪNG
#   STRAY_TABLES   (tuỳ) bảng lạ trong public chuyển sang schema `luu_tru` trước pha 2,
#                  cách nhau dấu cách (Gác Đỏ: order_lines_vat_fix_20260923)
#   UNTIL          (tuỳ) ngày chốt báo cáo, mặc định hôm qua theo giờ VN
#
# Nguyên tắc: dừng ở lệnh ĐẦU TIÊN không qua; KHÔNG `up` giữa chừng (ảnh mới tự chạy
# EnableShopRls lúc boot — chỉ được boot sau cửa pha 4). Đường lùi trọn vẹn: dump
# `giu-truoc-055-<ts>.dump` chụp ở bước 0 + `.env`/compose sao lưu — in ra khi dừng.
# Mật khẩu vai không bao giờ in ra màn hình.
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

: "${DIR:?DIR}" "${NEW_BE_TAG:?NEW_BE_TAG}"
STRAY_TABLES="${STRAY_TABLES:-}"
UNTIL="${UNTIL:-$(TZ=Asia/Ho_Chi_Minh date -d yesterday +%F)}"
TS="$(date +%Y%m%dT%H%M%S)"
cd "$DIR" || { echo "⛔ không vào được $DIR"; exit 2; }
envv() { local v; v=$(grep "^$1=" .env | tail -1 | cut -d= -f2-); echo "${v:-$2}"; }
DBU=$(envv DB_USER trcf); DBN=$(envv DB_NAME trcf_erp)

ts() { date '+%F %T'; }
say() { printf '\n== %s  [%s]\n' "$1" "$(ts)"; }
# Ảnh MỚI cho mọi CLI — .env chưa đổi tới bước 4c.
run_new() { BACKEND_IMAGE_TAG="$NEW_BE_TAG" docker compose run --pull never --rm --no-deps "$@" </dev/null 2>&1 | grep -vE '^ *(Container|Image) .*(Creat|Pull|Start)'; return "${PIPESTATUS[0]}"; }
psql_q() { docker compose exec -T postgres psql -U "$DBU" -d "${2:-$DBN}" -v ON_ERROR_STOP=1 -At -c "$1" </dev/null; }

# ── ĐƯỜNG LÙI: --lui <TS> — về đúng trạng thái trước cửa sổ <TS> ──────────────
if [ "${1:-}" = "--lui" ]; then
  L="${2:?--lui <TS> (lấy từ tên dump giu-truoc-055-<TS>.dump)}"
  [ -f ".env.bak-cua-so-055-$L" ] && [ -f "docker-compose.yml.bak-cua-so-055-$L" ] || { echo "⛔ thiếu .env/compose sao lưu của $L"; exit 2; }
  echo "LÙI về trước cửa sổ $L — $(ts)"
  docker compose stop backend frontend </dev/null 2>&1 | tail -1
  run_new --entrypoint sh backend -c "[ -s /backups/giu-truoc-055-$L.dump ]" || { echo "⛔ không thấy /backups/giu-truoc-055-$L.dump"; exit 2; }
  psql_q "DROP DATABASE IF EXISTS \"$DBN\" WITH (FORCE)" postgres && psql_q "CREATE DATABASE \"$DBN\" OWNER \"$DBU\"" postgres || { echo "⛔ dựng lại DB hỏng"; exit 1; }
  run_new --entrypoint sh backend -c "pg_restore --no-owner --exit-on-error -d \"\$MIGRATION_DATABASE_URL\" /backups/giu-truoc-055-$L.dump" || { echo "⛔ pg_restore hỏng"; exit 1; }
  cp -p ".env.bak-cua-so-055-$L" .env && cp -p "docker-compose.yml.bak-cua-so-055-$L" docker-compose.yml
  echo "migrations=$(psql_q "select count(*) from migrations") · mới nhất=$(psql_q "select name from migrations order by id desc limit 1") · RLS=$(psql_q "select count(*) from pg_class where relrowsecurity")"
  docker compose up -d --pull never backend frontend </dev/null 2>&1 | tail -2
  for i in $(seq 1 90); do docker compose logs --tail 200 backend </dev/null 2>&1 | grep -q 'Backend đang chạy' && break; sleep 2; done
  docker compose ps --format '{{.Service}} {{.Image}} {{.Status}}'
  echo "ĐÃ LÙI $(ts) — vai trcf_app/trcf_bypass còn trong cụm, vô hại."
  exit 0
fi
: "${NEW_FE_TAG:?NEW_FE_TAG}" "${EXPECT_MIG:?EXPECT_MIG}" "${EXPECT_LAST:?EXPECT_LAST}"
die() {
  echo
  echo "⛔ DỪNG ở bước $1 lúc $(ts). Backend ĐANG DỪNG — chưa up."
  echo "   Đã qua bước 0 (DB có thể đã đổi) ⇒ lùi:  DIR=$DIR NEW_BE_TAG=$NEW_BE_TAG bash $0 --lui $TS"
  echo "   Chưa tới bước 0 ⇒ chỉ cần:  docker compose up -d backend"
  exit 1
}

echo "BẮT ĐẦU cửa sổ 055 một lần — $(hostname) — $(ts) — until=$UNTIL"
say "−1. Kiểm trước khi dừng (chỉ đọc)"
docker compose config | grep -q 'MIGRATION_DATABASE_URL:' || die "-1 (compose thiếu MIGRATION_DATABASE_URL)"
docker compose config | grep -q 'target: /backups' || die "-1 (compose thiếu ổ backups)"
grep -q 'BACKEND_IMAGE_TAG' docker-compose.yml || die "-1 (compose chưa tách BACKEND_IMAGE_TAG)"
grep -q '^DB_APP_USER=' .env && die "-1 (.env đã có DB_APP_USER — soi tay)"
for n in backend frontend; do
  t=$([ $n = backend ] && echo "$NEW_BE_TAG" || echo "$NEW_FE_TAG")
  docker image inspect "ghcr.io/nguyentrucanhtuan/trcf-erp-$n:$t" >/dev/null 2>&1 || die "-1 (chưa pull $n:$t)"
done
MIG=$(psql_q "select count(*) from migrations") || die "-1 (không đọc được migrations)"
LAST=$(psql_q "select name from migrations order by id desc limit 1")
echo "migrations=$MIG · mới nhất=$LAST · cần $EXPECT_MIG · $EXPECT_LAST"
[ "$MIG" = "$EXPECT_MIG" ] && [ "$LAST" = "$EXPECT_LAST" ] || die "-1 (schema lệch bản đã diễn tập)"
df -h / | tail -1
cp -p .env ".env.bak-cua-so-055-$TS" && cp -p docker-compose.yml "docker-compose.yml.bak-cua-so-055-$TS" || die "-1 (sao lưu .env/compose)"

say "0. Dừng backend + dump giữ ngoài vòng xoay"
docker compose stop backend </dev/null 2>&1 | tail -1
run_new --entrypoint sh backend -c "pg_dump -Fc \"\$MIGRATION_DATABASE_URL\" -f /backups/giu-truoc-055-$TS.dump && pg_restore -l /backups/giu-truoc-055-$TS.dump | grep -c 'TABLE DATA' && ls -l /backups/giu-truoc-055-$TS.dump" || die "0 (dump)"

say "1a. Chuẩn bị: general.timezone + bảng lạ"
if [ "$(psql_q "select count(*) from system_settings where module='general' and key='timezone'")" = 0 ]; then
  psql_q "INSERT INTO system_settings (module, key, value, value_type, description) VALUES ('general','timezone','Asia/Ho_Chi_Minh','str','Múi giờ quán (IANA) — đặt lúc mở quán')" >/dev/null || die "1a (ghi timezone)"
  echo "đã ghi general.timezone = Asia/Ho_Chi_Minh"
else
  echo "general.timezone đã có: $(psql_q "select value from system_settings where module='general' and key='timezone'")"
fi
for t in $STRAY_TABLES; do
  psql_q "CREATE SCHEMA IF NOT EXISTS luu_tru; ALTER TABLE public.$t SET SCHEMA luu_tru;" >/dev/null || die "1a (chuyển $t)"
  echo "đã chuyển public.$t → luu_tru.$t ($(psql_q "select count(*) from luu_tru.$t") dòng)"
done

say "1b. PHA 1 — preflight · báo cáo trước · runner · cửa"
run_new backend node dist/timestamptz-preflight || die "1b (timestamptz-preflight)"
run_new backend node dist/baseline-report --until "$UNTIL" --out "/backups/phase1-before-$TS.json" || die "1b (baseline-report pha 1)"
run_new backend node dist/oneway-migrate TimestamptzEverywhere1783741000000 || die "1b (TimestamptzEverywhere)"
# Ảnh 055 chạy kèm SeedMarkers + CreateShops trong lô pha 1 ⇒ hai bảng MỚI có dòng mà
# báo cáo "trước" chưa có. phase1-gate (CLI) chưa khai newTables (DW-055-P1NEW) ⇒ chấp nhận
# HẸP: thoát 1 với ĐÚNG một FAIL là baseline-before-after chỉ "số dòng lệch: seed_markers,
# shops", cả hai "trước (không có)". Mọi lệch khác (hash nghiệp vụ, bảng khác) ⇒ DỪNG.
G1=$(run_new backend node dist/phase1-gate --before "/backups/phase1-before-$TS.json"); RC1=$?
echo "$G1" | grep -E '^(PASS|FAIL|✅|⛔)|^ +bảng '
if [ "$RC1" != 0 ]; then
  FAILS=$(echo "$G1" | grep -c '^FAIL ')
  if [ "$RC1" = 1 ] && [ "$FAILS" = 1 ] \
     && echo "$G1" | grep -qx 'FAIL baseline-before-after — số dòng lệch: seed_markers, shops' \
     && echo "$G1" | grep -q 'bảng seed_markers: trước (không có)' \
     && echo "$G1" | grep -q 'bảng shops: trước (không có)'; then
    echo "↳ chấp nhận: lệch DUY NHẤT là hai bảng mới tạo trong lô (seed_markers, shops) — 4 hash nghiệp vụ không đổi"
  else
    die "1b (phase1-gate)"
  fi
fi

say "2. PHA 2 — preflight · báo cáo trước · 5 runner · cửa"
# --expect-fingerprint bỏ: DW-055-FP (hash bản khôi phục ≠ DB thật vì cách in CHECK);
# thay bằng EXPECT_MIG/EXPECT_LAST ở −1 + diễn tập trên dump của quán.
run_new backend node dist/phase2-preflight || die "2 (phase2-preflight)"
run_new backend node dist/baseline-report --until "$UNTIL" --out "/backups/phase2-before-$TS.json" || die "2 (baseline-report pha 2)"
for m in BigintLargeTables1783741100000 AddShopIdColumns1783741200000 CompositeKeys1783741400000 \
         ExternalRefsAndZaloAppShops1783741500000 TenantScopedUniques1783741600000; do
  run_new backend node dist/oneway-migrate "$m" || die "2 ($m)"
done
run_new backend node dist/phase2-gate --before "/backups/phase2-before-$TS.json" || die "2 (phase2-gate)"

say "3. PHA 4 — dựng vai · preflight"
DBPW=$(envv DB_PASSWORD "")
APP_PW=$(openssl rand -hex 24); BYP_PW=$(openssl rand -hex 24)
run_new -e ADMIN_DATABASE_URL="postgresql://$DBU:$DBPW@postgres:5432/$DBN" \
  -e DB_APP_PASSWORD="$APP_PW" -e DB_BYPASS_PASSWORD="$BYP_PW" backend node dist/setup-db-roles || die "3 (setup-db-roles)"
( umask 077; printf '# %s — mật khẩu vai trcf_bypass (BYPASSRLS, chỉ quản trị). Chỉ root đọc.\nBYP_PW=%s\n' "$(ts)" "$BYP_PW" > /root/trcf-bypass.secret ) || die "3 (cất BYP_PW)"
run_new -e DATABASE_URL="postgresql://trcf_app:$APP_PW@postgres:5432/$DBN" backend node dist/phase4-preflight || die "3 (phase4-preflight)"

say "4. PHA 4 — báo cáo trước · đổi ảnh + vai · boot-migrate · cửa"
run_new backend node dist/baseline-report --until "$UNTIL" --out "/backups/phase4-before-$TS.json" || die "4 (baseline-report pha 4)"
if grep -q '^BACKEND_IMAGE_TAG=' .env; then sed -i "s/^BACKEND_IMAGE_TAG=.*/BACKEND_IMAGE_TAG=$NEW_BE_TAG/" .env; else printf '\nBACKEND_IMAGE_TAG=%s\n' "$NEW_BE_TAG" >> .env; fi
if grep -q '^IMAGE_TAG=' .env; then sed -i "s/^IMAGE_TAG=.*/IMAGE_TAG=$NEW_FE_TAG/" .env; else printf 'IMAGE_TAG=%s\n' "$NEW_FE_TAG" >> .env; fi
printf '# %s (055 pha 4): backend dưới vai app — RLS áp\nDB_APP_USER=trcf_app\nDB_APP_PASSWORD=%s\n' "$(ts)" "$APP_PW" >> .env
docker compose config --images | grep trcf-erp
docker compose config | grep -q "image: ghcr.io/nguyentrucanhtuan/trcf-erp-backend:$NEW_BE_TAG" || die "4 (image backend)"
docker compose config | grep -q 'DATABASE_URL: postgresql://trcf_app:' || die "4 (DATABASE_URL app)"
docker compose config | grep -qE "MIGRATION_DATABASE_URL: postgresql://$DBU:" || die "4 (MIGRATION_DATABASE_URL)"
docker compose run --pull never --rm --no-deps backend node dist/boot-migrate </dev/null 2>&1 | grep -vE '^ *(Container|Image) ' ; [ "${PIPESTATUS[0]}" = 0 ] || die "4 (boot-migrate)"
docker compose run --pull never --rm --no-deps backend node dist/phase4-gate --before "/backups/phase4-before-$TS.json" </dev/null 2>&1 | grep -vE '^ *(Container|Image) '; [ "${PIPESTATUS[0]}" = 0 ] || die "4 (phase4-gate)"

say "5. UP — backend + frontend mới"
docker compose up -d --pull never backend frontend </dev/null 2>&1 | tail -3
for i in $(seq 1 90); do docker compose logs --tail 200 backend </dev/null 2>&1 | grep -q 'Backend đang chạy' && break; sleep 2; done
docker compose logs --tail 300 backend </dev/null 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E 'DbRole|Backend đang chạy'
docker compose run --pull never --rm --no-deps backend node dist/phase4-gate </dev/null 2>&1 | grep -E '^(PASS|FAIL|✅|⛔)'
docker compose ps --format '{{.Service}} {{.Image}} {{.Status}}'
echo
echo "KẾT THÚC OK $(ts) — dump giữ: /backups/giu-truoc-055-$TS.dump · .env cũ: .env.bak-cua-so-055-$TS · BYP_PW: /root/trcf-bypass.secret"
