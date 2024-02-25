#!/bin/bash
#
# ./ddns_service.sh
#
# DDNSタイマー起動処理

## include file
File_dir="../config"
# shellcheck disable=SC1091
source "${File_dir}/default.conf"
User_File="${File_dir}/user.conf"
if [ -e ${User_File} ]; then
    # shellcheck disable=SC1090
    source "${User_File}"
fi
Test_File="${File_dir}/test.conf"
if [ -e ${Test_File} ]; then
    # shellcheck disable=SC1090
    source "${Test_File}"
fi

# 引数を変数に代入
Mode=$1
# 配列の要素数を変数に代入（DDNSのサービスごと）
Mydns=${#MYDNS_ID[@]}
CloudFlare=${#CLOUDFLARE_API[@]}

# IPv4とIPv6でアクセスする
multi_update() {
     # MyDNSのDDNSのための処理
    if (( "$Mydns" )); then
        # shellcheck disable=SC1091
        . ./ddns_service/mydns.sh "update" "$IPV4" "$IPV6"
    fi
}

ip_adr_read() {
    local ip_adr

    ip_adr=$(./ip_check.sh)
    # 出力を空白で分割し、変数に割り当てる
    read -r ipv4 <<< "${ip_adr%% *}"  # 最初の空白までを IPv4 アドレスとして読み込む
    read -r ipv6 <<< "${ip_adr#* }"   # 最初の空白以降を IPv6 アドレスとして読み込む

    multi_ddns "$ipv4" "$ipv6"

    if [[ -n ${EMAIL_ADR:-} ]] && [[ -n ${EMAIL_CHK_DDNS:-} ]]; then
        ./mail/sending.sh "ddns_mail" "IPアドレスの変更がありました <$(hostname)>" "$EMAIL_ADR"
    fi
}

# 複数のDDNSサービス用（拡張するときは処理を増やす）
multi_ddns() {
    local my_ipv4=$1
    local my_ipv6=$2

    # MyDNSのDDNSのための処理
    if (( "$Mydns" )); then
        # shellcheck disable=SC1091
        . ./ddns_service/mydns.sh "check" "$my_ipv4" "$my_ipv6"
    fi
    # CloudFlareのDDNSのための処理
    if (( "$CloudFlare" )); then
        # shellcheck disable=SC1091
        . ./ddns_service/cloudflare.sh "check" "$my_ipv4" "$my_ipv6"
    fi
}

main() {
    local wait_time=""
    # タイマー処理
    case ${Mode} in
    "update")  # アドレス定期通知（一般的なDDNSだと定期的に通知されない場合データが破棄されてしまう）
            if (( "$Mydns" )); then
                if [[ "$UPDATE_TIME" =~ ^[0-9]+[dhms]$ ]]; then
                    wait_time=$(./time_check.sh "$Mode" "$UPDATE_TIME")
                else
                    ./err_message.sh "sleep" "ddns_service.sh" "UPDATE_TIME=${UPDATE_TIME}:無効な形式 例:1d,2h,13m,24s,35: ip update serviceをエラー終了しました"
                    exit 1
                fi

                sleep 30    # 起動から30秒待つ
                while true;do
                    # IP更新用の処理を設定値に基づいて実行する
                    multi_update
                    sleep "$wait_time"
                done
            fi
            ;;
    "check")   # アドレス変更時のみ通知する
            if (( "$Mydns" || "$CloudFlare" )); then
                if [[ "$DDNS_TIME" =~ ^[0-9]+[dhms]$ ]]; then
                    wait_time=$(./time_check.sh "$Mode" "$DDNS_TIME")
                else
                    ./err_message.sh "sleep" "ddns_service.sh" "DDNS_TIME=${DDNS_TIME}:無効な形式 例:1d,2h,13m,24s,35: ip check serviceをエラー終了しました"
                    exit 1
                fi

                while true;do
                    # IPチェック用の処理を設定値に基づいて実行する
                    ip_adr_read
                    sleep "$wait_time"
                done
            fi
            ;;
        * )
            echo "[${Mode}] <- 引数エラーです"
            ;; 
    esac
}

# 実行スクリプト
main
