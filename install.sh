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
wget https://github.com/smileygames/dipper/archive/refs/tags/v${Ver}.tar.gz -O - | sudo tar zxvf - -C ./
sudo mv -fv dipper-${Ver} dipper
sudo cp -rv dipper /usr/local/
sudo rm -rf dipper

sudo chmod -R 755 /usr/local/dipper/bin
sudo ln -s /usr/local/dipper/systemd/dipper.service /etc/systemd/system

# デーモンリロードをして追加したサービスを読み込ませる
sudo systemctl daemon-reload

