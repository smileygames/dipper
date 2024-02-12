#!/bin/bash
#
# ./email_err_handle.sh
#
# エラーメッセージが1時間に10個以上の場合にメールで通知する

# キャッシュファイルのパス
Cache_Dir="../cache"
Cache_File="${Cache_Dir}/err_mail"
Err_count=0

Email_Adr=$1
Check_Time=$2
Check_Count=$3

# メール通知
send_email_notification() {
    mail -s "エラーが${Check_Time}に${Check_Count}個以上ありました" "$Email_Adr" < $Cache_File
}

# 設定時間ごとにカウンターをリセットする
reset_counter() {
    # キャッシュファイルが存在する場合、中身の内容を削除してCOUNT=0を書き込む
    if [ -f "$Cache_File" ]; then
        echo "Count: 0" > "$Cache_File"
    fi
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
        fi
        reset_counter
    fi
}

main() {
    local wait_time=""

    reset_counter
    wait_time=$(./time_check.sh "error" "$Check_Time")
    while true;do
        sleep "$wait_time";handle_error_message
    done
}

# 実行スクリプト
main
