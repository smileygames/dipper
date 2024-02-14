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

    # エラーメール通知機能がonの場合、エラーメッセージをメールで通知する
    set -u
    if [[ -n ${EMAIL_CHK_ADR:-} ]] && [[ -n ${ERR_CHK_TIME:-} ]]; then
        ./err_mail_servise.sh "$EMAIL_CHK_ADR" "$ERR_CHK_TIME" &
    fi
}

main() {
    local exit_code=""
    # 実行スクリプト
    timer_select

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
