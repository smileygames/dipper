#!/bin/bash
#
# ./ddns_service/mydns.sh
#
# multi_domain

Mode=$1
IP_Version=$2
DNS_Record=$3
IP_New=$4

if [ "$IP_Version" = 4 ]; then
    Login_URL=${MYDNS_IPV4_URL}
elif [ "$IP_Version" = 6 ]; then
    Login_URL=${MYDNS_IPV6_URL}
fi

# 配列のデータを読み込んでDDNSへアクセス
mydns_multi_domain_update() {
    for i in "${!MYDNS_ID[@]}"; do
        if [[ ${MYDNS_ID[$i]} = "" ]] || [[ ${MYDNS_PASS[$i]} = "" ]]; then
            ./err_message.sh "no_value" "${FUNCNAME[0]}" "MYDNS_ID[$i] or MYDNS_PASS[$i]"
            continue
        fi
        if [ "$IP_Version" = 4 ] && [[ ${MYDNS_IPV4[$i]} != on ]]; then
            continue
        elif [ "$IP_Version" = 6 ] && [[ ${MYDNS_IPV6[$i]} != on ]]; then
            continue
        fi
        # バックグラウンドプロセスで実行
        ./dns_access.sh "MYDNS" "${FUNCNAME[0]}" "$i" "${MYDNS_ID[$i]}:${MYDNS_PASS[$i]} ${Login_URL}" &
    done
}

# 配列のデータを読み込んでアドレスをチェックし変更があった場合のみ、DDNSへアクセス
mydns_multi_domain_check() {
    local IP_old=""

    for i in "${!MYDNS_ID[@]}"; do
        if [[ ${MYDNS_ID[$i]} = "" ]] || [[ ${MYDNS_PASS[$i]} = "" ]] || [[ ${MYDNS_DOMAIN[$i]} = "" ]]; then
            ./err_message.sh "no_value" "${FUNCNAME[0]}" "MYDNS_ID[$i] or MYDNS_PASS[$i] or MYDNS_DOMAIN[$i]"
            continue
        fi 
        if [ "$IP_Version" = 4 ] && [[ ${MYDNS_IPV4[$i]} != on ]]; then
            continue
        elif [ "$IP_Version" = 6 ] && [[ ${MYDNS_IPV6[$i]} != on ]]; then
            continue
        fi
        IP_old=$(dig "${MYDNS_DOMAIN[$i]}" "$DNS_Record" +short)  # ドメインのアドレスを読み込む

        if [[ "$IP_New" != "$IP_old" ]]; then
            # バックグラウンドプロセスで実行
            ./dns_access.sh "MYDNS" "${FUNCNAME[0]}" "$i" "${MYDNS_ID[$i]}:${MYDNS_PASS[$i]} ${Login_URL}" &
        fi
    done
}

# 実行スクリプト
case ${Mode} in
   "update")
        mydns_multi_domain_update
        ;;
   "check") 
        mydns_multi_domain_check
        ;;
    * )
        echo "[${Mode}] <- 引数エラーです"
    ;; 
esac
