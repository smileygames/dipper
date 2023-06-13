#!/bin/bash
#
# update ddns uninstall.sh
#
# dipper 

# v1.00以降用
sudo systemctl stop dipper.service
sudo systemctl disable dipper.service
 # 以前のバージョン用
sudo rm -f /etc/systemd/system/dipper.service

sudo rm -rf /usr/local/dipper
sudo systemctl daemon-reload
