#!/bin/bash
#
# ./email_err_handle.sh
#
# エラーメッセージが1時間に10個以上の場合にメールで通知する

# キャッシュファイルのパス
Cache_Dir="../cache"
Cache_File="${Cache_Dir}/err_mail"
Count=0

Email_Adr=$1
Check_Time=$2

# 設定時間ごとにカウンターをリセットする
reset_counter() {
    # キャッシュファイルが存在する場合、中身の内容を削除してCOUNT=0を書き込む
    if [ -f "$Cache_File" ]; then
        echo "Count: 0" > "$Cache_File"
    fi
}

# メール通知
send_email_notification() {
    local exit_code

    echo -e "Subject: dipperでエラーを検出しました\nFrom: $(hostname) <server>\nTo: <${Email_Adr}>\n" | 
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

# キャッシュファイル作成
new_cache_file() {
    touch "$Cache_File"
    Count=0
    echo "Count: $Count" >> "$Cache_File"
}

# エラーメッセージが生成された場合の処理
handle_error_message() {
    # キャッシュファイルが存在するか確認
    if [ -f "$Cache_File" ]; then
        # キャッシュファイルからカウントとメッセージ内容を読み込む
        Count=$(grep "Count:" "$Cache_File" | awk '{print $2}')

        # エラーカウントが閾値を超えた場合、メール通知を送信
        if (( "$Count" )); then
            send_email_notification
        fi

    elif [ ! -f "$Cache_Dir" ]; then
        mkdir -p "$Cache_Dir"
        new_cache_file
    else
        new_cache_file
    fi
}

main() {
    local wait_time=""

    wait_time=$(./time_check.sh "error" "$Check_Time")
    # 最初の起動を行う
    handle_error_message
    while true;do
        sleep "$wait_time";handle_error_message
    done
}

# 実行スクリプト
main
