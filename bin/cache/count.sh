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

# エラーメッセージ処理が実行されたときのカウントを増やし、メッセージ内容をキャッシュファイルに追加する
update_cache() {
    local new_count=0 old_count=0

    # Emailの通知がoffの場合は何もしない処理
    if [ "$Cache_Name" = "update_cache" ] && [[ "$EMAIL_UP_DDNS" != on ]]; then
        return
    elif [ "$Cache_Name" = "ddns_cache" ] && [[ "$EMAIL_CHK_DDNS" != on ]]; then
        return
    elif [ "$Cache_Name" = "err_mail" ] && [ "$ERR_CHK_TIME" = 0 ]; then
        return
    fi
    # キャッシュファイルが存在するか確認
    if [ -f "$Cache_File" ]; then
        # キャッシュファイルからカウントを読み込む
        old_count=$(grep "Count:" "$Cache_File" | awk '{print $2}')
        new_count=$((old_count + 1))  # インクリメント

        # カウントをファイル全体を書き換える形で更新
        sed -i "s/Count: $old_count/Count: $new_count/" "$Cache_File"
        # メッセージをファイルの末尾に追記
        echo "$Message" >> "$Cache_File"
    fi
}

update_cache
