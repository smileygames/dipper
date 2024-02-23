#!/bin/bash
#
# ./cache_ip_update.sh
#
# ipアドレスキャッシュファイルの作成及び、update処理

new_Ipv4=$1
new_Ipv6=$2

# キャッシュファイルのパス
Cache_Dir="../cache"
Cache_File="${Cache_Dir}/ip_cache"

# キャッシュファイル作成
new_ip_cache_file() {
    touch "$Cache_File"
    # アドレスをファイルの末尾に追記
    echo "ipv4: $new_Ipv4" >> "$Cache_File"
    echo "ipv6: $new_Ipv6" >> "$Cache_File"
}

# IPアドレスををキャッシュファイルに上書きする
ip_update_cache() {
    # キャッシュファイルが存在する場合、それを更新する
    if [ -f "$Cache_File" ]; then
        sed -i "s/^ipv4:.*$/ipv4: $new_Ipv4/" "$Cache_File"
        sed -i "s/^ipv6:.*$/ipv6: $new_Ipv6/" "$Cache_File"

    # キャッシュファイルが存在しない場合、新しいファイルを作成する
    elif [ "$IP_CACHE_TIME" != 0 ]; then
        mkdir -p "$Cache_Dir"
        new_ip_cache_file
    fi
}

ip_update_cache
