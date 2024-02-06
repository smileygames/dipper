#!/bin/bash
#
# ./dipper.sh
#
# shellcheck source=/dev/null

# include file
File_dir="../config/"
default_File="${File_dir}default.conf"
User_File="${File_dir}user.conf"

# 変数を逐次的に読み込む関数
load_config() {
    local file="$1"
    shift
    local variables=("$@")

    while IFS= read -r line; do
        local var_name="${line%%=*}"
        if [[ " ${variables[*]} " == *" $var_name "* ]]; then
            eval "$line"
        fi
    done < "$file"
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

# 実行スクリプト
# config fileの必要になる変数だけを逐次的に読み込む
load_config "$default_File" "IPV4" "IPV6" "IPV4_DDNS" "IPV6_DDNS"
if [ -e "$User_File" ]; then
    load_config "$User_File" "IPV4" "IPV6" "IPV4_DDNS" "IPV6_DDNS"
fi

timer_select

# バックグラウンドプロセスを監視して通常終了以外の時、異常終了させる
while true;do
    wait -n
    exit_code=$?
    if [ "$exit_code" = 127 ]; then
        ./err_message.sh "process" "ip_update.sh" "endcode=$exit_code  プロセスが全て終了しました。"
        exit 0
    elif [ "$exit_code" != 0 ]; then
        ./err_message.sh "process" "ip_update.sh" "endcode=$exit_code  プロセスのどれかが異常終了した為、強制終了しました。"
        exit 1
    fi
    sleep 1
done
