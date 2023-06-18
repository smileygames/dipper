#!/bin/bash
#
# update ddns uninstall.sh
#
# dipper 

SERVICE_NAME="dipper.service"
User_servce="/etc/systemd/system/$SERVICE_NAME"

if [ -e ${User_servce} ]; then
    # サービスの状態を確認
    status=$(systemctl is-active "$SERVICE_NAME")
    # 状態に応じて処理を分岐
    if [ "$status" = "active" ]; then
        sudo systemctl stop "$SERVICE_NAME"
    fi

    # サービスの有効化状態を確認
    enabled=$(systemctl is-enabled "$SERVICE_NAME")
    # 有効化状態に応じて処理を分岐
    if [ "$enabled" = "enabled" ]; then
        sudo systemctl disable "$SERVICE_NAME"
    fi

    if [ -e ${User_servce} ]; then
        sudo rm -f /etc/systemd/system/dipper.service
    fi
    sudo systemctl daemon-reload
fi

sudo rm -rf /usr/local/dipper
