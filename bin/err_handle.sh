#!/bin/bash
#
# ./err_handle.sh
#
# エラーメッセージが1時間に10個以上の場合にメールで通知する

# キャッシュファイルのディレクトリパス
Cache_Dir="../cache"
# キャッシュファイルのパス
Cache_File="${Cache_Dir}/err_mail.txt"
Err_count=0

Check_Time=$1
Check_Count=$2
Email_Adr=$3

# メール通知の閾値

# メール通知関数
send_email_notification() {
    mail -s "エラーが${Check_Time}に${Check_Count}個以上ありました" "$Email_Adr" < $Cache_File
}


# 設定時間ごとにカウンターをリセットする関数
reset_counter() {
    # キャッシュファイルが存在する場合、中身の内容を削除してCOUNT=0を書き込む
    if [ -f "$Cache_File" ]; then
        echo "Count: 0" > "$Cache_File"
    fi
}

# キャッシュファイルからカウントとメッセージ内容を読み込む関数
read_cache() {
    # キャッシュファイルからカウントとメッセージ内容を読み込む
    Err_count=$(grep "Count:" "$Cache_File" | awk '{print $2}')
    # カウントとメッセージ内容を出力
    echo "Count: $COUNT"
}

# エラーメッセージが生成された場合の処理
handle_error_message() {
    # キャッシュファイルが存在するか確認
    if [ -f "$Cache_File" ]; then
        # キャッシュファイルからカウントとメッセージ内容を読み込む
        Err_count=$(grep "Count:" "$Cache_File" | awk '{print $2}')

        # エラーカウントが閾値を超えた場合、メール通知を送信
        if (( "$Err_count" >= "$Check_Count" )); then
            send_email_notification
            reset_counter
        fi
    fi
}

main() {
    reset_counter

    while true;do
        sleep "$Check_Time";handle_error_message
    done
}

# 実行スクリプト
main
