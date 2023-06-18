#!/bin/bash
#
# ./ddns_service/google.sh
#
# multi_domain

Mode=$1
IP_Version=$2
DNS_Record=$3
IP_New=$4

# Googleの場合用のDDNSアクセス
google_multi_domain_check() {
    local IP_old=""

    for i in "${!GOOGLE_ID[@]}"; do
        if [[ ${GOOGLE_ID[$i]} = "" ]] || [[ ${GOOGLE_PASS[$i]} = "" ]] || [[ ${GOOGLE_DOMAIN[$i]} = "" ]]; then
            ./err_message.sh "no_value" "${FUNCNAME[0]}" "GOOGLE_ID[$i] or GOOGLE_PASS[$i] or GOOGLE_DOMAIN[$i]"
            continue
        fi 
        if [ "$IP_Version" = 4 ] && [[ ${GOOGLE_IPV6[$i]} = on ]]; then
            continue
        elif [ "$IP_Version" = 6 ] && [[ ${GOOGLE_IPV6[$i]} = off ]]; then
            continue
        fi
        IP_old=$(dig "${GOOGLE_DOMAIN[$i]}" "$DNS_Record" +short)  # ドメインのアドレスを読み込む

        if [[ "$IP_New" != "$IP_old" ]]; then
            # バックグラウンドプロセスで実行
            ./dns_access.sh "GOOGLE" "${FUNCNAME[0]}" "$i" "${GOOGLE_ID[$i]}:${GOOGLE_PASS[$i]} ${GOOGLE_URL}?hostname=${GOOGLE_DOMAIN[$i]}&myip=${IP_New}" &
        fi
    done
}


# 実行スクリプト
case ${Mode} in
   "update")
        ;;
   "check") 
        google_multi_domain_check
        ;;
    * )
        echo "[${Mode}] <- 引数エラーです"
    ;; 
esac
