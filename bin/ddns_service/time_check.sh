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
            work_sec=`expr $target_time \* 86400`
            ;;
        *h )
            work_sec=`expr $target_time \* 3600`
            ;;
        *m )
            work_sec=`expr $target_time \* 60`
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
    wait_sec=$(time_sec "$Time")
    if [[ ${wait_sec} != "" ]] && [ "$wait_sec" -lt 180 ]; then
        UPDATE_TIME=3m
        ./err_message.sh "no_value" "${FUNCNAME[0]}" "3分以下の値[${wait_sec}s]が入力された為、[UPDATE_TIME=3m] に変更しました"
    fi
}

time_check_ddns() {
    wait_sec=$(time_sec "$Time")
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
