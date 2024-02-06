#!/bin/bash
#
# dns_api_access.sh
#
# multi_accece

Mode=$1
service=$2
Array_Num=$3
My_ipv4=$4
My_ipv6=$5
ipv4_select=$6
ipv6_select=$7
Email=$8
API_Key=$9
Domain=${10}
Zone=${11}
url=${12}

# 動的アドレスモードの場合、チェック用にIPvバージョン情報とレコード情報も追加
ipv_check_api() {
    if [[ $My_ipv4 != "" ]] && [ "$ipv4_select" = on ]; then
        IPv4_old=$(dig "$Domain" "A" +short)  # ドメインのアドレスを読み込む

        if [[ ${IPv4_old[$i]} = "" ]]; then
            ./err_message.sh "no_value" "${FUNCNAME[0]}" "ドメインのIPv4アドレスを取得できなかった"

        elif [[ "$My_ipv4" != "$IPv4_old" ]]; then
            # バックグラウンドプロセスで実行
            api_access "${FUNCNAME[0]}" "A" "$My_ipv4"
        fi
    fi

    if [[ $My_ipv6 != "" ]] && [ "$ipv6_select" = on ]; then
        IPv6_old=$(dig "$Domain" "AAAA" +short)  # ドメインのアドレスを読み込む

        if [[ ${IPv6_old[$i]} = "" ]]; then
            ./err_message.sh "no_value" "${FUNCNAME[0]}" "ドメインのIPv6アドレスを取得できなかった"

        elif [[ "$My_ipv6" != "$IPv6_old" ]]; then
            # バックグラウンドプロセスで実行
            api_access "${FUNCNAME[0]}" "AAAA" "$My_ipv6"
        fi
    fi
}
 
id_accese() {
    Zone_ID=`curl -H "x-Auth-Key: ${API_Key}" \
                  -H "x-Auth-Email: ${Email}" \
                  -sS "$url?name=${Zone}" |\
                  jq -r .result[0].id`

#    echo "success to fetch zone id: ${ZONE_ID} domain=${Zone}"

    Domain_ID=`curl -H "x-Auth-Key: ${API_Key}" \
                    -H "x-Auth-Email: ${Email}" \
                    -sS "$url/${Zone_ID}/dns_records?type=${Record}&name=${Domain}" |\
                    jq -r .result[0].id`

#    echo "success to fetch domain id type=${Mode}: ${Domain_ID} domain=${Zone}"
}

api_access() {
    Func_Name=$1
    Record=$2
    IP_adr=$3

    id_accese

    output=`curl -X PATCH \
         -H "x-Auth-Key: ${API_Key}" \
         -H "x-Auth-Email: ${Email}" \
         -H "Content-Type: application/json" \
         -d "{\"name\":\"$Domain\",\"type\":\"$Record\",\"content\":\"$IP_adr\"}" \
         -sS "$url/${Zone_ID}/dns_records/${Domain_ID}"`

    local exit_code=$?
    if [ "${exit_code}" != 0 ]; then
        # curlコマンドのエラー
        ./err_message.sh "curl" "$Func_Name" "${service}_MAIL[$Array_Num]:${service}_API[$Array_Num]: ${output}"
    else
        echo "Access successful ${service} : domain=${Domain} type=${Record} IP=${IP_adr}"
    fi
}

# 実行スクリプト
case ${Mode} in
   "update")
        ;;
   "check") 
        ipv_check_api
        ;;
    * )
        echo "[${Mode}] <- 引数エラーです"
    ;; 
esac