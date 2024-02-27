#!/bin/bash
#
# ./time_check.sh
#
# タイマー時間に制限を付ける

Mode=$1
Time=$2

time_sec() {
    local target_time=""
    local work_sec

    if [ ${#1} -ge 2 ]; then
        target_time=${1%?}  # 末尾の文字を削除
    fi
    case "$1" in
        *d )
            work_sec=$((target_time * 86400))
            ;;
        *h )
            work_sec=$((target_time * 3600))
            ;;
        *m )
            work_sec=$((target_time * 60))
            ;;
        *s )
            work_sec="$target_time"
            ;;
        *  )
            work_sec="$1"
            ;;
    esac
    echo "$work_sec"
}

time_check_update() {
    local wait_sec

    wait_sec=$(time_sec "$Time")
    if [ "$wait_sec" != "" ] && [ "$wait_sec" -lt 180 ]; then
        ./err_message.sh "out_range" "${FUNCNAME[0]}" "3分以下の値[${Time}]が入力された為、[UPDATE_TIME=3m] に変更しました"
        Time=3m
    fi
}

time_check_ddns() {
    local wait_sec
    
    wait_sec=$(time_sec "$Time")
    if [ "$wait_sec" != "" ] && [ "$wait_sec" -lt 60 ]; then
        ./err_message.sh "out_range" "${FUNCNAME[0]}" "1分以下の値[${Time}]が入力された為、[DDNS_TIME=1m] に変更しました"
        Time=1m
    fi
}

time_check_error() {
    local wait_sec
    
    wait_sec=$(time_sec "$Time")
    if [ "$wait_sec" != "" ] && [ "$wait_sec" != 0 ] && [ "$wait_sec" -lt 60 ]; then
        ./err_message.sh "out_range" "${FUNCNAME[0]}" "1分以下の値[${Time}]が入力された為、[ERR_CHK_TIME=1m] に変更しました"
        Time=1m
    fi
}

time_check_ip() {
    local wait_sec
    
    wait_sec=$(time_sec "$Time")
    if [ "$wait_sec" != "" ] && [ "$wait_sec" != 0 ] && [ "$wait_sec" -lt 900 ]; then
        ./err_message.sh "out_range" "${FUNCNAME[0]}" "15分以下の値[${Time}]が入力された為、[IP_CACHE_TIME=15m] に変更しました"
        Time=1m
    fi
}

sec_time_cnv() {
    Time=$(time_sec "$Time")
}

main() {
    # 実行スクリプト
    case ${Mode} in
    "update")   # アドレス定期通知
            time_check_update
            echo "$Time"
            ;;
    "check")    # アドレス変更時のみ通知する
            time_check_ddns
            echo "$Time"
            ;;
    "error")    # エラーカウント処理のタイムチェック
            time_check_error
            echo "$Time"
            ;;
    "ip_time")  # IP_CACHE_TIMEを秒数に変換
            time_check_ip
            echo "$Time"
            ;;
    "sec_time")  # IP_CACHE_TIMEを秒数に変換
            sec_time_cnv
            echo "$Time"
            ;;
        * )
            ./err_message.sh "no_value" "${FUNCNAME[0]}" "[${Mode}] <- 引数エラーです"
            ;; 
    esac
}

main
