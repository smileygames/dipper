#!/bin/bash
#
# ./ddns_service/cloudflare.sh
#
# multi_domain

Mode=$1
My_ipv4=$2
My_ipv6=$3

# CloudFlareの場合用のDDNSアクセス
cloudflare_multi_domain() {
    local domain=""

    for i in "${!CLOUDFLARE_API[@]}"; do
        if [[ ${CLOUDFLARE_API[$i]} = "" ]] \
        || [[ ${CLOUDFLARE_ZONE[$i]} = "" ]] \
        || [[ ${CLOUDFLARE_DOMAIN[$i]} = "" ]]; then
            ./err_message.sh \
                "no_value" \
                "${FUNCNAME[0]}" \
                "CLOUDFLARE_API[$i] or CLOUDFLARE_ZONE[$i] or CLOUDFLARE_DOMAIN[$i]"
            continue
        fi
        if [[ ${CLOUDFLARE_IPV4[$i]} != on ]] && [[ ${CLOUDFLARE_IPV6[$i]} != on ]]; then
            continue
        fi
        # CLOUDFLARE_DOMAIN[]に入っている変数に”,”があった場合、カンマで区切って配列に格納する
        IFS=',' read -r -a domain <<< "${CLOUDFLARE_DOMAIN[$i]}"
        for j in "${!domain[@]}"; do
            ./access/dns_api_access.sh \
                "$Mode" \
                "CLOUDFLARE" \
                "$i" \
                "${My_ipv4}" \
                "${My_ipv6}"  \
                "${CLOUDFLARE_IPV4[$i]}" \
                "${CLOUDFLARE_IPV6[$i]}" \
                "${CLOUDFLARE_ZONE[$i]}" \
                "${CLOUDFLARE_API[$i]}" \
                "${domain[$j]}" \
                "$CLOUDFLARE_URL"
        done
    done
}

# 実行スクリプト
cloudflare_multi_domain
