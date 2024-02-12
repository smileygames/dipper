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

# 設定時間ごとにカウンターをリセットする
reset_counter() {
    # キャッシュファイルが存在する場合、中身の内容を削除してCOUNT=0を書き込む
    if [ -f "$Cache_File" ]; then
        echo "Count: 0" > "$Cache_File"
    fi
}

# メール通知
send_email_notification() {
    local time_str=""
    local exit_code

    case $Check_Time in
        *s) 
            time_str="${Check_Time%s}秒間" ;;
        *m) 
            time_str="${Check_Time%m}分間" ;;
        *h) 
            time_str="${Check_Time%h}時間" ;;
        *d) 
            time_str="${Check_Time%d}日間" ;;
        *) 
            ;;
    esac

    echo -e "Subject: エラーが${time_str}に${Err_count}個ありました\nFrom: $(hostname) <server>\nTo: <${Email_Adr}>\n" | 
            cat - ${Cache_File} > temp && mv temp ${Cache_File}
    sendmail -t < ${Cache_File}
    exit_code=$?

    if [ "${exit_code}" != 0 ]; then
        # sendmailコマンドのエラー
        ./err_message.sh "sendmail" "email_err_handle.sh" "sendmailコマンドエラー"
    else
        reset_counter
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
    fi
}

main() {
    local wait_time=""

    # 遅延起動で最初の起動を行う
    sleep 1m;handle_error_message

    wait_time=$(./time_check.sh "error" "$Check_Time")
    while true;do
        sleep "$wait_time";handle_error_message
    done
}

# 実行スクリプト
main
