#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# TRCF ERP — cài TRCF BRIDGE ở máy quầy: cầu nối giữa ERP và thiết bị cắm tại
# quầy (hiện tại là máy in USB), chạy bằng Docker.
#
#   cd ~ && curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/bridge.sh \
#     | GHCR_TOKEN=<token> sudo -E bash
#
# Script này CHỈ CÀI, cố ý KHÔNG ghép nối và KHÔNG chạy.
# Ghép là việc riêng vì nó cần mã 6 số lấy từ ERP, mà mã chỉ sống 10 phút —
# gộp vào đây thì người lắp phải lấy mã trước rồi mới dám chạy lệnh cài,
# và lỡ tay là mã hết hạn giữa chừng. Cài xong script in ra lệnh ghép.
#
# Máy in có cổng MẠNG thì KHÔNG cần script này — vào ERP mục Máy in, chọn
# kết nối "mạng", nhập IP + cổng 9100 là xong.
# ─────────────────────────────────────────────────────────────────────────
set -euo pipefail

IMAGE="ghcr.io/nguyentrucanhtuan/trcf-bridge:latest"
DIR="/opt/trcf-bridge"
CFG_DIR="/etc/trcf-bridge"
WRAPPER="/usr/local/bin/trcf-bridge"
GHCR_USER="nguyentrucanhtuan"

red()  { printf '\033[31m%s\033[0m\n' "$*"; }
grn()  { printf '\033[32m%s\033[0m\n' "$*"; }
ylw()  { printf '\033[33m%s\033[0m\n' "$*"; }
die()  { red "✗ $*"; exit 1; }

echo "── Cài TRCF Bridge (cầu nối thiết bị tại quầy) ──"

# ── 1. Máy này có chạy được không ────────────────────────────────────────
# Chặn sớm và nói rõ lý do: Docker trên Windows/macOS chạy trong một máy ảo
# KHÔNG có cổng USB nào để cấp cho container. Để người ta cài xong mới phát
# hiện máy in không bao giờ ra giấy thì tệ hơn nhiều.
[ "$(uname -s)" = "Linux" ] || die "Chỉ chạy được trên Linux.
  Máy in USB trên Windows/macOS hiện CHƯA hỗ trợ — hãy dùng máy in có cổng mạng
  (vào ERP mục Máy in, chọn kết nối 'mạng', nhập IP + cổng 9100)."

[ "$(id -u)" = "0" ] || die "Cần quyền quản trị (script ghi vào $DIR, $CFG_DIR và cấp thiết bị máy in).
  Chạy lại kèm sudo:  ... | GHCR_TOKEN=<token> sudo -E bash"

command -v docker >/dev/null 2>&1 || die "Chưa có Docker. Cài ERP trước (install/ubuntu.sh) rồi chạy lại."
docker info >/dev/null 2>&1 || die "Docker chưa chạy:  sudo systemctl start docker"
docker compose version >/dev/null 2>&1 || die "Thiếu Docker Compose plugin. Cài lại Docker bằng install/docker.sh."

# ── 2. Tải phần mềm ──────────────────────────────────────────────────────
# Thử kéo trước khi hỏi token: máy đã cài ERP thì Docker đã đăng nhập GHCR sẵn,
# bắt nhập lại token là thừa và làm người ta tưởng cần token thứ hai.
echo "→ Tải phần mềm ..."
if ! docker pull -q "$IMAGE" >/dev/null 2>&1; then
  [ -n "${GHCR_TOKEN:-}" ] || die "Chưa tải được phần mềm và không có token.
  Chạy lại kèm token nhà cung cấp đã cấp:
    ... | GHCR_TOKEN=<token> sudo -E bash"
  echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin >/dev/null \
    || die "Token không hợp lệ hoặc đã bị thu hồi — xin nhà cung cấp token mới."
  docker pull -q "$IMAGE" >/dev/null || die "Vẫn không tải được phần mềm. Kiểm tra mạng rồi thử lại."
fi
grn "✓ Đã tải phần mềm"

# ── 3. Tìm máy in USB ────────────────────────────────────────────────────
# Số `lpN` KHÔNG cố định — rút cắm lại dây hay khởi động máy là nó nhảy. Từ bản
# 2026-08-11 việc đó KHÔNG còn ảnh hưởng gì: compose không khai từng thiết bị nữa
# (mount cả /dev), còn bản gán máy in bám SÊ-RI chứ không bám đường dẫn. Dò ở đây
# chỉ để nói cho người lắp biết máy in đã hiện ra chưa.
# CUPS phải xử TRƯỚC khi dò, không phải chỉ nhắc khi dò hụt.
#
# Ca thật ở quán Coffeetree 2026-08-06: máy in ĐANG hiện, cài xong chạy ngon, rồi
# giữa buổi CUPS mới thêm hàng đợi và giật `usblp` — `/dev/usb/lp4` biến mất, bill
# in được nửa tờ rồi máy nhả tiếp mã PostScript của CUPS ra giấy. Bản cũ của script
# này chỉ nhắc CUPS trong nhánh "không thấy máy in", nên ca đó lọt lưới hoàn toàn.
#
# `disable` KHÔNG đủ: quán đó đã disable cả 4 unit từ 05/08 mà `cups.socket` vẫn
# đánh thức `cupsd` (GNOME `gsd-printer` tự dò máy in rồi thêm hàng đợi). Phải `mask`.
if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet cups 2>/dev/null; then
  ylw "⚠ Hệ thống in của Linux (CUPS) đang chạy — nó sẽ GIÀNH máy in nhiệt."
  echo "  Triệu chứng nếu bỏ qua: bill in được vài dòng rồi đứt, hoặc máy nhả ra"
  echo "  mã PostScript, mà phần mềm vẫn báo 'đã in xong' (hỏng im lặng)."
  echo
  if lpstat -v 2>/dev/null | grep -q 'usb://'; then
    echo "  Đang có hàng đợi CUPS trỏ vào máy in USB:"
    lpstat -v 2>/dev/null | grep 'usb://' | sed 's/^/      /'
    echo
  fi
  echo "  Quán KHÔNG in giấy A4 → khoá hẳn CUPS (lệnh dứt điểm, có đường lùi):"
  echo "      sudo lpadmin -x <tên-hàng-đợi>          # xem tên ở dòng trên"
  echo "      sudo systemctl mask --now cups cups.socket cups.path cups-browsed"
  echo "      # gọi máy in trở lại (tương đương rút/cắm dây USB):"
  echo "      ls /sys/bus/usb/drivers/usblp/            # tìm mã cổng, vd 1-2:1.0"
  echo "      echo 0 | sudo tee /sys/bus/usb/devices/1-2/authorized; sleep 2"
  echo "      echo 1 | sudo tee /sys/bus/usb/devices/1-2/authorized"
  echo
  echo "  Muốn dùng lại CUPS sau này:  sudo systemctl unmask cups cups.socket cups.path cups-browsed"
  echo
  echo "  (Vẫn cài tiếp — nhưng chưa khoá CUPS thì đừng tin là in được.)"
  echo
fi

mapfile -t LPS < <(ls /dev/usb/lp* 2>/dev/null || true)
# Dò chỉ để BÁO CHO NGƯỜI LẮP biết máy in đã hiện chưa — KHÔNG còn dùng để dựng
# `devices:` trong compose nữa (xem khối YAML bên dưới, mục "vì sao không khai từng
# thiết bị"). Nhờ vậy máy in cắm sau, hay đổi số `lpN`, đều không phải chạy lại script.
if [ ${#LPS[@]} -gt 0 ]; then
  grn "✓ Thấy máy in: ${LPS[*]}"
else
  ylw "⚠ Không thấy máy in USB nào (/dev/usb/lp* trống)."
  echo "  Vẫn cài tiếp — chương trình in dò lại mỗi nhịp, cắm máy in sau vẫn nhận."
  echo "  Nếu quán có máy in USB đang cắm mà không thấy, khả năng cao là hệ thống in"
  echo "  của Linux (CUPS) đã giành mất. Gỡ hàng đợi của nó rồi cắm lại dây:"
  echo "      lpstat -p                       # xem hàng đợi nào đang giữ"
  echo "      sudo lpadmin -x <tên-hàng-đợi>"
  # `disable` KHÔNG chặn được CUPS — socket/dbus activation vẫn kéo nó dậy rồi nó tự
  # thêm lại hàng đợi và giật `usblp`. Đo thật ở Gấc Đỏ 2026-08-11: cả 4 unit
  # `is-enabled=disabled` từ hôm cài mà `is-active=running`, queue tự mọc lại. Phải `mask`.
  echo "      sudo systemctl mask --now cups cups.socket cups.path cups-browsed"
  echo "                                      # nếu quán không in giấy A4"
fi

# ── 4. Ghi cấu hình chạy ─────────────────────────────────────────────────
mkdir -p "$DIR" "$CFG_DIR"
cat > "$DIR/docker-compose.yml" <<YAML
# Tệp này do install/bridge.sh SINH RA — sửa tay thì lần chạy lại sẽ ghi đè.
#
# VÌ SAO KHÔNG KHAI TỪNG THIẾT BỊ (\`devices: "/dev/usb/lp1:/dev/usb/lp1"\`):
# khai như vậy là bind CỨNG, và nó đẻ ra hai hỏng hóc đã gặp thật:
#
#   1. ĐUA LÚC KHỞI ĐỘNG — ổ cắm máy in ở quán thường bật muộn hơn máy tính. Docker
#      khởi động container trước khi \`usblp\` kịp tạo node ⇒ container chết ngay lúc
#      TẠO với mã 128 ("no such file or directory"), mà lỗi lúc tạo thì Docker KHÔNG
#      thử lại (\`RestartCount=0\`) ⇒ mất in tới khi có người vào bật tay.
#      Gấc Đỏ 2026-08-11: máy boot 07:05, máy in có điện 07:22 → mất in cả buổi sáng.
#   2. CẮM THÊM MÁY IN thì phải dựng lại container mới thấy.
#
# Cách hiện tại: mount cả /dev (thư mục này luôn tồn tại, node mới do nhân tạo ra là
# thấy ngay) + cấp quyền theo NHÓM thiết bị. Chương trình in dò lại \`/dev/usb/lp*\`
# mỗi nhịp nên máy in cắm giữa buổi vẫn nhận, không phải chạy lại script này.
#
# \`c 180:* rmw\` = thiết bị ký tự nhóm 180 — đúng nhóm của \`usblp\`. Mount cả /dev
# nhưng KHÔNG cấp quyền nhóm khác, nên container vẫn không mở nổi ổ đĩa hay thứ gì
# ngoài máy in.
services:
  bridge:
    image: $IMAGE
    container_name: trcf-bridge
    restart: unless-stopped
    # Dùng chung mạng với máy thật để gọi được http://localhost (ERP ở cổng 80).
    network_mode: host
    device_cgroup_rules:
      - "c 180:* rmw"
    volumes:
      - /dev:/dev
      - $CFG_DIR:$CFG_DIR
YAML

# Máy đã cài kiểu TRỰC TIẾP (binary thật nằm đúng chỗ này) thì đừng ghi đè âm thầm:
# dịch vụ systemd cũ vẫn trỏ vào đường dẫn đó, thay bằng vỏ bọc là nó chạy `docker
# compose ...` mỗi lần systemd khởi động — vòng lặp không ai hiểu nổi. Dẹp dịch vụ cũ
# và cất binary sang một bên, nói rõ đã làm gì.
if [ -f "$WRAPPER" ] && ! head -c 200 "$WRAPPER" | grep -q "sinh ra"; then
  ylw "⚠ Máy này đang cài kiểu TRỰC TIẾP (binary ở $WRAPPER)."
  if systemctl is-enabled trcf-bridge >/dev/null 2>&1 || systemctl is-active trcf-bridge >/dev/null 2>&1; then
    echo "  → Dừng và gỡ dịch vụ systemd cũ (bản Docker tự chạy lại, không cần nó)."
    systemctl disable --now trcf-bridge >/dev/null 2>&1 || true
    rm -f /etc/systemd/system/trcf-bridge.service
    systemctl daemon-reload || true
  fi
  mv "$WRAPPER" "$WRAPPER.truc-tiep.bak"
  echo "  → Binary cũ cất tại $WRAPPER.truc-tiep.bak (liên kết máy in trong $CFG_DIR giữ nguyên)."
fi

# Vỏ bọc cho gọn: gõ `trcf-bridge pair ...` y như bản cài trực tiếp, không phải
# nhớ cả câu `docker compose -f ... run --rm`. Dùng `run --rm` chứ không `exec` vì lúc
# ghép thì container chưa chạy (chưa có token để chạy).
cat > "$WRAPPER" <<WRAP
#!/usr/bin/env bash
# Vỏ bọc do install/bridge.sh sinh ra — chạy TRCF Bridge trong container.
# --progress quiet: giấu mấy dòng "Container ... Creating" của compose, chúng chen vào
# giữa thông báo của chương trình in và làm người lắp tưởng có gì đó đang hỏng.
exec docker compose --progress quiet -f "$DIR/docker-compose.yml" run --rm bridge "\$@"
WRAP
chmod +x "$WRAPPER"
grn "✓ Đã cài vào $DIR"

# ── 5. Đã ghép chưa ──────────────────────────────────────────────────────
if [ -s "$CFG_DIR/config.json" ]; then
  echo "→ Máy này đã ghép từ trước — khởi động lại với cấu hình mới ..."
  docker compose -f "$DIR/docker-compose.yml" up -d
  grn "✓ Xong. TRCF Bridge đang chạy."
  echo
  echo "  Xem nhật ký:   docker compose -f $DIR/docker-compose.yml logs -f"
  exit 0
fi

cat <<MSG

$(grn "✓ CÀI XONG.") Còn MỘT bước nữa: ghép với ERP.

  1. Vào ERP → mục $(printf '\033[1mMáy in\033[0m') → $(printf '\033[1mThêm máy in\033[0m') → chọn kết nối $(printf '\033[1mUSB\033[0m') → lưu
  2. Bấm menu ⋯ ở dòng vừa tạo → $(printf '\033[1mLấy mã ghép\033[0m') (mã 6 số, sống 10 phút)
  3. Chạy trên máy này:

       sudo trcf-bridge pair --server http://localhost --code <mã-6-số>

     (máy in cắm ở máy khác thì thay localhost bằng IP máy chủ)

  4. Bật chạy nền:

       docker compose -f $DIR/docker-compose.yml up -d

  Cắm thêm máy in thứ hai (bếp/tem): chỉ cần lặp bước 1–3 với mã mới.
  KHÔNG phải chạy lại script này — chương trình in tự dò thiết bị mới mỗi nhịp.

MSG
