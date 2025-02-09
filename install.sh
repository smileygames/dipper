#!/bin/bash
#
# update ddns install.sh
#
# dipper

Ver="1.24"
SERVICE_NAME="dipper.service"
User_servce="/etc/systemd/system/$SERVICE_NAME"

## 必要なコマンドをインストールする処理
# 各コマンドに対応するパッケージ名を定義
declare -A packages=(
    ["curl"]="curl curl curl curl curl curl curl curl"
    ["tar"]="tar tar tar tar tar tar tar tar"
    ["dig"]="dnsutils bind-utils bind-utils bind-tools bind-tools bind-utils bind-tools bind-tools"
    ["jq"]="jq jq jq jq jq jq jq jq"
)

# インストールが必要なコマンドを格納するリスト
missing_cmds=()

# すべてのコマンドをチェックし、ないものをリストアップ
for cmd in "${!packages[@]}"; do
    command -v "$cmd" &>/dev/null || missing_cmds+=("$cmd")
done

# インストールが必要なコマンドがある場合
if [ ${#missing_cmds[@]} -gt 0 ]; then
    echo "以下のコマンドが見つかりません。"
    echo " ${missing_cmds[*]}"
    read -r -p "これらをインストールしますか？ (y/n): " answer

    case "$answer" in
        [Yy]* )
            echo "インストールを開始します..."

            # パッケージマネージャーごとのリスト
            declare -A install_list
            for cmd in "${missing_cmds[@]}"; do
                IFS=' ' read -r -a package_alternatives <<< "${packages[$cmd]}" || continue

                # 利用可能なパッケージマネージャーを判定してリストに追加
                for pm in apt dnf yum pacman apk zypper pkg pkgin; do
                    if command -v "$pm" &>/dev/null; then
                        install_list[$pm]+="${package_alternatives[0]} "
                        break
                    fi
                done
            done

            # パッケージマネージャーごとに一括インストール
            for pm in "${!install_list[@]}"; do
                echo ">> $pm で ${install_list[$pm]} をインストールします..."
                # shellcheck disable=SC2086
                case "$pm" in
                    apt)    sudo apt update && sudo apt install -y ${install_list[$pm]} ;;
                    dnf)    sudo dnf install -y ${install_list[$pm]} ;;
                    yum)    sudo yum install -y ${install_list[$pm]} ;;
                    pacman) sudo pacman -S --noconfirm ${install_list[$pm]} ;;
                    apk)    sudo apk update && sudo apk add --no-cache ${install_list[$pm]} ;;
                    zypper) sudo zypper install -y ${install_list[$pm]} ;;
                    pkg)    sudo pkg install -y ${install_list[$pm]} ;;
                    pkgin)  sudo pkgin install -y ${install_list[$pm]} ;;
                esac
            done
            echo "インストールが完了しました！"
            ;;
        [Nn]* ) echo "インストールをキャンセルしました。"; exit 0 ;;
        * )     echo "有効な入力を選択してください。" ;;
    esac
fi

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

## v1.01以降のインストール用

# スクリプトファイルダウンロード＆ファイル属性変更
curl -L https://github.com/smileygames/dipper/archive/refs/tags/v${Ver}.tar.gz | sudo tar zxvf - -C ./
sudo mv -fv dipper-${Ver} dipper
sudo cp -rv dipper /usr/local/
sudo rm -rf dipper
sudo rm -rf /usr/local/dipper/.github
sudo rm -rf /usr/local/dipper/.vscode
sudo rm -f /usr/local/dipper/.gitignore
sudo rm -f /usr/local/dipper/bin/test.bats

sudo chmod -R 755 /usr/local/dipper/bin


sudo systemctl enable /usr/local/dipper/systemd/dipper.service
# デーモンリロードをして追加したサービスを読み込ませる
sudo systemctl daemon-reload
