#!/bin/bash
#
# update ddns install.sh
# dipper
#
# - systemd（systemctl）環境を前提とします
# - 強化PID方式で ps の "ps -p PID -o args=" を使うため、procps 系を依存に含めます
# - 想定外OS（Alpine/FreeBSD等）はここでは対象外にします（systemd前提のため）

set -u

Ver="1.24"
SERVICE_NAME="dipper.service"
User_servce="/etc/systemd/system/$SERVICE_NAME"

# -----------------------------
# 前提チェック（systemd）
# -----------------------------
if ! command -v systemctl >/dev/null 2>&1; then
    echo "この install.sh は systemd 環境（systemctl が使えるOS）を前提としています。"
    echo "systemctl が見つからないため終了します。"
    exit 1
fi

# -----------------------------
# パッケージマネージャ判定（対応OSを絞る）
# -----------------------------
detect_pm() {
    if command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    else
        echo ""
    fi
}

PM=$(detect_pm)
if [ -z "$PM" ]; then
    echo "対応していないOS/環境です（apt/dnf/yum/pacman/zypper のいずれも見つかりません）。"
    echo "この install.sh は systemd + 一般的なLinuxを対象としています。"
    exit 1
fi

# -----------------------------
# コマンド → パッケージ名（PM別）
# -----------------------------
pkg_name() {
    local cmd=$1
    local pm=$2

    case "$cmd" in
        curl) echo "curl" ;;
        tar)  echo "tar" ;;
        dig)
            case "$pm" in
                apt) echo "dnsutils" ;;
                *)   echo "bind-utils" ;;   # RHEL系 / Arch / openSUSE など
            esac
            ;;
        jq) echo "jq" ;;
        ps)
            # ps -p PID -o args= を安定して使うための procps 系
            case "$pm" in
                apt)        echo "procps" ;;
                dnf|yum)    echo "procps-ng" ;;
                pacman)     echo "procps-ng" ;;
                zypper)     echo "procps" ;;
                *)          echo "" ;;
            esac
            ;;
        *)
            echo ""
            ;;
    esac
}

# -----------------------------
# 依存コマンドチェック & インストール
# -----------------------------
required_cmds=(curl tar dig jq ps)

missing_cmds=()
for cmd in "${required_cmds[@]}"; do
    command -v "$cmd" >/dev/null 2>&1 || missing_cmds+=("$cmd")
done

if [ ${#missing_cmds[@]} -gt 0 ]; then
    echo "以下のコマンドが見つかりません。"
    echo " ${missing_cmds[*]}"
    read -r -p "これらをインストールしますか？ (y/n): " answer

    case "$answer" in
        [Yy]* )
            echo "インストールを開始します... (pm=$PM)"

            install_pkgs=()
            for cmd in "${missing_cmds[@]}"; do
                pkg=$(pkg_name "$cmd" "$PM")
                if [ -n "${pkg:-}" ]; then
                    install_pkgs+=("$pkg")
                fi
            done

            if [ ${#install_pkgs[@]} -eq 0 ]; then
                echo "インストールすべきパッケージを特定できませんでした。終了します。"
                exit 1
            fi

            echo ">> $PM で ${install_pkgs[*]} をインストールします..."
            case "$PM" in
                apt)
                    sudo apt update
                    sudo apt install -y "${install_pkgs[@]}"
                    ;;
                dnf)
                    sudo dnf install -y "${install_pkgs[@]}"
                    ;;
                yum)
                    sudo yum install -y "${install_pkgs[@]}"
                    ;;
                pacman)
                    sudo pacman -S --noconfirm "${install_pkgs[@]}"
                    ;;
                zypper)
                    sudo zypper install -y "${install_pkgs[@]}"
                    ;;
            esac

            echo "インストールが完了しました！"
            ;;
        [Nn]* )
            echo "インストールをキャンセルしました。"
            exit 0
            ;;
        * )
            echo "有効な入力を選択してください。"
            exit 1
            ;;
    esac
fi

# -----------------------------
# 既存サービスの停止・無効化・削除
# -----------------------------
if [ -e "$User_servce" ]; then
    status=$(systemctl is-active "$SERVICE_NAME" 2>/dev/null || echo "unknown")
    if [ "$status" = "active" ]; then
        sudo systemctl stop "$SERVICE_NAME"
    fi

    enabled=$(systemctl is-enabled "$SERVICE_NAME" 2>/dev/null || echo "unknown")
    if [ "$enabled" = "enabled" ]; then
        sudo systemctl disable "$SERVICE_NAME"
    fi

    if [ -e "$User_servce" ]; then
        sudo rm -f "/etc/systemd/system/$SERVICE_NAME"
    fi

    sudo systemctl daemon-reload
fi

# -----------------------------
# 以前のバージョンのアンインストール
# -----------------------------
sudo rm -rf /usr/local/dipper/bin
sudo rm -rf /usr/local/dipper/cache

# -----------------------------
# v1.01以降のインストール
# -----------------------------
# スクリプトファイルダウンロード＆展開
curl -L "https://github.com/smileygames/dipper/archive/refs/tags/v${Ver}.tar.gz" | sudo tar zxvf - -C ./

sudo mv -fv "dipper-${Ver}" dipper
sudo cp -rv dipper /usr/local/
sudo rm -rf dipper

# 不要ファイル削除（配布用）
sudo rm -rf /usr/local/dipper/.github
sudo rm -rf /usr/local/dipper/.vscode
sudo rm -f  /usr/local/dipper/.gitignore
sudo rm -f  /usr/local/dipper/bin/test.bats

# 実行権限
sudo chmod -R 755 /usr/local/dipper/bin

# サービス有効化
sudo systemctl enable /usr/local/dipper/systemd/dipper.service

# デーモンリロード（サービス反映）
sudo systemctl daemon-reload

echo "dipper v${Ver} のインストールが完了しました。"
