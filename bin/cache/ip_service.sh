#!/bin/bash
#
# ./cache_ip_service.sh
#
# ipアドレスキャッシュファイルの作成及び、update処理

# キャッシュファイルのパス
Cache_Dir="../cache"
Cache_File="${Cache_Dir}/ip_cache"

main() {
    local wait_time=""

    if [ "$IP_CACHE_TIME" != 0 ]; then

        wait_time=$(./time_check.sh "ip_cache" "$IP_CACHE_TIME")
        while true;do
            if [ -f "$Cache_File" ]; then
                # 中身をクリア
                echo "ipv4:" > "$Cache_File"
                echo "ipv6:" >> "$Cache_File"
            fi
            sleep "$wait_time"
            exit_code=$?
            if [ "${exit_code}" != 0 ]; then
                ./err_message.sh "sleep" "cache_ip_service.sh" "IP_CACHE_TIME=${wait_time}: 無効な時間間隔の為 cache_ip_serviceを終了しました"
                exit 1
            fi
       done
    else
        rm -f "$Cache_File"
    fi
}

main