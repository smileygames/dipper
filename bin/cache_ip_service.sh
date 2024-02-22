#!/bin/bash
#
# ./cache_ip_service.sh
#
# ipアドレスキャッシュファイルの作成及び、update処理

# キャッシュファイルのパス
Cache_Dir="../cache"
Cache_File="${Cache_Dir}/ip_cache"

main() {
    if [ "$IP_CACHE_TIME" != 0 ]; then
        local wait_time=""

        wait_time=$(./time_check.sh "ip_cache" "$IP_CACHE_TIME")
        while true;do
            sleep "$wait_time"
            exit_code=$?
            if [ "${exit_code}" != 0 ]; then
                ./err_message.sh "sleep" "cache_ip_service.sh" "IP_CACHE_TIME=${wait_time}: 無効な時間間隔の為 cache_ip_serviceを終了しました"
                exit 1
            fi
            rm -f "$Cache_File"
        done
    else
        rm -f "$Cache_File"
    fi
}

main