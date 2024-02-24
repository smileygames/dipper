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
export EMAIL_ADR
export ERR_CHK_TIME

cache_time_set() {
    if [ "$IP_CACHE_TIME" != 0 ]; then
        if [[ "$IP_CACHE_TIME" =~ ^[0-9]+[dhms]$ ]]; then
            IP_CACHE_TIME_SEC=$(./time_check.sh "ip_time" "$IP_CACHE_TIME")
            export IP_CACHE_TIME_SEC
        else
            ./err_message.sh "sleep" "cache_time_set" "IP_CACHE_TIME=${IP_CACHE_TIME}:無効な形式 例:1d,2h,13m,24s,35: dipper.shをエラー終了しました"
            exit 1
        fi
    fi
}

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
        # ファイルが存在しない場合、削除
        rm -r "${cache_dir}"
    fi
}

main() {
    local exit_code=""

    cache_time_set
    timer_select
    ./mail/service.sh &
    dir_check
    # バックグラウンドプロセスを監視して通常終了以外の時、異常終了させる
    while true;do
        wait -n
        exit_code=$?
        if [ "$exit_code" = 127 ]; then
            ./err_message.sh "process" "dipper.sh" "endcode=$exit_code  プロセスが全て終了しました"
            ./mail/sending.sh "err_mail" "dipperでエラーを検出しました <$(hostname)>" "$EMAIL_ADR"
            exit 0
        elif [ "$exit_code" != 0 ]; then
            ./err_message.sh "process" "dipper.sh" "endcode=$exit_code  プロセスのどれかが異常終了した為、強制終了しました"
            ./mail/sending.sh "err_mail" "dipperでエラーを検出しました <$(hostname)>" "$EMAIL_ADR"
            exit 1
        fi
        sleep 10
    done
}

main 
