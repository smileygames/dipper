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

# エラーメッセージ処理が実行されたときのカウントを増やし、メッセージ内容をキャッシュファイルに追加する
update_cache() {
    local count=0 err_count=0

    # キャッシュファイルが存在するか確認
    if [ -f "$Cache_File" ]; then
        # キャッシュファイルからカウントとメッセージ内容を読み込む
        err_count=$(grep "Count:" "$Cache_File" | awk '{print $2}')
        count=$((err_count + 1))  # インクリメント

        # カウントをファイル全体を書き換える形で更新
        sed -i "s/Count: $err_count/Count: $count/" "$Cache_File"
        # メッセージをファイルの末尾に追記
        echo "Message: $Message" >> "$Cache_File"
    fi
}

update_cache
