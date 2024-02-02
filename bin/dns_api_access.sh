#!/bin/bash
#
# ./dns_api_access.sh
#
# cloudflare DNS

Mode=$1 # DNS_Record IPv4 or IPv6
API_Key=$2
Email=$3
Zone=$4
Domain=$5
IP_adr=$6
 
id_accese() {
    Zone_ID=`curl -H "x-Auth-Key: ${API_Key}" \
                  -H "x-Auth-Email: ${Email}" \
                  -sS "https://api.cloudflare.com/client/v4/zones?name=${Zone}" |\
                  jq -r .result[0].id`

#    echo "success to fetch zone id: ${ZONE_ID} domain=${Zone}"

    Domain_ID=`curl -H "x-Auth-Key: ${API_Key}" \
                    -H "x-Auth-Email: ${Email}" \
                    -sS "https://api.cloudflare.com/client/v4/zones/${Zone_ID}/dns_records?type=${Mode}&name=${Domain}" |\
                    jq -r .result[0].id`

#    echo "success to fetch domain id type=${Mode}: ${Domain_ID} domain=${Zone}"
}

api_access() {
    curl -X PATCH \
         -H "x-Auth-Key: ${API_Key}" \
         -H "x-Auth-Email: ${Email}" \
         -H "Content-Type: application/json" \
         -d "{\"name\":\"$Domain\",\"type\":\"$Mode\",\"content\":\"$IP_adr\"}" \
         -sS "https://api.cloudflare.com/client/v4/zones/${Zone_ID}/dns_records/${Domain_ID}"

    echo "success to update address domain=${Domain} type=${Mode}"
}

# 実行スクリプト
id_accese
api_access

