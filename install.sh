#!/bin/bash
#
# update ddns install.sh
#
# dipper

Ver="1.02"
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
fi

# 以前のバージョンのアンインストール処理
sudo rm -rf /usr/local/dipper/bin
sudo rm -f /etc/systemd/system/dipper.service

# v1.01以降のインストール用
# スクリプトファイルダウンロード＆ファイル属性変更
wget https://github.com/smileygames/dipper/archive/refs/tags/v${Ver}.tar.gz -O - | sudo tar zxvf - -C ./
sudo mv -fv dipper-${Ver} dipper
sudo cp -rv dipper /usr/local/
sudo rm -rf dipper
sudo chmod -R 755 /usr/local/dipper/bin

sudo systemctl enable /usr/local/dipper/systemd/dipper.service
# デーモンリロードをして追加したサービスを読み込ませる
sudo systemctl daemon-reload

