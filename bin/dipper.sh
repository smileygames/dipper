#!/bin/bash
#
# ./dipper.sh
#
# main処理。それぞれのタイマー処理をコールして監視する

## include file
File_dir="../config"
# shellcheck disable=SC1091
source "${File_dir}/default.conf"
User_File="${File_dir}/user.conf"
if [ -e ${User_File} ]; then
    # shellcheck disable=SC1090
    source "${User_File}"
fi

# 環境変数宣言
export IPV4
export IPV4_DDNS
export IPV6
export IPV6_DDNS
export IP_CACHE_TIME
export EMAIL_CHK_DDNS
export EMAIL_CHK_ADR
export ERR_CHK_TIME

# タイマーイベントを選択し、実行する
timer_select() {
    if [ "$IPV4" = on ] || [ "$IPV6" = on ]; then
        ./ddns_service.sh "update" &    # DDNSアップデートタイマーを開始
    fi

    if [  "$IPV4" = on ] && [ "$IPV4_DDNS" = on ]; then
        ./ddns_service.sh "check" &     # DDNSチェックタイマーを開始

    elif [ "$IPV6" = on ] && [ "$IPV6_DDNS" = on ]; then
        ./ddns_service.sh "check" &     # DDNSチェックタイマーを開始
    fi
}

dir_check() {
    local cache_dir="../cache"
    # ディレクトリの中身をチェック
    if [ -d "${cache_dir}" ] && [ -z "$(ls -A ${cache_dir})" ]; then
        # ファイルが存在しない
        rm -r "${cache_dir}"
    fi
}

main() {
    local exit_code=""

    timer_select
    ./mail_service.sh
    ./cache_ip_service.sh &
    dir_check
    # バックグラウンドプロセスを監視して通常終了以外の時、異常終了させる
    while true;do
        wait -n
        exit_code=$?
        if [ "$exit_code" = 127 ]; then
            ./err_message.sh "process" "dipper.sh" "endcode=$exit_code  プロセスが全て終了しました。"
            ./mail_sending.sh "err_mail" "dipperでエラーを検出しました <$(hostname)>" "$EMAIL_CHK_ADR"
            exit 0
        elif [ "$exit_code" != 0 ]; then
            ./err_message.sh "process" "dipper.sh" "endcode=$exit_code  プロセスのどれかが異常終了した為、強制終了しました。"
            ./mail_sending.sh "err_mail" "dipperでエラーを検出しました <$(hostname)>" "$EMAIL_CHK_ADR"
            exit 1
        fi
        sleep 10
    done
}

main 
