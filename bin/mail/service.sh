#!/bin/bash
#
# ./mail_service.sh
#
# エラーメッセージが設定時間に1個以上の場合にメールで通知する

mail_err_service() {
    local email_adr=$1
    local check_time=$2
    local wait_time=""

    wait_time=$(./time_check.sh "error" "$check_time")
    while true;do
        ./mail/sending.sh "err_mail" "dipperでエラーを検出しました <$(hostname)>" "$email_adr"
        sleep "$wait_time"
        exit_code=$?
        if [ "${exit_code}" != 0 ]; then
            ./err_message.sh "sleep" "mail_service.sh" "ERR_CHK_TIME=${wait_time}: 無効な時間間隔の為 mail_err_serviceを終了しました"
            exit 1
        fi
    done
}

# メール通知機能チェック処理
main() {
    local cache_dir="../cache"
    local cache_err="${cache_dir}/err_mail"
    local cache_ddns="${cache_dir}/ddns_mail"

    if [[ -n ${EMAIL_ADR:-} ]]; then
        if [[ -n ${EMAIL_CHK_DDNS:-} ]]; then
            ./mail/sending.sh "ddns_mail" "IPアドレスの変更がありました <$(hostname)>" "$EMAIL_ADR"
        else
            rm -f "${cache_ddns}"
        fi
        if [[ -n ${ERR_CHK_TIME:-} ]]; then
            mail_err_service "$EMAIL_ADR" "$ERR_CHK_TIME" &
        else
            rm -f "${cache_err}"
        fi
    else
        rm -f "${cache_err}"
        rm -f "${cache_ddns}"
    fi
}

main
