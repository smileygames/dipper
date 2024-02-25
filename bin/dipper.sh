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
Test_File="${File_dir}/test.conf"
if [ -e ${Test_File} ]; then
    # shellcheck disable=SC1090
    source "${Test_File}"
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
    local mode=$1
    local cache_time_name=$2
    local cache_time=$3
    local cache_time_name cache_time

    if [ "$cache_time" != 0 ]; then
        if [[ "$cache_time" =~ ^[0-9]+[dhms]$ ]]; then
            ./time_check.sh "$mode" "$cache_time"
        else
            ./err_message.sh "sleep" "cache_time_set" "$cache_time_name=${cache_time}:無効な形式 例:1d,2h,13m,24s,35: dipper.shをエラー終了しました"
            exit 1
        fi
    fi
}

cache_time_multi() {
    IP_CACHE_TIME=$(cache_time_set "ip_time" "IP_CACHE_TIME" "$IP_CACHE_TIME")
    UPDATE_TIME=$(cache_time_set "update" "UPDATE_TIME" "$UPDATE_TIME")
    DDNS_TIME=$(cache_time_set "check" "DDNS_TIME" "$DDNS_TIME")
    ERR_CHK_TIME=$(cache_time_set "error" "ERR_CHK_TIME" "$ERR_CHK_TIME")
}

# タイマーイベントを選択し、実行する
timer_select() {
    local run_on

    if [ "$IPV4" = on ] || [ "$IPV6" = on ]; then
            run_on=$(cache_time_check "update_cache" "$UPDATE_TIME")
            if [ "$run_on" = on ]; then
                # shellcheck disable=SC1091
                . ./dns_select.sh "update" &        # DNSアップデートを開始
            fi

            if [  "$IPV4" = on ] && [ "$IPV4_DDNS" = on ]; then
                run_on=$(cache_time_check "ddns_cache" "$DDNS_TIME")
                if [ "$run_on" = on ]; then
                    # shellcheck disable=SC1091
                    . ./dns_select.sh "check" &     # DNSチェックを開始
                fi
            elif [ "$IPV6" = on ] && [ "$IPV6_DDNS" = on ]; then
                run_on=$(cache_time_check "ddns_cache" "$DDNS_TIME")
                if [ "$run_on" = on ]; then
                    # shellcheck disable=SC1091
                    . ./dns_select.sh "check" &     # DNSチェックを開始
                fi
            fi

            if [[ -n ${EMAIL_ADR:-} ]] && [ "$ERR_CHK_TIME" != 0 ]; then
                run_on=$(cache_time_check "err_mail" "$ERR_CHK_TIME")
                if [ "$run_on" = on ]; then
                    ./mail/sending.sh "err_mail" "dipperでエラーを検出しました <$(hostname)>" "$EMAIL_ADR" &
                fi
            fi
    fi
}

cache_check() {
    local cache_dir="../cache"
    local cache_ddns="${cache_dir}/ddns_mail"
    local cache_err="${cache_dir}/err_mail"
    local cache_adr="${cache_dir}/ip_cache"

    if [[ -n ${EMAIL_ADR:-} ]]; then
        if [ "$EMAIL_CHK_DDNS" != on ]; then
            rm -f "${cache_ddns}"
        fi
        if [ "$ERR_CHK_TIME" = 0 ]; then
            rm -f "${cache_err}"
        fi
    else
        rm -f "${cache_ddns}" "${cache_err}"
    fi

    if [ "$IP_CACHE_TIME" = 0 ]; then
        rm -f "${cache_adr}"
    fi

     # キャッシュディレクトリ内が空の場合、ディレクトリを削除
    if [ -d "${cache_dir}" ] && [ -z "$(ls -A ${cache_dir})" ]; then
        rm -r "${cache_dir}"
    fi
}

ip_cache_read() {
    local cache_file=$1
    local ip_date=$1

    # キャッシュファイルからipアドレスを読み込んで出力
    ip_cache_date=$(grep "$ip_date:" "$cache_file" | awk '{print $2}')
    echo "$ip_cache_date"
}

cache_reset() {
    local cache_file=$1
    # 現在のエポック秒を取得
    current_time=$(date +%s)

    echo "time: $current_time" > "$cache_file"
    echo "Count:" >> "$cache_file"
}

cache_time_check() {
    local cache_file=$1
    local set_time=$2
    local set_time_sec old_time now_time diff_time

    if [ "$set_time" != 0 ] && [ -f "$cache_file" ]; then
        set_time_sec=$(./time_check.sh "$cache_file" "sec_time")

        # キャッシュファイルのtimeを読み込む
        old_time=$(ip_cache_read "$cache_file" "time")
        # 現在のエポック秒を取得
        now_time=$(date +%s)
        diff_time=$((now_time - old_time))
        # 経過時間が設定された時間より大きい場合、キャッシュを初期化
        if ((diff_time > set_time_sec)); then
            cache_reset "$cache_file"
            echo "on"
        else
            echo "off"
        fi
    else
        echo "on"
    fi
}

main() {
    local exit_code=""

    cache_time_multi
    cache_check
    # バックグラウンドプロセスを監視して通常終了以外の時、異常終了させる
    while true;do
        timer_select

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
