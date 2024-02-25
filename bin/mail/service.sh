#!/bin/bash
#
# ./mail/service.sh
#
# エラーメッセージが設定時間に1個以上の場合にメールで通知する

mail_err_service() {

    ./mail/sending.sh "err_mail" "dipperでエラーを検出しました <$(hostname)>" "$EMAIL_ADR"
}

mail_err_service
