#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# TRCF ERP — lối tắt gọi bộ cài chính.
#
# Cách cài chuẩn (không cần tải repo này về):
#   cd ~ && curl -fsSL https://raw.githubusercontent.com/nguyentrucanhtuan/fnberp_deploy/main/install/ubuntu.sh | bash
#
# File này chỉ để chạy khi bạn ĐÃ có sẵn thư mục repo trên máy:
#   ./install.sh                         # cài vào ~/fnberp
#   ./install.sh --domain erp.quan.vn    # kèm domain + HTTPS
#   ./install.sh --update                # cập nhật bản mới
#
# Mọi tham số được chuyển thẳng sang install/ubuntu.sh (xem README.md §4).
# ─────────────────────────────────────────────────────────────────────────
set -euo pipefail
exec bash "$(cd "$(dirname "$0")" && pwd)/install/ubuntu.sh" "$@"
