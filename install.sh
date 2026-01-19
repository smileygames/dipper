#!/bin/bash
#
# update ddns install.sh
#
# dipper は以下の環境を前提としています:
# - Linux
# - systemd (systemctl)
# - /proc が利用可能
# これらを満たさない場合はインストールを行いません

Ver="2.0"

# 任意：インストール元 ref（ブランチ名 / タグ名 / コミットSHA）
# 指定がなければ従来通り v${Ver} を使う
DIPPER_REF="${DIPPER_REF:-}"

SERVICE_NAME="dipper.service"
User_servce="/etc/systemd/system/$SERVICE_NAME"

# -----------------------------
# Linux(systemd + /proc) 前提チェック
# -----------------------------
if [ "$(uname -s)" != "Linux" ]; then
    echo "この環境は Linux ではありません。"
    echo "Detected OS: $(uname -s)"
    echo "インストールをキャンセルしました。"
    exit 0
fi

if [ ! -d /proc ]; then
    echo "/proc が存在しません。"
    echo "この環境は dipper の動作対象外です。"
    echo "インストールをキャンセルしました。"
    exit 0
fi

if ! command -v systemctl >/dev/null 2>&1; then
    echo "systemd (systemctl) が見つかりません。"
    echo "この環境は dipper の動作対象外です。"
    echo "インストールをキャンセルしました。"
    exit 0
fi

# -----------------------------
# 必要コマンドのチェック＆インストール
# -----------------------------
# 各コマンドに対応するパッケージ名を定義（Linux向けのみ想定）
declare -A packages=(
    ["curl"]="curl curl curl curl curl"
    ["tar"]="tar tar tar tar tar"
    ["dig"]="dnsutils bind-utils bind-utils bind-tools bind-tools"
    ["jq"]="jq jq jq jq jq"
)

missing_cmds=()
for cmd in "${!packages[@]}"; do
    command -v "$cmd" &>/dev/null || missing_cmds+=("$cmd")
done

if [ ${#missing_cmds[@]} -gt 0 ]; then
    echo "以下のコマンドが見つかりません。"
    echo " ${missing_cmds[*]}"
    read -r -p "これらをインストールしますか？ (y/n): " answer

    case "$answer" in
        [Yy]* )
            echo "インストールを開始します..."

            declare -A install_list
            for cmd in "${missing_cmds[@]}"; do
                IFS=' ' read -r -a package_alternatives <<< "${packages[$cmd]}" || continue

                # 利用可能なパッケージマネージャーを判定してリストに追加
                # Linux(systemd想定)のみ: apt / dnf / yum / pacman / zypper
                for pm in apt dnf yum pacman zypper; do
                    if command -v "$pm" &>/dev/null; then
                        install_list[$pm]+="${package_alternatives[0]} "
                        break
                    fi
                done
            done

            for pm in "${!install_list[@]}"; do
                echo ">> $pm で ${install_list[$pm]} をインストールします..."
                # shellcheck disable=SC2086
                case "$pm" in
                    apt)    sudo apt update && sudo apt install -y ${install_list[$pm]} ;;
                    dnf)    sudo dnf install -y ${install_list[$pm]} ;;
                    yum)    sudo yum install -y ${install_list[$pm]} ;;
                    pacman) sudo pacman -S --noconfirm ${install_list[$pm]} ;;
                    zypper) sudo zypper install -y ${install_list[$pm]} ;;
                esac
            done

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
# 以降 sudo を多用するため、先に認証を確保
# -----------------------------
sudo -v || exit 1

# -----------------------------
# 既存サービスの停止/無効化（存在する場合）
# -----------------------------
if [ -e "${User_servce}" ]; then
    status=$(systemctl is-active "$SERVICE_NAME" 2>/dev/null || true)
    if [ "$status" = "active" ]; then
        sudo systemctl stop "$SERVICE_NAME"
    fi

    enabled=$(systemctl is-enabled "$SERVICE_NAME" 2>/dev/null || true)
    if [ "$enabled" = "enabled" ]; then
        sudo systemctl disable "$SERVICE_NAME"
    fi

    # サービスファイル削除
    sudo rm -f "${User_servce}"

    sudo systemctl daemon-reload
fi

# -----------------------------
# tmp 作業ディレクトリ準備（必ず掃除）
# -----------------------------
backup_dir="$(mktemp -d)"
workdir="$(mktemp -d)"
trap 'sudo rm -rf "$backup_dir" "$workdir"' EXIT

echo "backup_dir: $backup_dir"
echo "workdir: $workdir"

# -----------------------------
# ユーザー設定＆キャッシュ退避
# -----------------------------
# user.conf 退避（存在する場合のみ）
if [ -f /usr/local/dipper/config/user.conf ]; then
    mkdir -p "$backup_dir/config"
    sudo cp -a /usr/local/dipper/config/user.conf "$backup_dir/config/"
fi

# cache 退避（存在する場合のみ）
if [ -d /usr/local/dipper/cache ]; then
    sudo cp -a /usr/local/dipper/cache "$backup_dir/"
fi

# -----------------------------
# インストール元 ref 決定
# -----------------------------
if [ -n "$DIPPER_REF" ]; then
    ref="$DIPPER_REF"
else
    ref="v${Ver}"
fi

# -----------------------------
# ダウンロード＆展開（tmp）
# -----------------------------
curl -fsSL "https://github.com/smileygames/dipper/archive/${ref}.tar.gz" \
    | tar zxvf - -C "$workdir"

src_dir="$(find "$workdir" -maxdepth 1 -type d -name 'dipper-*' | head -n 1)"
if [ -z "$src_dir" ]; then
    echo "展開ディレクトリが見つかりません"
    exit 1
fi
mv -fv "$src_dir" "$workdir/dipper"

# -----------------------------
# 安全確認（想定外を起こさない）
# -----------------------------
# workdir が空/ルートなどの場合は即停止（rm事故防止）
if [ -z "${workdir:-}" ] || [ "$workdir" = "/" ]; then
    echo "workdir が不正です: workdir=[$workdir]"
    exit 1
fi
# dipper 配置に失敗していたら即停止（mv失敗/展開失敗の検知）
if [ ! -d "$workdir/dipper/bin" ]; then
    echo "配置に失敗しました: $workdir/dipper/bin が見つかりません"
    exit 1
fi

# -----------------------------
# 不要ファイル除去（確実に入れない）
# -----------------------------
sudo rm -rf "$workdir/dipper/.github" "$workdir/dipper/.vscode" "$workdir/dipper/bin/tests"
sudo rm -f  "$workdir/dipper/.gitignore" "$workdir/dipper/bin/test.bats" "$workdir/dipper/README_AI.txt"

# -----------------------------
# インストール（入れ替え）
#   ※ user.conf / cache は後で復元する
# -----------------------------
sudo rm -rf /usr/local/dipper
sudo cp -r "$workdir/dipper" /usr/local/dipper

sudo chmod -R 755 /usr/local/dipper/bin

# -----------------------------
# 退避物の復元（user.conf / cache）
# -----------------------------
if [ -f "$backup_dir/config/user.conf" ]; then
    sudo mkdir -p /usr/local/dipper/config
    sudo cp -a "$backup_dir/config/user.conf" /usr/local/dipper/config/user.conf
fi

if [ -d "$backup_dir/cache" ]; then
    sudo rm -rf /usr/local/dipper/cache
    sudo cp -a "$backup_dir/cache" /usr/local/dipper/
fi

# -----------------------------
# systemd 登録
# -----------------------------
sudo cp -f /usr/local/dipper/systemd/dipper.service /etc/systemd/system/dipper.service
sudo rm -rf /usr/local/dipper/systemd

# SELinux: コンテキストを正規化（ある環境だけ）
if command -v restorecon >/dev/null 2>&1; then
    sudo restorecon -v /etc/systemd/system/dipper.service >/dev/null 2>&1 || true
    sudo restorecon -Rv /usr/local/dipper >/dev/null 2>&1 || true
fi

sudo systemctl daemon-reload
sudo systemctl enable dipper.service

echo "install done."
echo "ref: $ref"
