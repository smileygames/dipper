#!/bin/bash
#
# ./ddns_service/mydns.sh
#
# multi_domain

Mode=$1
My_ipv4=$2
My_ipv6=$3

# IPv4,IPv6を判断して、それぞれのURLでDDNSへアクセス
ip_update_mydns() {
    v4_Mydns=$1
    v6_Mydns=$2
    Array_Num=$3
    ID=$4
    PASS=$5
    DOMAIN=$6

    if [ "$v4_Mydns" = on ]; then
        # バックグラウンドプロセスで実行
        ./dns_access.sh "MYDNS" "${FUNCNAME[0]}" "$Array_Num" "$ID:$PASS ${MYDNS_IPV4_URL}" "$DOMAIN" "4" "update!" &
    fi
    if [ "$v6_Mydns" = on ]; then
        # バックグラウンドプロセスで実行
        ./dns_access.sh "MYDNS" "${FUNCNAME[0]}" "$Array_Num" "$ID:$PASS ${MYDNS_IPV6_URL}" "$DOMAIN" "6" "update!" &
    fi
}

# アドレスをチェックし変更があった場合のみ、DDNSへアクセス
ip_check_mydns() {
    v4_Mydns=$1
    v6_Mydns=$2
    Array_Num=$3
    ID=$4
    PASS=$5
    DOMAIN=$6

    local IP_old=""

    if [[ $My_ipv4 = "" ]]; then
        ./err_message.sh "no_value" "${FUNCNAME[0]}" "自分のIPv4アドレスを取得できなかった"

    elif [ "$v4_Mydns" = on ]; then
        IPv4_old=$(dig "$domain" "A" +short)  # ドメインのアドレスを読み込む

        if [[ "$My_ipv4" != "$IPv4_old" ]]; then
            # バックグラウンドプロセスで実行
            ./dns_access.sh "MYDNS" "${FUNCNAME[0]}" "$Array_Num" "$ID:$PASS ${MYDNS_IPV4_URL}" "$DOMAIN" "4" "$My_ipv4" &
        fi
    fi

    if [[ $My_ipv6 = "" ]]; then
        ./err_message.sh "no_value" "${FUNCNAME[0]}" "自分のIPv6アドレスを取得できなかった"

    elif [ "$v6_Mydns" = on ]; then
        IPv6_old=$(dig "$domain" "AAAA" +short)  # ドメインのアドレスを読み込む

        if [[ "$My_ipv6" != "$IPv6_old" ]]; then
            # バックグラウンドプロセスで実行
            ./dns_access.sh "MYDNS" "${FUNCNAME[0]}" "$Array_Num" "$ID:$PASS ${MYDNS_IPV6_URL}" "$DOMAIN" "6" "$My_ipv6" &
        fi
    fi
}

# 配列のデータを読み込む
mydns_multi_domain() {
    for i in "${!MYDNS_ID[@]}"; do
        if [[ ${MYDNS_ID[$i]} = "" ]] || [[ ${MYDNS_PASS[$i]} = "" ]] || [[ ${MYDNS_DOMAIN[$i]} = "" ]]; then
            ./err_message.sh "no_value" "${FUNCNAME[0]}" "MYDNS_ID[$i] or MYDNS_PASS[$i] or MYDNS_DOMAIN[$i]"
            continue
        fi 
        if [[ ${MYDNS_IPV4[$i]} != on ]] && [[ ${MYDNS_IPV6[$i]} != on ]]; then
            continue
        fi

        if [ "$Mode" = "update" ]; then
            ip_update_mydns "${MYDNS_IPV4[$i]}" "${MYDNS_IPV6[$i]}" "$i" "${MYDNS_ID[$i]}" "${MYDNS_PASS[$i]}" "${MYDNS_DOMAIN[$i]}"
        elif [ "$Mode" = "check" ]; then
            ip_check_mydns "${MYDNS_IPV4[$i]}" "${MYDNS_IPV6[$i]}" "$i" "${MYDNS_ID[$i]}" "${MYDNS_PASS[$i]}" "${MYDNS_DOMAIN[$i]}"
        fi
    done
}

# 実行スクリプト
mydns_multi_domain
