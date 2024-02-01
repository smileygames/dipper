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
 
cloudflare_ID() {
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

generate_body_v4_v6() {
    cat << EOS
{
    "types": ["A", "AAAA"],
    "name": "$DOMAIN",
    "fixed_ipv4": "$IP",
    "fixed_ipv6": "$IPv6",
}
EOS
}

access_v4() {
    curl -X PATCH \
        -H "x-Auth-Key: ${API_KEY}" \
        -H "x-Auth-Email: ${EMAIL}" \
        -H "Content-Type: application/json" \
        -d "$(generate_body_ipv4)" \
        "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${DOMAIN_ID}"

    echo "success to update address"
}
access_v6() {
    curl -X PATCH \
        -H "x-Auth-Key: ${API_KEY}" \
        -H "x-Auth-Email: ${EMAIL}" \
        -H "Content-Type: application/json" \
        -d "$(generate_body_ipv6)" \
        "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${DOMAIN_ID}"

    echo "success to update address"
}

access_v4_v6() {
    curl -X PATCH \
        -H "x-Auth-Key: ${API_KEY}" \
        -H "x-Auth-Email: ${EMAIL}" \
        -H "Content-Type: application/json" \
        -d "$(generate_body_v4_v6)" \
        "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${DOMAIN_ID}"

    echo "success to update address"
}

# 実行スクリプト
cloudflare_ID
case ${Mode} in
   "ipv4") 
        access_v4
        ;;
   "ipv6") 
        access_v6
        ;;
   "ipv4_ipv6") 
        access_v4_v6
        ;;
    * )
        echo "[${Mode}] <- 引数エラーです"
    ;; 
esac

