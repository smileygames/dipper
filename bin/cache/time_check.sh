#!/bin/bash
#
# ./cache/time_check.sh
#
# キャッシュファイルのチェック処理

Cache_File=$1
Set_Time=$2

ip_cache_read() {
    local date_namee=$1
    local cachet_time

    # キャッシュファイルからipアドレスを読み込んで出力
    cachet_time=$(grep "${date_namee}:" "$Cache_File" | awk '{print $2}')
    echo "$cachet_time"
}

cache_time_check() {
    local set_time_sec old_time now_time diff_time

    if [[ "$Set_Time" != 0 ]] && [ -f "$Cache_File" ]; then
        set_time_sec=$(./time_check.sh "sec_time" "$Set_Time")

        # キャッシュファイルのtimeを読み込む
        old_time=$(ip_cache_read "time")
        # 現在のエポック秒を取得
        now_time=$(date +%s)
        diff_time=$((now_time - old_time))
        # 経過時間が設定された時間より大きい場合、キャッシュを初期化
        if ((diff_time > set_time_sec)); then
            echo "on"
        else
            echo "off"
        fi
    else
        echo "on"
    fi
}

cache_time_check