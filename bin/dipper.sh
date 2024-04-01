#!/bin/bash
#
# ./dipper.sh
#
# main処理。それぞれのタイマー処理をコールして監視する

## include file
default_File="../config/default.conf"
User_File="../config/user.conf"
# shellcheck disable=SC1090
source "${default_File}"
if [ -e ${User_File} ]; then
    # shellcheck disable=SC1090
    source "${User_File}"
fi

# 環境変数宣言
export IPV4
export IPV4_DDNS
export IPV6
export IPV6_DDNS
export EMAIL_UP_DDNS
export EMAIL_CHK_DDNS
export EMAIL_ADR
export ERR_CHK_TIME

cache_time_set() {
    local mode=$1
    local cache_time_name=$2
    local cache_time=$3

    if [[ "$cache_time" =~ ^[0-9]+[0-9]*[dhms]?$ ]]; then
        ./time_check.sh "$mode" "$cache_time"
    else
        ./err_message.sh "sleep" "cache_time_set" "$cache_time_name=${cache_time}:無効な形式 例:1d,2h,13m,24s,35: dipper.shをエラー終了しました"
        exit 1
    fi
}

err_process() {
    local exit_code=$1
    local process_name=$2

    if [[ "$exit_code" != 0 ]]; then
        ./err_message.sh "process" "dipper.sh" "endcode=${exit_code}  ${process_name}プロセスが異常終了した為、強制終了しました"
        if [[ -n ${EMAIL_ADR:-} ]] && [[ "$ERR_CHK_TIME" != 0 ]]; then
            ./mail/sending.sh "err_mail" "dipperでエラーを検出しました <$(hostname)>" "$EMAIL_ADR"
        fi
        exit 1
    fi
}

UPDATE_TIME=$(cache_time_set "update" "UPDATE_TIME" "$UPDATE_TIME")
err_process "$?"
DDNS_TIME=$(cache_time_set "check" "DDNS_TIME" "$DDNS_TIME")
err_process "$?"
IP_CACHE_TIME=$(cache_time_set "ip_time" "IP_CACHE_TIME" "$IP_CACHE_TIME")
err_process "$?"
ERR_CHK_TIME=$(cache_time_set "error" "ERR_CHK_TIME" "$ERR_CHK_TIME")
err_process "$?"
export UPDATE_TIME
export DDNS_TIME
export IP_CACHE_TIME
export ERR_CHK_TIME

dns_service_check() {
    local total_count=0

    # 配列の要素数を変数に代入（DDNSのサービスごと）
    (( total_count += ${#MYDNS_ID[@]} ))
    (( total_count += ${#CLOUDFLARE_API[@]} ))

    # 全てのDNSサービスに値が何もない場合の処理
    if [ $total_count = 0 ]; then
        err_process 1 "dns_service"
    fi
}

# タイマーイベントを選択し、実行する
timer_select() {
    local cache_dir="../cache"
    local cache_update="${cache_dir}/update_cache"
    local cache_ddns="${cache_dir}/ddns_cache"
    local cache_err="${cache_dir}/err_mail"
    local cache_on=0

    if [ "$IPV4" = on ] || [ "$IPV6" = on ]; then
        cache_on=$(./cache/time_check.sh "$cache_update" "$UPDATE_TIME")
        if [ "$cache_on" = on ]; then
            ./dns_select.sh "update" &      # DNSアップデートを開始
        fi

        if { [ "$IPV4" = on ] && [ "$IPV4_DDNS" = on ]; } || { [ "$IPV6" = on ] && [ "$IPV6_DDNS" = on ]; }; then
            cache_on=$(./cache/time_check.sh "$cache_ddns" "$DDNS_TIME")
            if [ "$cache_on" = on ]; then
                ./dns_select.sh "check" &      # DNSアップデートを開始
            fi
        fi

        if [[ -n ${EMAIL_ADR:-} ]] && [[ "$ERR_CHK_TIME" != 0 ]]; then
            cache_on=$(./cache/time_check.sh "$cache_err" "$ERR_CHK_TIME")
            if [ "$cache_on" = on ]; then
                ./dns_select.sh "err_mail" &      # DNSアップデートを開始
            fi
        fi
    else
        exit 0
    fi
}

main() {
    ./cache/initial.sh
    dns_service_check

    sleep 10
    while true;do
        timer_select
        sleep 30
    done
}

main 
