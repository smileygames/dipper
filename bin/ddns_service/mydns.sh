#!/bin/bash
#
# ./ddns_service/mydns.sh
#
# multi_domain

Mode=$1
My_ipv4=$2
My_ipv6=$3

# 配列のデータを読み込む
mydns_multi_domain() {
    for i in "${!MYDNS_ID[@]}"; do
        if [[ ${MYDNS_ID[$i]} = "" ]] \
        || [[ ${MYDNS_PASS[$i]} = "" ]] \
        || [[ ${MYDNS_DOMAIN[$i]} = "" ]]; then
            ./err_message.sh \
                "no_value" \
                "${FUNCNAME[0]}" \
                "MYDNS_ID[$i] or MYDNS_PASS[$i] or MYDNS_DOMAIN[$i]"
            continue
        fi 
        if [[ ${MYDNS_IPV4[$i]} != on ]] && [[ ${MYDNS_IPV6[$i]} != on ]]; then
            continue
        fi

        ./dns_access.sh \
            "$Mode" \
            "MYDNS" \
            "$i" \
            "${My_ipv4}" \
            "${My_ipv6}" \
            "${MYDNS_IPV4[$i]}" \
            "${MYDNS_IPV6[$i]}" \
            "${MYDNS_ID[$i]}" \
            "${MYDNS_PASS[$i]}" \
            "${MYDNS_DOMAIN[$i]}" \
            "$MYDNS_IPV4_URL" \
            "$MYDNS_IPV6_URL"
    done
}

# 実行スクリプト
mydns_multi_domain
