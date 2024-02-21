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

# 引数を変数に代入
Mode=$1
# 配列の要素数を変数に代入（DDNSのサービスごと）
Mydns=${#MYDNS_ID[@]}
CloudFlare=${#CLOUDFLARE_MAIL[@]}

# IPv4とIPv6でアクセスする
multi_update() {
     # MyDNSのDDNSのための処理
    if (( "$Mydns" )); then
        # shellcheck disable=SC1091
        . ./ddns_service/mydns.sh "update" "$IPV4" "$IPV6"
    fi
}

# 動的アドレスモードの場合、チェック用にIPvバージョン情報とレコード情報も追加
ip_check() {
    local my_ipv4="" my_ipv6=""
    local exit_code

    if [ "$IPV4" = on ] && [ "$IPV4_DDNS" = on ]; then
        my_ipv4=$(dig -4 @resolver1.opendns.com myip.opendns.com A +short)  # 自分のアドレスを読み込む
        exit_code=$?
        if [ "${exit_code}" != 0 ]; then
            ./err_message.sh "no_value" "${FUNCNAME[0]}" "自分のIPv4アドレスを取得できなかった"
            my_ipv4=""
        fi
    fi
    if [ "$IPV6" = on ] && [ "$IPV6_DDNS" = on ]; then
        my_ipv6=$(dig -6 @resolver1.opendns.com myip.opendns.com AAAA +short)  # 自分のアドレスを読み込む
#        my_ipv6=$(ip -o a show scope global up | grep -oP '(?<=inet6 ).+(?=/64 )')  # DNSに負担をかけない方法
        exit_code=$?
        if [ "${exit_code}" != 0 ]; then
            ./err_message.sh "no_value" "${FUNCNAME[0]}" "自分のIPv6アドレスを取得できなかった"
            my_ipv6=""
        fi
    fi

    if [[ $my_ipv4 != "" ]] || [[ $my_ipv6 != "" ]]; then
        multi_ddns "$my_ipv4" "$my_ipv6"
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
                wait_time=$(./time_check.sh "$Mode" "$UPDATE_TIME")

                sleep 1m    # 起動から少し待って最初の処理を行う
                while true;do
                    # IP更新用の処理を設定値に基づいて実行する
                    multi_update
                    sleep "$wait_time"
                    exit_code=$?
                    if [ "${exit_code}" != 0 ]; then
                        ./err_message.sh "sleep" "ddns_service.sh" "UPDATE_TIME=${wait_time}: 無効な時間間隔の為 ip update serviceを終了しました"
                        exit 1
                    fi
                done
            fi
            ;;
    "check")   # アドレス変更時のみ通知する
            if (( "$Mydns" || "$CloudFlare" )); then
                wait_time=$(./time_check.sh "$Mode" "$DDNS_TIME")

                while true;do
                    # IPチェック用の処理を設定値に基づいて実行する
                    sleep "$wait_time"
                    exit_code=$?
                    if [ "${exit_code}" != 0 ]; then
                        ./err_message.sh "sleep" "ddns_service.sh" "DDNS_TIME=${wait_time}: 無効な時間間隔の為 ip check serviceを終了しました"
                        exit 1
                    fi
                    ip_check
                    # Email通知処理
                    if [[ -n ${EMAIL_CHK_ADR:-} ]] && [[ -n ${EMAIL_CHK_DDNS:-} ]]; then
                        ./mail_handle.sh "ddns_mail" "IPアドレスの変更がありました <$(hostname)>" "$EMAIL_CHK_ADR" & 
                    fi
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
