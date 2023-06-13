#!/bin/bash
#
# update ddns install.sh
#
# dipper

Ver="1.02"

# サービスの停止
sudo systemctl stop dipper.service
sudo systemctl disable dipper.service

# 以前のバージョンのアンインストール処理
sudo rm -rf /usr/local/dipper/bin

# v1.01以降のインストール用
# スクリプトファイルダウンロード＆ファイル属性変更
wget -qO- "https://github.com/smileygames/dipper/archive/refs/tags/v${Ver}.tar.gz" | sudo tar -zxvf - -C /tmp
sudo mv -fv "/tmp/dipper-${Ver}" "/usr/local/dipper"
sudo cp -v "/usr/local/dipper/systemd/dipper.service" "/etc/systemd/system/"
sudo rm -rf "/usr/local/dipper/systemd"
sudo rm -rf "/tmp/dipper"

sudo chmod -R 755 /usr/local/dipper/bin

# デーモンリロードをして追加したサービスを読み込ませる
sudo systemctl daemon-reload
