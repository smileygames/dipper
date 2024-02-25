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

# メール通知機能チェック処理
main() {
    local cache_dir="../cache"
    local cache_err="${cache_dir}/err_mail"
    local cache_ddns="${cache_dir}/ddns_mail"

    if [[ -n ${EMAIL_ADR:-} ]]; then
        if [ "$EMAIL_CHK_DDNS" != on ]; then
            rm -f "${cache_ddns}"
        else
            ./mail/sending.sh "ddns_mail" "IPアドレスの変更がありました <$(hostname)>" "$EMAIL_ADR"
        fi

        if [ "$ERR_CHK_TIME" = 0 ]; then
            rm -f "${cache_err}"
        else
            mail_err_service
        fi
    else
        rm -f "${cache_err}"
        rm -f "${cache_ddns}"
    fi
}

main
