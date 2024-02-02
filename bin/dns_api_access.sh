#!/bin/bash
#
# ./dns_api_access.sh
#
# cloudflare DNS

Mode=$1 # DNS_Record IPv4 or IPv6
API_KEY=$2
EMAIL=$3
ZONE=$4
DOMAIN=$5
IP=$6
ZONE_ID=$7
 
api_access() {
    DOMAIN_ID=`curl -H "x-Auth-Key: ${API_KEY}" \
                    -H "x-Auth-Email: ${EMAIL}" \
                    "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=${Mode}&name=${DOMAIN}" |\
                    jq -r .result[0].id`

    echo "success to fetch domain id type=${Mode}: ${DOMAIN_ID}"

    curl -X PATCH \
        -H "x-Auth-Key: ${API_KEY}" \
        -H "x-Auth-Email: ${EMAIL}" \
        -H "Content-Type: application/json" \
        -d '{
            "name": '$DOMAIN',
            "type": '$Mode',
            "content": '$IP',
        }' \
        "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${DOMAIN_ID}"

    echo "success to update address type=${Mode}"
}

# 実行スクリプト
api_access

