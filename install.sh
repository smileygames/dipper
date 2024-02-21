#!/bin/bash
#
# update ddns install.sh
#
# dipper

Ver="1.19"
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
    # デーモンリロードをして追加したサービスを読み込ませる
    sudo systemctl daemon-reload
fi

# 以前のバージョンのアンインストール処理
sudo rm -rf /usr/local/dipper/bin
sudo rm -rf /usr/local/dipper/cache

# v1.01以降のインストール用

# スクリプトファイルダウンロード＆ファイル属性変更
wget https://github.com/smileygames/dipper/archive/refs/tags/v${Ver}.tar.gz -O - | sudo tar zxvf - -C ./
sudo mv -fv dipper-${Ver} dipper
sudo cp -rv dipper /usr/local/
sudo rm -rf dipper
sudo rm -rf /usr/local/dipper/.github
sudo rm -rf /usr/local/dipper/.vscode
sudo rm -f /usr/local/dipper/.gitignore

sudo chmod -R 755 /usr/local/dipper/bin

# digコマンドの存在を確認し、インストールされていない場合はインストールするかどうかを尋ねる
if ! command -v dig &> /dev/null; then
    read -r -p "digコマンドが見つかりません。インストールしますか？ (y/n): " answer
    case $answer in
        [Yy]* )
            echo "インストールプロセスを開始します..."
            # ディストリビューションの判定
            if [ -x "$(command -v apt)" ]; then
                sudo apt update
                sudo apt install dnsutils
            elif [ -x "$(command -v yum)" ]; then
                sudo yum install bind-utils
            elif [ -x "$(command -v dnf)" ]; then
                sudo dnf install bind-utils
            elif [ -x "$(command -v pacman)" ]; then
                sudo pacman -S bind-tools
            elif [ -x "$(command -v apk)" ]; then
                sudo apk update
                sudo apk add bind-tools
            elif [ -x "$(command -v zypper)" ]; then
                sudo zypper install bind-utils
            elif [ -x "$(command -v pkg)" ]; then
                sudo pkg install bind-tools
            elif [ -x "$(command -v pkgin)" ]; then
                sudo pkgin install bind-tools
            else
                echo "このディストリビューションではdigコマンドのインストールプロセスがサポートされていません。"
            fi
            ;;
        [Nn]* )
            echo "インストールをキャンセルしました。"
            ;;
        * )
            echo "有効な入力を選択してください。"
            ;;
    esac
fi

# jqコマンドの存在を確認し、インストールされていない場合はインストールするかどうかを尋ねる
if ! command -v dig &> /dev/null; then
    read -r -p "jqコマンドが見つかりません。インストールしますか？ (y/n): " answer
    case $answer in
        [Yy]* )
            echo "インストールプロセスを開始します..."
            # ディストリビューションの判定
            # ディストリビューションの判定
            if [ -x "$(command -v apt)" ]; then
                sudo apt update
                sudo apt install jq
            elif [ -x "$(command -v yum)" ]; then
                sudo yum install epel-release   # epelリポジトリを追加（必要な場合）
                sudo yum install jq
            elif [ -x "$(command -v dnf)" ]; then
                sudo dnf install jq
            elif [ -x "$(command -v pacman)" ]; then
                sudo pacman -S jq
            elif [ -x "$(command -v apk)" ]; then
                sudo apk update
                sudo apk add jq
            elif [ -x "$(command -v zypper)" ]; then
                sudo zypper install jq
            elif [ -x "$(command -v pkg)" ]; then
                sudo pkg install jq
            elif [ -x "$(command -v pkgin)" ]; then
                sudo pkgin install jq
            else
                echo "このディストリビューションではjqコマンドインストールプロセスがサポートされていません。"
            fi
            ;;
        [Nn]* )
            echo "インストールをキャンセルしました。"
            ;;
        * )
            echo "有効な入力を選択してください。"
            ;;
    esac
fi

sudo systemctl enable /usr/local/dipper/systemd/dipper.service
# デーモンリロードをして追加したサービスを読み込ませる
sudo systemctl daemon-reload

