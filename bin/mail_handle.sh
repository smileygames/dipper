#!/bin/bash
#
# ./mail_handle.sh
#
# 変更を検知したらEmailへ通知

Cache_Name=$1
Sub_Message=$2
Email_Adr=$3

# キャッシュファイルのパス
Cache_Dir="../cache"
Cache_File="${Cache_Dir}/${Cache_Name}"

# キャッシュファイル作成
new_cache_file() {
    touch "$Cache_File"
    echo "Count: 0" > "$Cache_File"
}

# メール通知
send_mail_notification() {
    local exit_code

    echo -e "Subject: ${Sub_Message}\nFrom: $(hostname) <server>\nTo: <${Email_Adr}>\n" | 
            cat - "${Cache_File}" > temp && mv temp "${Cache_File}"
    sendmail -t < "${Cache_File}"
    exit_code=$?

    if [ "${exit_code}" != 0 ]; then
        # sendmailコマンドのエラー
        ./err_message.sh "sendmail" "email_ddns_handle.sh" "sendmailコマンドエラー"
    else
        # 中身の内容を削除してCOUNT=0を書き込む(reset処理)
        echo "Count: 0" > "$Cache_File"
    fi
}

# メール通知メイン処理
main() {
    local count=0
    # キャッシュファイルが存在するか確認
    if [ -f "$Cache_File" ]; then
        # キャッシュファイルからカウントとメッセージ内容を読み込む
        count=$(grep "Count:" "$Cache_File" | awk '{print $2}')

        # カウントが1以上であれば、メール通知を送信
        if (( "$count" )); then
            send_mail_notification
        fi

    elif [ ! -f "$Cache_Dir" ]; then
        mkdir -p "$Cache_Dir"
        new_cache_file
    else
        new_cache_file
    fi
}

main
