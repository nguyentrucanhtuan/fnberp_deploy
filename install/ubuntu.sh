#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# CÀI TẤT CẢ TRONG MỘT LỆNH (Ubuntu / Debian)
#
#   cd ~ && curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/ubuntu.sh \
#     | GHCR_TOKEN=<token> bash
#
# Chỉ là lớp gọi lần lượt 2 bước — muốn tách ra thì chạy riêng từng cái:
#   BƯỚC 1  install/docker.sh   cài Docker Engine + Compose
#   BƯỚC 2  install/erp.sh      cài TRCF ERP (yêu cầu đã có Docker)
#
# Mọi tham số truyền vào đây được chuyển thẳng sang BƯỚC 2, ví dụ:
#   curl -fsSL <url> | GHCR_TOKEN=xxx bash -s -- --domain erp.quan.vn
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

RAW_BASE="${TRCF_RAW_BASE:-https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main}"

printf '\n\033[1;36m━━━ BƯỚC 1/2 — CÀI DOCKER ━━━\033[0m\n'
curl -fsSL "$RAW_BASE/install/docker.sh" -o /tmp/trcf-docker.sh \
  || { printf '\n\033[1;31m✗ Không tải được bước 1 (kiểm tra mạng).\033[0m\n' >&2; exit 1; }
bash /tmp/trcf-docker.sh
rm -f /tmp/trcf-docker.sh

printf '\n\033[1;36m━━━ BƯỚC 2/2 — CÀI TRCF ERP ━━━\033[0m\n'
curl -fsSL "$RAW_BASE/install/erp.sh" -o /tmp/trcf-erp.sh \
  || { printf '\n\033[1;31m✗ Không tải được bước 2 (kiểm tra mạng).\033[0m\n' >&2; exit 1; }
bash /tmp/trcf-erp.sh "$@"
rm -f /tmp/trcf-erp.sh
