#!/bin/bash
#
# ./ddns_service/cloudflare.sh
#
# multi_domain

Mode=$1
My_ipv4=$2
My_ipv6=$3

# 動的アドレスモードの場合、チェック用にIPvバージョン情報とレコード情報も追加
ip_check_api() {
    ipv4_select=$1
    ipv6_select=$2
    mail=$3
    api=$4
    domain=$5
    zone=$6

    if [[ $My_ipv4 = "" ]]; then
        ./err_message.sh "no_value" "${FUNCNAME[0]}" "自分のIPv4アドレスを取得できなかった"

    elif [ "$ipv4_select" = on ]; then
        IPv4_old=$(dig "$domain" "A" +short)  # ドメインのアドレスを読み込む

        if [[ "$My_ipv4" != "$IPv4_old" ]]; then
            # バックグラウンドプロセスで実行
            ./dns_api_access.sh "CLOUDFLARE" "$i" "$api" "$mail" "$zone" "$domain" "A" "$My_ipv4" &
        fi
    fi

    if [[ $My_ipv6 = "" ]]; then
        ./err_message.sh "no_value" "${FUNCNAME[0]}" "自分のIPv6アドレスを取得できなかった"

    elif [ "$ipv6_select" = on ]; then
        IPv6_old=$(dig "$domain" "AAAA" +short)  # ドメインのアドレスを読み込む

        if [[ "$My_ipv6" != "$IPv6_old" ]]; then
            # バックグラウンドプロセスで実行
            ./dns_api_access.sh "CLOUDFLARE" "$i" "$api" "$mail" "$zone" "$domain" "AAAA" "$My_ipv6" &
        fi
    fi
}

# CloudFlareの場合用のDDNSアクセス
cloudflare_multi_domain() {
    for i in "${!CLOUDFLARE_MAIL[@]}"; do
        if [[ ${CLOUDFLARE_MAIL[$i]} = "" ]] || [[ ${CLOUDFLARE_API[$i]} = "" ]] || [[ ${CLOUDFLARE_ZONE[$i]} = "" ]] || [[ ${CLOUDFLARE_DOMAIN[$i]} = "" ]]; then
            ./err_message.sh "no_value" "${FUNCNAME[0]}" "CLOUDFLARE_MAIL[$i] or CLOUDFLARE_API[$i] or CLOUDFLARE_DOMAIN[$i]"
            continue
        fi

        if [[ ${CLOUDFLARE_IPV4[$i]} != on ]] && [[ ${CLOUDFLARE_IPV6[$i]} != on ]]; then
            continue
        fi

        if [ "$Mode" = "check" ]; then
            ip_check_api "${CLOUDFLARE_IPV4[$i]}" "${CLOUDFLARE_IPV6[$i]}" "${CLOUDFLARE_MAIL[$i]}" "${CLOUDFLARE_API[$i]}" "${CLOUDFLARE_DOMAIN[$i]}" "${CLOUDFLARE_ZONE[$i]}"
        fi
    done
}

# 実行スクリプト
cloudflare_multi_domain
