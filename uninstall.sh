#!/bin/bash
#
# update ddns uninstall.sh
#
# dipper uninstall script

SERVICE_NAME="dipper.service"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME"

sudo -v || exit 1

# あるかもしれないので、とにかく止める / 無効化（失敗してもOK）
sudo systemctl stop "$SERVICE_NAME" 2>/dev/null || true
sudo systemctl disable "$SERVICE_NAME" 2>/dev/null || true

# unit file があれば削除
sudo rm -f "$SERVICE_FILE"

# systemd 再読み込み
sudo systemctl daemon-reload

# 本体削除
sudo rm -rf /usr/local/dipper

echo "dipper uninstall done."
