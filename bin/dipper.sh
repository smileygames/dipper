#!/bin/bash
#
# ./dipper.sh
#
# main処理。それぞれのタイマー処理をコールして監視する

# shellcheck disable=SC1090,1091
## include file
File_dir="../config"
source "${File_dir}/default.conf"
User_File="${File_dir}/user.conf"
if [ -e ${User_File} ]; then
    source "${User_File}"
fi

# エラーメール通知機能がonの場合は初期化処理を行い。offの場合はそれぞれのキャッシュファイルを削除する
mail_service() {
    # キャッシュファイルのパス
    local cache_dir="../cache"
    local cache_err="${cache_dir}/err_mail"
    local cache_ddns="${cache_dir}/ddns_mail"

    if [[ -n ${EMAIL_CHK_ADR:-} ]]; then
        if [[ -n ${ERR_CHK_TIME:-} ]]; then
            ./err_mail_service.sh "$EMAIL_CHK_ADR" "$ERR_CHK_TIME" &
        else
            if [ -f "${cache_err}" ]; then
                rm "${cache_err}"
            fi
            if [ ! -f "${cache_ddns}" ] && [ -d "${cache_dir}" ]; then
                rm -r "${cache_dir}"
            fi
        fi

        if [[ -n ${EMAIL_CHK_DDNS:-} ]]; then
            ./mail_handle.sh "ddns_mail" "IPアドレスの変更がありました" "$EMAIL_CHK_ADR" & 
        else
            if [ -f "${cache_ddns}" ]; then
                rm "${cache_ddns}"
            fi
            if [ ! -f "${cache_err}" ] && [ -d "${cache_dir}" ]; then
                rm -r "${cache_dir}"
            fi
        fi
    else
        if [ -d "${cache_dir}" ]; then
            rm -r "${cache_dir}"
        fi
    fi
}

# タイマーイベントを選択し、実行する
timer_select() {
    if [ "$IPV4" = on ] || [ "$IPV6" = on ]; then
        ./ddns_service.sh "update" &  # DDNSアップデートタイマーを開始
    fi

    if [  "$IPV4" = on ] && [ "$IPV4_DDNS" = on ]; then
        ./ddns_service.sh "check" &  # DDNSチェックタイマーを開始

    elif [ "$IPV6" = on ] && [ "$IPV6_DDNS" = on ]; then
        ./ddns_service.sh "check" &  # DDNSチェックタイマーを開始
    fi
}

main() {
    local exit_code=""
    # 実行スクリプト
    timer_select
    # メール通知機能チェック処理
    mail_service

    # バックグラウンドプロセスを監視して通常終了以外の時、異常終了させる
    while true;do
        wait -n
        exit_code=$?
        if [ "$exit_code" = 127 ]; then
            ./err_message.sh "process" "dipper.sh" "endcode=$exit_code  プロセスが全て終了しました。"
            exit 0
        elif [ "$exit_code" != 0 ]; then
            ./err_message.sh "process" "dipper.sh" "endcode=$exit_code  プロセスのどれかが異常終了した為、強制終了しました。"
            exit 1
        fi
        sleep 1
    done
}

main 
