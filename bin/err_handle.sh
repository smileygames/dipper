#!/bin/bash
#
# ./err_handle.sh
#
# エラーメッセージが1時間に10個以上の場合にメールで通知する

Check_Time=$1
Check_Count=$2
Email_Adr=$3

# エラーメッセージのカウンター
export ERR_COUNT=0
# メール通知の閾値

# メール通知関数
send_email_notification() {
    # ここにメール送信のコードを記述します
    echo -e "エラーメッセージが${Check_Time}に${Check_Count}個以上ありました。\n${ERR_MESSAGE}" |
            mail -s "エラー通知" "$Email_Adr"
}

# 設定時間ごとにカウンターをリセットする関数
reset_counter() {
    ERR_COUNT=0
}

# エラーメッセージが生成された場合の処理
handle_error_message() {
    # エラーカウントが閾値を超えた場合、メール通知を送信
    if [ $ERR_COUNT -ge "$Check_Count" ]; then
        send_email_notification
        reset_counter
    fi
}

main() {
    while true;do
        sleep "$Check_Time";handle_error_message
    done
}

# 実行スクリプト
main
