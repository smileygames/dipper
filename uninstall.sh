#!/bin/bash
#
# update ddns uninstall.sh
#
# dipper uninstall script

SERVICE_NAME="dipper.service"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME"

# -----------------------------
# sudo を先に確保
# -----------------------------
sudo -v || exit 1

# -----------------------------
# systemd service 停止・無効化
# -----------------------------
if [ -f "$SERVICE_FILE" ]; then
    status=$(systemctl is-active "$SERVICE_NAME" 2>/dev/null || true)
    if [ "$status" = "active" ]; then
        sudo systemctl stop "$SERVICE_NAME"
    fi

    enabled=$(systemctl is-enabled "$SERVICE_NAME" 2>/dev/null || true)
    if [ "$enabled" = "enabled" ]; then
        sudo systemctl disable "$SERVICE_NAME"
    fi

    # service ファイル削除
    sudo rm -f "$SERVICE_FILE"

    sudo systemctl daemon-reload
else
    echo "service file not found: $SERVICE_FILE"
fi

# -----------------------------
# dipper 本体削除
# -----------------------------
if [ -d /usr/local/dipper ]; then
    sudo rm -rf /usr/local/dipper
else
    echo "/usr/local/dipper not found"
fi

echo "dipper uninstall done."
