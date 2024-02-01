#!/bin/bash
#
# ./dns_api_access.sh
#
# cloudflare DNS

Mode=$1
API_KEY=$2
EMAIL=$3
ZONE=$4
DOMAIN=$5
IP=$6
 
generate_body() {
    cat << EOS
{
    "type": "$DNS_Record",
    "name": "$DOMAIN",
    "content": "$IP"
}
EOS
}

cloudflare_access() {
    ZONE_ID=`curl -H "x-Auth-Key: ${API_KEY}" \
                -H "x-Auth-Email: ${EMAIL}" \
                "https://api.cloudflare.com/client/v4/zones?name=${ZONE}" |\
            jq -r .result[0].id`

    echo "success to fetch zone id: ${ZONE_ID}"

    DOMAIN_ID=`curl -H "x-Auth-Key: ${API_KEY}" \
                    -H "x-Auth-Email: ${EMAIL}" \
                    "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=AAAA&name=${DOMAIN}" |\
            jq -r .result[0].id`

    echo "success to fetch domain id: ${DOMAIN_ID}"

    curl -X PATCH \
        -H "x-Auth-Key: ${API_KEY}" \
        -H "x-Auth-Email: ${EMAIL}" \
        -H "Content-Type: application/json" \
        -d "$(generate_body)" \
        "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${DOMAIN_ID}"

    echo "success to update address"
}

# 実行スクリプト
case ${Mode} in
   "cloudflare") 
        cloudflare_access
        ;;
    * )
        echo "[${Mode}] <- 引数エラーです"
    ;; 
esac

