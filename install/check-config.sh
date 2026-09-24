#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# Kiểm cấu hình cổng vào — chạy trên MÁY PHÁT HÀNH, trước khi đẩy bản mới.
#
#   bash install/check-config.sh          (từ thư mục trcf_deploy/)
#
# Thư mục này không có test nào và CI không chạy gì, nên hai bất biến dưới đây
# chỉ được chứng minh bằng một lượt đo tay không lặp lại được. Script này gói
# đúng hai lượt đo đó lại để một thay đổi "cho gọn" không lặng lẽ phá chúng:
#
#   ① `.env` KHÔNG khai `ZALO_ALLOWED_IPS` thì Caddyfile vẫn phải có mặc định
#      MỞ (nhận mọi IP). Đổi `{$ZALO_ALLOWED_IPS:0.0.0.0/0 ::/0}` thành
#      `{$ZALO_ALLOWED_IPS}` "cho nhất quán với compose" là allowlist rỗng ⇒
#      Caddy chặn SẠCH mọi lượt gọi của Zalo, quán mất đơn đã thu tiền.
#
#   ② Route `/zalo-checkout/*` phải đứng TRƯỚC route `@backend` và trước khối
#      vét về frontend. `handle` loại trừ lẫn nhau nên khối nào khớp trước thì
#      thắng; chèn một khối `handle` lên trên khối `@zalo` là đẩy lượt gọi của
#      Zalo vào Next.js — chết lặng, đúng bẫy MoMo IPN 14/08.
#
# Cần Docker (dùng ảnh caddy:2-alpine để adapt) và `docker compose`.
# Thoát 0 = đạt; khác 0 = có bất biến bị phá, in rõ cái nào.
# ─────────────────────────────────────────────────────────────────────────
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2
FAIL=0
CADDY_IMAGE="caddy:2-alpine"

red() { printf '\033[31m✗ %s\033[0m\n' "$1"; FAIL=1; }
grn() { printf '\033[32m✓ %s\033[0m\n' "$1"; }

need() { command -v "$1" >/dev/null 2>&1 || { echo "Thiếu lệnh: $1"; exit 2; }; }
need docker

ALLOW_VAL=""
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ── ① compose truyền biến tuỳ chọn dạng rỗng, và Caddyfile mở mặc định ──
cat > "$TMP/minimal.env" <<'EOF'
DB_PASSWORD=x
JWT_SECRET=x
ADMIN_SEED_EMAIL=a@b.c
ADMIN_SEED_PASSWORD=x
AUTH_SECRET=x
EOF

if ! CONF="$(docker compose --env-file "$TMP/minimal.env" config 2>"$TMP/err")"; then
	red "docker compose config lỗi với .env tối thiểu (quán cũ cập nhật ảnh sẽ chết): $(head -2 "$TMP/err")"
else
	for v in ZALO_ALLOWED_IPS ZALO_CHECKOUT_API_BASE TRUST_PROXY CORS_ALLOWED_ORIGINS; do
		if printf '%s' "$CONF" | grep -q "$v:"; then
			grn "compose truyền $v khi .env không khai"
		else
			red "compose KHÔNG truyền $v — biến trong .env sẽ không tới được container"
		fi
	done

	# `ZALO_ALLOWED_IPS` phải ra KHÁC RỖNG. Caddy phân biệt "chưa khai" với "khai
	# rỗng": `${VAR-}` truyền vào một biến đã-đặt-mà-rỗng, placeholder
	# `{$VAR:mặc-định}` KHÔNG lùi về mặc định nữa, `remote_ip` nhận 0 dải và chặn
	# sạch mọi lượt gọi của Zalo — trong khi `caddy validate` vẫn báo hợp lệ.
	ALLOW_VAL="$(printf '%s' "$CONF" | sed -n 's/^ *ZALO_ALLOWED_IPS: *//p' | head -1 | tr -d '"')"
	if [ -n "$ALLOW_VAL" ]; then
		grn "ZALO_ALLOWED_IPS ra khác rỗng khi .env không khai ($ALLOW_VAL)"
	else
		red "ZALO_ALLOWED_IPS ra RỖNG — Caddy sẽ chặn SẠCH mọi lượt gọi của Zalo ở mọi quán (dùng \${ZALO_ALLOWED_IPS:-0.0.0.0/0 ::/0}, đừng dùng \${VAR-})"
	fi
fi

# ── ② Caddy: mặc định MỞ khi biến rỗng ──
# Truyền ĐÚNG giá trị mà compose sinh ra ở trên (không phải "biến chưa khai"):
# chính chỗ lệch đó là nơi lỗi chặn-sạch từng lọt qua một lượt đo tay.
ADAPT_OPEN="$(docker run --rm -e SITE_ADDRESS=:80 -e ZALO_ALLOWED_IPS="${ALLOW_VAL:-}" \
	-v "$PWD/Caddyfile:/etc/caddy/Caddyfile:ro" "$CADDY_IMAGE" \
	caddy adapt --config /etc/caddy/Caddyfile 2>"$TMP/err")"
if [ -z "$ADAPT_OPEN" ]; then
	red "caddy adapt thất bại: $(head -3 "$TMP/err")"
else
	if printf '%s' "$ADAPT_OPEN" | grep -q '"0.0.0.0/0"' && printf '%s' "$ADAPT_OPEN" | grep -q '"::/0"'; then
		grn ".env không khai → allowlist MỞ cả v4 lẫn v6 (0.0.0.0/0 + ::/0)"
	else
		red ".env không khai mà allowlist KHÔNG mở — Zalo sẽ bị chặn sạch ở mọi quán"
	fi

	# ── ③ thứ tự route: zalo trước backend, backend trước khối vét ──
	ORDER="$(printf '%s' "$ADAPT_OPEN" | python3 -c '
import sys, json
d = json.load(sys.stdin)
rs = d["apps"]["http"]["servers"]["srv0"]["routes"]
zalo = backend = catch = -1
for i, r in enumerate(rs):
    paths = []
    for m in (r.get("match") or []):
        paths += m.get("path", [])
    if any(p.startswith("/zalo-checkout") for p in paths):
        zalo = i if zalo < 0 else zalo
    elif any(p.startswith("/socket.io") for p in paths):
        backend = i if backend < 0 else backend
    elif not r.get("match") and json.dumps(r).find("frontend:3000") >= 0:
        catch = i if catch < 0 else catch
print(zalo, backend, catch)
' 2>/dev/null)"
	set -- $ORDER
	Z="${1:--1}"; B="${2:--1}"; C="${3:--1}"
	if [ "$Z" -lt 0 ]; then
		red "KHÔNG tìm thấy route /zalo-checkout — Zalo sẽ rơi vào Next.js và chết lặng"
	elif [ "$B" -ge 0 ] && [ "$Z" -gt "$B" ]; then
		red "route /zalo-checkout ($Z) đứng SAU route @backend ($B)"
	elif [ "$C" -ge 0 ] && [ "$Z" -gt "$C" ]; then
		red "route /zalo-checkout ($Z) đứng SAU khối vét về frontend ($C)"
	else
		grn "route /zalo-checkout (#$Z) đứng trước @backend (#$B) và khối vét (#$C)"
	fi

	# ── ④ khớp cả đường trần, không chỉ /* ──
	if printf '%s' "$ADAPT_OPEN" | grep -q '"/zalo-checkout"'; then
		grn "matcher khớp cả /zalo-checkout trần lẫn /zalo-checkout/*"
	else
		red "matcher thiếu /zalo-checkout trần — route mới ở gốc sẽ rơi vào Next.js"
	fi
fi

# ── ⑤ allowlist hẹp vẫn adapt được và mang đúng dải ──
if docker run --rm -e SITE_ADDRESS=:80 -e ZALO_ALLOWED_IPS='203.0.113.0/24 ::/0' \
	-v "$PWD/Caddyfile:/etc/caddy/Caddyfile:ro" "$CADDY_IMAGE" \
	caddy adapt --config /etc/caddy/Caddyfile 2>/dev/null |
	grep -q '"ranges":\["203.0.113.0/24","::/0"\]'; then
	grn "allowlist hẹp (2 dải cách nhau bằng dấu cách) tách đúng thành 2 range"
else
	red "allowlist hẹp KHÔNG tách đúng — kiểm lại khuôn {\$ZALO_ALLOWED_IPS:...}"
fi

echo
[ "$FAIL" -eq 0 ] && { echo "Tất cả bất biến cổng vào ĐẠT."; exit 0; }
echo "CÓ BẤT BIẾN BỊ PHÁ — đừng đẩy bản này cho quán."
exit 1
