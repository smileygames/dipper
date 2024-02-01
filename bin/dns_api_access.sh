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
IPv6=$7
 
cloudflare_zone_id() {
    ZONE_ID=`curl -H "x-Auth-Key: ${API_KEY}" \
                -H "x-Auth-Email: ${EMAIL}" \
                "https://api.cloudflare.com/client/v4/zones?name=${ZONE}" |\
            jq -r .result[0].id`

    echo "success to fetch zone id: ${ZONE_ID}"
}

generate_body_ipv4() {
    cat << EOS
{
    "types": ["A"],
    "name": "$DOMAIN",
    "content": "$IP"
}
EOS
}

generate_body_ipv6() {
    cat << EOS
{
    "types": ["AAAA"],
    "name": "$DOMAIN",
    "content": "$IP"
}
EOS
}

access_v4() {
    DOMAIN_ID_IPV4=`curl -H "x-Auth-Key: ${API_KEY}" \
                    -H "x-Auth-Email: ${EMAIL}" \
                    "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=A&name=${DOMAIN}" |\
                    jq -r .result[0].id`

    echo "success to fetch domain id: ${DOMAIN_ID}"

    curl -X PATCH \
        -H "x-Auth-Key: ${API_KEY}" \
        -H "x-Auth-Email: ${EMAIL}" \
        -H "Content-Type: application/json" \
        -d "$(generate_body_ipv4)" \
        "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${DOMAIN_ID_IPV4}"

    echo "success to update address ipv4"
}

access_v6() {
    DOMAIN_ID_IPV6=`curl -H "x-Auth-Key: ${API_KEY}" \
                    -H "x-Auth-Email: ${EMAIL}" \
                    "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=AAAA&name=${DOMAIN}" |\
                    jq -r .result[0].id`

    echo "success to fetch domain id: ${DOMAIN_ID}"

    curl -X PATCH \
        -H "x-Auth-Key: ${API_KEY}" \
        -H "x-Auth-Email: ${EMAIL}" \
        -H "Content-Type: application/json" \
        -d "$(generate_body_ipv6)" \
        "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${DOMAIN_ID_IPV6}"

    echo "success to update address ipv6"
}

# 実行スクリプト
cloudflare_zone_id
case ${Mode} in
   "ipv4") 
        access_v4
        ;;
   "ipv6") 
        access_v6
        ;;
    * )
        echo "[${Mode}] <- 引数エラーです"
    ;; 
esac

