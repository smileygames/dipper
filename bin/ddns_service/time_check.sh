#!/bin/bash
#
# ./ddns_service/time_check.sh
#
# 1分以下のタイマー処理を認めない

Mode=$1
Time=$2

time_sec() {
    if [ ${#1} -ge 2 ]; then
        target_time=`echo "$1" | cut -c 1-\`expr ${#1} - 1\``
    fi
    case "$1" in
        *d )
            wait_sec=""
            ;;
        *h )
            wait_sec=""
            ;;
        *m )
            wait_sec=""
            ;;
        *s )
            wait_sec="$target_time"
            ;;
        *  )
            wait_sec="$1"
            ;;
    esac
}

time_check_update() {
    time_sec "$Time"
    if [[ ${wait_sec} != "" ]] && [ "$wait_sec" -lt 60 ]; then
        UPDATE_TIME=1m
        ./err_message.sh "no_value" "${FUNCNAME[0]}" "1分以下の値[${wait_sec}s]が入力された為、[UPDATE_TIME=1m] に変更しました"
    fi
}

time_check_ddns() {
    time_sec "$Time"
    if [[ ${wait_sec} != "" ]] && [ "$wait_sec" -lt 60 ]; then
        DDNS_TIME=1m
        ./err_message.sh "no_value" "${FUNCNAME[0]}" "1分以下の値[${wait_sec}s]が入力された為、[DDNS_TIME=1m] に変更しました"
    fi
}

# 実行スクリプト
case ${Mode} in
   "update")  # アドレス定期通知
        time_check_update
        ;;
   "check")   # アドレス変更時のみ通知する
        time_check_ddns
        ;;
    * )
        echo "[${Mode}] <- 引数エラーです"
    ;; 
esac
