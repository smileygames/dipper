#!/bin/bash
#
# ./cache/count.sh
#
# キャッシュファイルの作成及び、count処理

Cache_Name=$1
Message=$2

# キャッシュファイルのパス
Cache_Dir="../cache"
Cache_File="${Cache_Dir}/${Cache_Name}"

# キャッシュファイル作成
new_cache_file() {
    touch "$Cache_File"
    echo "Count: 1" >> "$Cache_File"
    echo "$Message" >> "$Cache_File"
}

# エラーメッセージ処理が実行されたときのカウントを増やし、メッセージ内容をキャッシュファイルに追加する
update_cache() {
    local new_count=0 old_count=0

    # キャッシュファイルが存在するか確認
    if [ -f "$Cache_File" ]; then
        # キャッシュファイルからカウントを読み込む
        old_count=$(grep "Count:" "$Cache_File" | awk '{print $2}')
        new_count=$((old_count + 1))  # インクリメント

        # カウントをファイル全体を書き換える形で更新
        sed -i "s/Count: $old_count/Count: $new_count/" "$Cache_File"
        # メッセージをファイルの末尾に追記
        echo "$Message" >> "$Cache_File"

    elif [[ -n ${EMAIL_ADR:-} ]]; then
        if [[ -n ${ERR_CHK_TIME:-} ]] || [[ -n ${EMAIL_CHK_DDNS:-} ]]; then
            mkdir -p "$Cache_Dir"
            new_cache_file
        fi
    fi
}

update_cache
