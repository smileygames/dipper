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
    v4_ddns=$1
    v6_ddns=$2
    api=$3
    mail=$4
    zone=$5
    domain=$6

    if [ "$v4_ddns" = on ]; then
        IPv4_old=$(dig "${CLOUDFLARE_DOMAIN[$i]}" "A" +short)  # ドメインのアドレスを読み込む
        if [[ "$My_ipv4" != "$IPv4_old" ]]; then
            # バックグラウンドプロセスで実行
            ./dns_api_access.sh "CLOUDFLARE" "$api" "$mail" "$zone" "$domain" "A" "$My_ipv4" &
        fi
    fi
    if [ "$v6_ddns" = on ]; then
        IPv6_old=$(dig "${CLOUDFLARE_DOMAIN[$i]}" "AAAA" +short)  # ドメインのアドレスを読み込む
        if [[ "$My_ipv6" != "$IPv6_old" ]]; then
            # バックグラウンドプロセスで実行
            ./dns_api_access.sh "CLOUDFLARE" "" "$api" "$mail" "$zone" "$domain" "AAAA"  "$My_ipv6" &
        fi
    fi
}

# CloudFlareの場合用のDDNSアクセス
cloudflare_multi_domain_check() {
    local IP_old=""

    for i in "${!CLOUDFLARE_MAIL[@]}"; do
        if [[ ${CLOUDFLARE_MAIL[$i]} = "" ]] || [[ ${CLOUDFLARE_API[$i]} = "" ]] || [[ ${CLOUDFLARE_ZONE[$i]} = "" ]] || [[ ${CLOUDFLARE_DOMAIN[$i]} = "" ]]; then
            ./err_message.sh "no_value" "${FUNCNAME[0]}" "CLOUDFLARE_MAIL[$i] or CLOUDFLARE_API[$i] or CLOUDFLARE_DOMAIN[$i]"
            continue
        fi

        if [[ ${CLOUDFLARE_IPV4[$i]} != on ]] && [[ ${CLOUDFLARE_IPV6[$i]} != on ]]; then
            continue
        fi
        ip_check_api "${CLOUDFLARE_IPV4[$i]}" "${CLOUDFLARE_IPV6[$i]}" "${CLOUDFLARE_API[$i]}" "${CLOUDFLARE_MAIL[$i]}" "${CLOUDFLARE_ZONE[$i]}" "${CLOUDFLARE_DOMAIN[$i]}"
    done
}

# 実行スクリプト
case ${Mode} in
   "update")
        ;;
   "check") 
        cloudflare_multi_domain_check
        ;;
    * )
        echo "[${Mode}] <- 引数エラーです"
    ;; 
esac
