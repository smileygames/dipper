#!/bin/bash
#
# ./err_mail_service.sh
#
# エラーメッセージが設定時間に1個以上の場合にメールで通知する

Email_Adr=$1
Check_Time=$2

main() {
    local wait_time=""

    wait_time=$(./time_check.sh "error" "$Check_Time")
    while true;do
        ./mail_handle.sh "err_mail" "dipperでエラーを検出しました" "$Email_Adr" &
        sleep "$wait_time" 
    done
}

# 実行スクリプト
main
