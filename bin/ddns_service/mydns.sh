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
    Name="MYDNS"

    for i in "${!${Name}_ID[@]}"; do
        if [[ ${${Name}_ID[$i]} = "" ]] || [[ ${${Name}_PASS[$i]} = "" ]] || [[ ${${Name}_DOMAIN[$i]} = "" ]]; then
            ./err_message.sh "no_value" "${FUNCNAME[0]}" "${${Name}_ID[$i]} or ${${Name}_PASS[$i]} or ${${Name}_DOMAIN[$i]}"
            continue
        fi 
        if [[ ${${Name}_IPV4[$i]} != on ]] && [[ ${${Name}_IPV6[$i]} != on ]]; then
            continue
        fi
        # バックグランドで実行 "&"
        .dns_access.sh "$Mode" "${Name}" "$i" "$My_ipv4" "$My_ipv6" "${${Name}_IPV4[$i]}" "${${Name}_IPV6[$i]}" "${${Name}_ID[$i]}" "${${Name}_PASS[$i]}" "${${Name}_DOMAIN[$i]}" "${${Name}_IPV4_URL}" "${${Name}_IPV6_URL}" &
    done
}

# 実行スクリプト
mydns_multi_domain
