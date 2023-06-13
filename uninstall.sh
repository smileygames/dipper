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
        systemctl stop "$SERVICE_NAME"
    fi

    # サービスの有効化状態を確認
    enabled=$(systemctl is-enabled "$SERVICE_NAME")
    # 有効化状態に応じて処理を分岐
    if [ "$enabled" = "enabled" ]; then
        systemctl disable "$SERVICE_NAME"
    fi
fi

 # 以前のバージョン用
sudo rm -f /etc/systemd/system/dipper.service

sudo rm -rf /usr/local/dipper
sudo systemctl daemon-reload
