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
        ./mail_handle.sh "err_mail" "dipperでエラーを検出しました <$(hostname)>" "$Email_Adr"
        sleep "$wait_time"
        exit_code=$?
        if [ "${exit_code}" != 0 ]; then
            ./err_message.sh "sleep" "ERR_CHK_TIME=${wait_time}: 無効な時間間隔の為 err mail serviceを終了しました"
            exit 1
        fi
    done
}

# 実行スクリプト
main
