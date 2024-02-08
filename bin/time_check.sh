#!/bin/bash
#
# ./ddns_service/time_check.sh
#
# タイマー時間に制限を付ける

time_sec() {
    local target_time work_sec

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
    local update_time=$1
    local wait_sec

    wait_sec=$(time_sec "$update_time")
    if [[ ${wait_sec} != "" ]] && [ "$wait_sec" -lt 180 ]; then
        wait_sec=3m
        ./err_message.sh "no_value" "${FUNCNAME[0]}" "3分以下の値[${wait_sec}s]が入力された為、[UPDATE_TIME=3m] に変更しました"
    fi
    echo "$wait_sec"
}

time_check_ddns() {
    local ddns_time=$1
    local wait_sec
    
    wait_sec=$(time_sec "$ddns_time")
    if [[ ${wait_sec} != "" ]] && [ "$wait_sec" -lt 60 ]; then
        wait_sec=1m
        ./err_message.sh "no_value" "${FUNCNAME[0]}" "1分以下の値[${wait_sec}s]が入力された為、[DDNS_TIME=1m] に変更しました"
    fi
    echo "$wait_sec"
}
