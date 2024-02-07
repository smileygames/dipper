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
    echo "UPDATE_TIME=${wait_sec}"
    if [[ ${wait_sec} != "" ]] && [ "$wait_sec" -lt 60 ]; then
        echo "UPDATE_TIME lt =${wait_sec}"
        UPDATE_TIME=1m
    fi
    echo "UPDATE_TIME end =${UPDATE_TIME}"
}

time_check_ddns() {
    time_sec "$Time"
    echo "DDNS_TIME=${wait_sec}"
    if [[ ${wait_sec} != "" ]] && [ "$wait_sec" -lt 60 ]; then
        echo "DDNS_TIME lt=${wait_sec}"
        DDNS_TIME=1m
    fi
    echo "DDNS_TIME end =${DDNS_TIME}"
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

