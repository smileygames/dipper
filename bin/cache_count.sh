#!/bin/bash
#
# ./cache_count.sh
#
# キャッシュファイルの作成及び、count処理

Cache=$1
Message=$2

# キャッシュファイルのパス
Cache_Dir="../cache"
Cache_File="${Cache_Dir}/${Cache}"

# キャッシュファイル作成
new_cache_file() {
    touch "$Cache_File"
    Err_count=0
    echo "Count: $Err_count" >> "$Cache_File"
}

# キャッシュファイルからカウントとメッセージ内容を読み込む
read_cache() {
    # キャッシュファイルが存在するか確認
    if [ -f "$Cache_File" ]; then
        # キャッシュファイルからカウントとメッセージ内容を読み込む
        Err_count=$(grep "Count:" "$Cache_File" | awk '{print $2}')

    elif [ ! -f "$Cache_Dir" ]; then
        mkdir -p "$Cache_Dir"
        new_cache_file
    else
        new_cache_file
    fi
}

# エラーメッセージ処理が実行されたときのカウントを増やし、メッセージ内容をキャッシュファイルに追加する
update_cache() {
    local count=0

    read_cache
    count=$((Err_count + 1))  # インクリメント

    # カウントをファイル全体を書き換える形で更新
    sed -i "s/Count: $Err_count/Count: $count/" "$Cache_File"
    # メッセージをファイルの末尾に追記
    echo "Message: $Message" >> "$Cache_File"
}

update_cache
