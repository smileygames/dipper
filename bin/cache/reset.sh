#!/bin/bash
#
# ./cache/reset.sh
#
# キャッシュファイルのリセット処理

Reset_Cache_Name=$1
# キャッシュファイルのパス
Cache_Dir="../cache"
Reset_File="${Cache_Dir}/${Reset_Cache_Name}"

ip_cache_read() {
    local date_name=$1
    local cachet_time

    # キャッシュファイルからデータを読み込んで出力
    cachet_time=$(grep "${date_name}:" "$Reset_File" | awk '{print $2}')
    echo "$cachet_time"
}

cache_reset() {
    local old_time old_pid

    # キャッシュファイルのデータを読み込む
    old_time=$(ip_cache_read "time")
    old_pid=$(ip_cache_read "pid")
    # 中身の内容を削除してCOUNT=0を書き込む(reset処理)
    echo "time: $old_time" > "$Reset_File"
    echo "pid: $old_pid" >> "$Reset_File"
    echo "Count: 0" >> "$Reset_File"
}

cache_reset
