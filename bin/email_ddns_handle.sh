#!/bin/bash
#
# ./email_ddns_handle.sh
#
# DDNSへIPアドレスの変更をしたらEmailへ通知

# キャッシュファイルのパス
Cache_Dir="../cache"
Cache_File="${Cache_Dir}/ddns_mail"
Count=0

Email_Adr=$1

# メール通知
send_email_notification() {
    mail -s "IPアドレスの変更が${Count}件ありました" "$Email_Adr" < $Cache_File
}

# 設定時間ごとにカウンターをリセットする
reset_counter() {
    # キャッシュファイルが存在する場合、中身の内容を削除してCOUNT=0を書き込む
    if [ -f "$Cache_File" ]; then
        echo "Count: 0" > "$Cache_File"
    fi
}

# ipアドレス更新メッセージが生成された場合の処理
handle_ddns_message() {
    # キャッシュファイルが存在するか確認
    if [ -f "$Cache_File" ]; then
        # キャッシュファイルからカウントとメッセージ内容を読み込む
        Count=$(grep "Count:" "$Cache_File" | awk '{print $2}')

        # カウントが1以上であれば、メール通知を送信
        if (( "$Count" )); then
            send_email_notification
        fi
        reset_counter
    fi
}

handle_ddns_message
