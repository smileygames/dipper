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
export IPV4 IPV4_DDNS IPV6 IPV6_DDNS EMAIL_UP_DDNS EMAIL_CHK_DDNS EMAIL_ADR ERR_CHK_TIME

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

export UPDATE_TIME DDNS_TIME IP_CACHE_TIME ERR_CHK_TIME

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

# タイマーイベントを実行する
# cacheがonのときだけ、指定modeのワーカーをtimeout付きで非同期起動する
timer_run() {
    local mode=$1
    local cache_file=$2
    local time=$3
    local cache_on=0

    cache_on=$(./cache/time_check.sh "$cache_file" "$time")

    if [ "$cache_on" = on ]; then
        timeout 60 ./dns_select.sh "$mode" &
    fi
}


# タイマーイベントを選択する
# 設定値と状態(cache)に基づいて、実行すべきタイマーイベントを選択する
timer_select() {
    local cache_dir="../cache"
    local cache_update="${cache_dir}/update_cache"
    local cache_ddns="${cache_dir}/ddns_cache"
    local cache_err="${cache_dir}/err_mail"

    if [ "$IPV4" = on ] || [ "$IPV6" = on ]; then
        timer_run "update" "$cache_update" "$UPDATE_TIME"

        if { [ "$IPV4" = on ] && [ "$IPV4_DDNS" = on ]; } || { [ "$IPV6" = on ] && [ "$IPV6_DDNS" = on ]; }; then
            timer_run "check" "$cache_ddns" "$DDNS_TIME"
        fi

        if [[ -n ${EMAIL_ADR:-} ]] && [[ "$ERR_CHK_TIME" != 0 ]]; then
            timer_run "err_mail" "$cache_err" "$ERR_CHK_TIME"
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
