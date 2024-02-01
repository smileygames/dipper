#!/bin/bash
#
# ./ddns_service/cloudflare.sh
#
# multi_domain

# Googleの場合用のDDNSアクセス
cloudflare_multi_domain_check() {
    local IP_old=""

    for i in "${!CLOUDFLARE_MAIL[@]}"; do
        if [[ ${CLOUDFLARE_MAIL[$i]} = "" ]] || [[ ${CLOUDFLARE_API[$i]} = "" ]] || [[ ${CLOUDFLARE_ZONE[$i]} = "" ]] || [[ ${CLOUDFLARE_DOMAIN[$i]} = "" ]]; then
            ./err_message.sh "no_value" "${FUNCNAME[0]}" "CLOUDFLARE_MAIL[$i] or CLOUDFLARE_API[$i] or CLOUDFLARE_DOMAIN[$i]"
            continue
        fi
        if [ "$IP_Version" = 4 ] && [[ ${CLOUDFLARE_IPV6[$i]} = on ]]; then
            continue
        elif [ "$IP_Version" = 6 ] && [[ ${CLOUDFLARE_IPV6[$i]} != on ]]; then
            continue
        fi
        IP_old=$(dig "${CLOUDFLARE_DOMAIN[$i]}" "$DNS_Record" +short)  # ドメインのアドレスを読み込む

        if [[ "$IP_New" != "$IP_old" ]]; then
            # バックグラウンドプロセスで実行
            ./dns_api_access.sh "cloudflare" "${CLOUDFLARE_API[$i]}" "${CLOUDFLARE_MAIL[$i]}" "${CLOUDFLARE_ZONE[$i]}" "${CLOUDFLARE_DOMAIN[$i]}" "${$IP_New}" &
        fi
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
