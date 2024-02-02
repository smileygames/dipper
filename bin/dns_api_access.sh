#!/bin/bash
#
# ./dns_api_access.sh
#
# cloudflare DNS

Mode=$1
Array_Num=$2
API_Key=$3
Email=$4
Zone=$5
Domain=$6
Record=$7
IP_adr=$8
 
id_accese() {
    Zone_ID=`curl -H "x-Auth-Key: ${API_Key}" \
                  -H "x-Auth-Email: ${Email}" \
                  -sS "https://api.cloudflare.com/client/v4/zones?name=${Zone}" |\
                  jq -r .result[0].id`

#    echo "success to fetch zone id: ${ZONE_ID} domain=${Zone}"

    Domain_ID=`curl -H "x-Auth-Key: ${API_Key}" \
                    -H "x-Auth-Email: ${Email}" \
                    -sS "https://api.cloudflare.com/client/v4/zones/${Zone_ID}/dns_records?type=${Record}&name=${Domain}" |\
                    jq -r .result[0].id`

#    echo "success to fetch domain id type=${Mode}: ${Domain_ID} domain=${Zone}"
}

api_access() {
    output=`curl -X PATCH \
         -H "x-Auth-Key: ${API_Key}" \
         -H "x-Auth-Email: ${Email}" \
         -H "Content-Type: application/json" \
         -d "{\"name\":\"$Domain\",\"type\":\"$Record\",\"content\":\"$IP_adr\"}" \
         -sS "https://api.cloudflare.com/client/v4/zones/${Zone_ID}/dns_records/${Domain_ID}"`

    local exit_code=$?
    if [ "${exit_code}" != 0 ]; then
        # curlコマンドのエラー
        ./err_message.sh "curl" "api_access" "${Mode}_MAIL[$Array_Num]:${Mode}_DOMAIN[$Array_Num]: ${output}"
    else
        echo "success to ${Mode} update address : domain=${Domain} type=${Record} IP=${IP_adr}"
    fi
}

# 実行スクリプト
id_accese
api_access

