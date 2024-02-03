#!/bin/bash
#
# ./ddns_service.sh
#
# shellcheck source=/dev/null

# include file
File_dir="../config/"
source "${File_dir}default.conf"
User_File="${File_dir}user.conf"
if [ -e ${User_File} ]; then
    source "${User_File}"
fi
# 引数を変数に代入
Mode=$1

# IPv4とIPv6でアクセスURLを変える
ip_update() {
    if [ "$IPV4" = on ]; then
        multi_ddns "update" "4" "A" "update!"
    fi
    if [ "$IPV6" = on ]; then
        multi_ddns "update" "6" "AAAA" "update!"
    fi
}

# 動的アドレスモードの場合、チェック用にIPvバージョン情報とレコード情報も追加
ip_check() {
    local My_ipv4=""
    local My_ipv6=""

    if [ "$IPV4" = on ] && [ "$IPV4_DDNS" = on ]; then
        My_ipv4=$(dig -4 @resolver1.opendns.com myip.opendns.com A +short)  # 自分のアドレスを読み込む

        if [[ $My_ipv4 = "" ]]; then
            ./err_message.sh "no_value" "${FUNCNAME[0]}" "自分のIPv4アドレスを取得できなかった"
        else
            multi_ddns "check" "4" "A" "$My_ipv4"
        fi
    fi
    if [ "$IPV6" = on ] && [ "$IPV6_DDNS" = on ]; then
        My_ipv6=$(dig -6 @resolver1.opendns.com myip.opendns.com AAAA +short)  # 自分のアドレスを読み込む

        if [[ $My_ipv6 = "" ]]; then
            ./err_message.sh "no_value" "${FUNCNAME[0]}" "自分のIPv6アドレスを取得できなかった"
        else
            multi_ddns "check" "6" "AAAA" "$My_ipv6"
        fi
    fi

    if (( "$cloudflare" )); then
        . ./ddns_service/cloudflare.sh "check" "$My_ipv4" "$My_ipv6"
    fi
}

# 複数のDDNSサービス用（拡張するときは処理を増やす）
multi_ddns() {
    local ddns_Mode=$1
    local IP_Version=$2
    local DNS_Record=$3
    local My_ip=$4

    # MyDNSのDDNSのための処理
    if (( "$mydns" )); then
        . ./ddns_service/mydns.sh "$ddns_Mode" "$IP_Version" "$DNS_Record" "$My_ip"
    fi

    # GoogleのDDNSサービスはIPv4とIPv6が排他制御のための処理
    if (( "$google" )); then
        . ./ddns_service/google.sh "$ddns_Mode" "$IP_Version" "$DNS_Record" "$My_ip"
    fi
}

# 実行スクリプト

# 配列の要素数を変数に代入（DDNSのサービスごと）
mydns=${#MYDNS_ID[@]}
google=${#GOOGLE_ID[@]}
cloudflare=${#CLOUDFLARE_MAIL[@]}

# タイマー処理
case ${Mode} in
   "update")  # アドレス定期通知（一般的なDDNSだと定期的に通知されない場合データが破棄されてしまう）
        if (( "$mydns" )); then
            sleep 1m;ip_update  # 起動から少し待って最初の処理を行う
            while true;do
                # IP更新用の処理を設定値に基づいて実行する
                sleep "$UPDATE_TIME";ip_update
            done
        fi
        ;;
   "check")   # アドレス変更時のみ通知する
        if (( "$mydns" || "$google" || "$cloudflare" )); then
            while true;do
                # IPチェック用の処理を設定値に基づいて実行する
                sleep "$DDNS_TIME";ip_check
            done
        fi
        ;;
    * )
        echo "[${Mode}] <- 引数エラーです"
    ;; 
esac
