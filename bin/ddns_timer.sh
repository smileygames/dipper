#!/bin/bash
#
# ./ddns_timer.sh
#
# shellcheck source=/dev/null

# include file
File_dir="../config/"
source "${File_dir}default.conf"
User_File="${File_dir}user.conf"
if [ -e ${User_File} ]; then
    source "${User_File}"
fi

Mode=$1

# IPv4とIPv6でアクセスURLを変える
ip_update() {
    if [ "$IPV4" = on ]; then
        multi_ddns "update" "4"
    fi
    if [ "$IPV6" = on ]; then
        multi_ddns "update" "6"
    fi
}

# 動的アドレスモードの場合、チェック用にIPvバージョン情報とレコード情報も追加
ip_check() {
    if [ "$IPV4" = on ] && [ "$IPV4_DDNS" = on ]; then
        multi_ddns "check" "4" "A" 
    fi
    if [ "$IPV6" = on ] && [ "$IPV6_DDNS" = on ]; then
        multi_ddns "check" "6" "AAAA"
    fi
}

# 複数のDDNSサービス用
multi_ddns() {
    ddns_Mode=$1
    IP_Version=$2
    DNS_Record=$3

    if [ "$ddns_Mode" = "check" ]; then
        MyIP=$(dig @ident.me -"$IP_Version" +short)  # 自分のアドレスを読み込む
        if [[ $MyIP = "" ]]; then
            ./err_message.sh "no_value" "${FUNCNAME[0]}" "自分のIPアドレスを取得できなかった"
            return 1
        fi
    fi

    # MyDNSのDDNSのための処理
    if [ ${#MYDNS_ID[@]} != 0 ]; then
        . ./ddns_timer/mydns_domain.sh "$ddns_Mode" "$IP_Version" "$DNS_Record" "$MyIP" &
    fi

    # GoogleのDDNSサービスはIPv4とIPv6が排他制御のための処理
    if [ ${#GOOGLE_ID[@]} != 0 ]; then
        . ./ddns_timer/google_domain.sh "$ddns_Mode" "$IP_Version" "$DNS_Record" "$MyIP" &
    fi
}

# 実行スクリプト

# タイマー処理
case ${Mode} in
   "update")  # アドレス定期通知（一般的なDDNSだと定期的に通知されない場合データが破棄されてしまう）
        if [[ ${#MYDNS_ID[@]} != 0 ]]; then
            sleep 5m;ip_update  # 起動から少し待って最初の処理を行う
            while true;do
                sleep "$UPDATE_TIME";ip_update
            done
        fi
        ;;
   "check")   # アドレス変更時のみ通知する
        if [[ ${#MYDNS_ID[@]} != 0 || ${#GOOGLE_ID[@]} != 0 ]]; then
            while true;do
                sleep "$DDNS_TIME";ip_check
            done
        fi
        ;;
    * )
        echo "[${Mode}] <- 引数エラーです"
    ;; 
esac
