#!/bin/bash
#
# ./cache/reset.sh
#
# キャッシュファイルのリセット処理

Reset_Cache_Name=$1
# キャッシュファイルのパス
Cache_Dir="../cache"
Reset_File="${Cache_Dir}/${Reset_Cache_Name}"

cache_reset() {
    local current_time
    # 現在のエポック秒を取得
    current_time=$(date +%s)
    # 中身の内容を削除してCOUNT=0を書き込む(reset処理)
    echo "time: $current_time" > "$Reset_File"
}

cache_reset
