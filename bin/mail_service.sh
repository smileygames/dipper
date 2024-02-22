#!/bin/bash
#
# ./mail_service.sh
#
# エラーメッセージが設定時間に1個以上の場合にメールで通知する

# メール通知機能チェック処理
mail_err_service() {
    local wait_time=""

    wait_time=$(./time_check.sh "error" "$Check_Time")
    while true;do
        ./mail_sending.sh "err_mail" "dipperでエラーを検出しました <$(hostname)>" "$Email_Adr"
        sleep "$wait_time"
        exit_code=$?
        if [ "${exit_code}" != 0 ]; then
            ./err_message.sh "sleep" "mail_err_service" "ERR_CHK_TIME=${wait_time}: 無効な時間間隔の為 err mail serviceを終了しました"
            exit 1
        fi
    done
}

# メール通知機能チェック処理
main() {
    local cache_dir="../cache"
    local cache_err="${cache_dir}/err_mail"
    local cache_ddns="${cache_dir}/ddns_mail"

    if [[ -n ${EMAIL_CHK_ADR:-} ]]; then
        if [[ -n ${ERR_CHK_TIME:-} ]]; then
            mail_err_service "$EMAIL_CHK_ADR" "$ERR_CHK_TIME" &
        elif [ -f "${cache_err}" ]; then
            rm "${cache_err}"
        fi

        if [[ -n ${EMAIL_CHK_DDNS:-} ]]; then
            ./mail_handle.sh "ddns_mail" "IPアドレスの変更がありました <$(hostname)>" "$EMAIL_CHK_ADR" &
        elif [ -f "${cache_ddns}" ]; then
            rm "${cache_ddns}"
        fi
    fi
}

main