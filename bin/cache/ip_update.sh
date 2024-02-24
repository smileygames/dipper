#!/bin/bash
#
# ./cache/ip_update.sh
#
# ipアドレスキャッシュファイルの作成及び、update処理

New_Ipv4=$1
New_Ipv6=$2

# キャッシュファイルのパス
Cache_Dir="../cache"
Cache_File="${Cache_Dir}/ip_cache"

# キャッシュファイル作成
new_ip_cache_file() {
    local current_time

    # 現在のエポック秒を取得
    current_time=$(date +%s)

    echo "time: $current_time" > "$Cache_File"
    echo "ipv4: $New_Ipv4" >> "$Cache_File"
    echo "ipv6: $New_Ipv6" >> "$Cache_File"
}

# IPアドレスををキャッシュファイルに上書きする
ip_update_cache() {
    # キャッシュファイルが存在する場合、それを更新する
    if [ -f "$Cache_File" ]; then
        sed -i "s/^ipv4:.*$/ipv4: $New_Ipv4/" "$Cache_File"
        sed -i "s/^ipv6:.*$/ipv6: $New_Ipv6/" "$Cache_File"

    # キャッシュファイルが存在しない場合、新しいファイルを作成する
    elif [ "$IP_CACHE_TIME" != 0 ]; then
        mkdir -p "$Cache_Dir"
        touch "$Cache_File"
        new_ip_cache_file
    fi
}

ip_update_cache
