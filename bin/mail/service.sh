#!/bin/bash
#
# ./mail/service.sh
#
# エラーメッセージが設定時間に1個以上の場合にメールで通知する

mail_err_service() {
    local wait_time=""

    if [[ "$ERR_CHK_TIME" =~ ^[0-9]+[dhms]$ ]]; then
        wait_time=$(./time_check.sh "error" "$ERR_CHK_TIME")
    else
        ./err_message.sh "sleep" "mail_service.sh" "ERR_CHK_TIME=${ERR_CHK_TIME}:無効な形式 例:1d,2h,13m,24s,35: mail_err_serviceをエラー終了しました"
        exit 1
    fi

    while true;do
        ./mail/sending.sh "err_mail" "dipperでエラーを検出しました <$(hostname)>" "$EMAIL_ADR"
        sleep "$wait_time"
    done
}

mail_err_service
