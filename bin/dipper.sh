#!/bin/bash
#
# ./dipper.sh
#
# main処理。それぞれのタイマー処理をコールして監視する

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

    if [ "$cache_time" != 0 ] && [[ "$cache_time" =~ ^[0-9]+[dhms]$ ]]; then
            ./time_check.sh "$mode" "$cache_time"
    else
        ./err_message.sh "sleep" "cache_time_set" "$cache_time_name=${cache_time}:無効な形式 例:1d,2h,13m,24s,35: dipper.shをエラー終了しました"
        exit 1
    fi
}

IP_CACHE_TIME=$(cache_time_set "ip_time" "IP_CACHE_TIME" "$IP_CACHE_TIME")
UPDATE_TIME=$(cache_time_set "update" "UPDATE_TIME" "$UPDATE_TIME")
DDNS_TIME=$(cache_time_set "check" "DDNS_TIME" "$DDNS_TIME")
ERR_CHK_TIME=$(cache_time_set "error" "ERR_CHK_TIME" "$ERR_CHK_TIME")
export IP_CACHE_TIME
export UPDATE_TIME
export DDNS_TIME
export ERR_CHK_TIME

err_process() {
    local exit_code=$1
    local process_name=$2

    if [ "$exit_code" != 0 ]; then
        ./err_message.sh "process" "dipper.sh" "endcode=${exit_code}  ${process_name}プロセスが異常終了した為、強制終了しました"
        ./mail/sending.sh "err_mail" "dipperでエラーを検出しました <$(hostname)>" "$EMAIL_ADR"
        exit 1
    fi
}

# タイマーイベントを選択し、実行する
timer_select() {
    local cache_dir="../cache"
    local cache_update="${cache_dir}/update_cache"
    local cache_ddns="${cache_dir}/ddns_cache"
    local cache_err="${cache_dir}/err_mail"
    local run_on

    if [ "$IPV4" = on ] || [ "$IPV6" = on ]; then
            run_on=$(./cache/time_check.sh "$cache_update" "$UPDATE_TIME")
            if [ "$run_on" = on ]; then
                # shellcheck disable=SC1091
                . ./dns_select.sh "update"      # DNSアップデートを開始
                err_process "$?"
            fi
            if [  "$IPV4" = on ] && [ "$IPV4_DDNS" = on ]; then
                run_on=$(./cache/time_check.sh "$cache_ddns" "$DDNS_TIME")
                if [ "$run_on" = on ]; then
                    # shellcheck disable=SC1091
                    . ./dns_select.sh "check"   # DNSチェックを開始
                    err_process "$?"
                fi
            elif [ "$IPV6" = on ] && [ "$IPV6_DDNS" = on ]; then
                run_on=$(./cache/time_check.sh "$cache_ddns" "$DDNS_TIME")
                if [ "$run_on" = on ]; then
                    # shellcheck disable=SC1091
                    . ./dns_select.sh "check"   # DNSチェックを開始
                    err_process "$?"
                fi
            fi

            if [[ -n ${EMAIL_ADR:-} ]] && [ "$ERR_CHK_TIME" != 0 ]; then
                run_on=$(./cache/time_check.sh "$cache_err" "$ERR_CHK_TIME")
                if [ "$run_on" = on ]; then
                    ./mail/sending.sh "err_mail" "dipperでエラーを検出しました <$(hostname)>" "$EMAIL_ADR"
                    err_process "$?"
                fi
            fi
    fi
}

main() {
    local exit_code=""

    ./cache/time_initial.sh
    # バックグラウンドプロセスを監視して通常終了以外の時、異常終了させる
    while true;do
        sleep 10
        timer_select
    done
}

main 
