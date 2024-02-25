#!/bin/bash
#
# /access/dns_api_access.sh
#
# multi_accece

Mode=$1
Service=$2
Array_Num=$3
My_ipv4=$4
My_ipv6=$5
IPv4_Select=$6
IPv6_Select=$7
Zone=$8
API_token=$9
Domain=${10}
Url=${11}

# 動的アドレスモードの場合、チェック用にIPvバージョン情報とレコード情報も追加
ipv_check_api() {
    local ipv4_old="" ipv6_old=""

    if [[ $My_ipv4 != "" ]] && [ "$IPv4_Select" = on ]; then
        ipv4_old=$(dig "$Domain" "A" +short)  # ドメインのアドレスを読み込む

        if [[ "$My_ipv4" != "$ipv4_old" ]]; then
            api_access "${FUNCNAME[0]}" "A" "$My_ipv4"
        fi
    fi

    if [[ $My_ipv6 != "" ]] && [ "$IPv6_Select" = on ]; then
        ipv6_old=$(dig "$Domain" "AAAA" +short)  # ドメインのアドレスを読み込む

        if [[ "$My_ipv6" != "$ipv6_old" ]]; then
            api_access "${FUNCNAME[0]}" "AAAA" "$My_ipv6"
        fi
    fi
}
 
id_accese() {
    Zone_ID=$(curl -H "Authorization: Bearer ${API_token}" \
                   -sS "$Url?name=${Zone}" |
                   jq -r .result[0].id)

    Domain_ID=$(curl -H "Authorization: Bearer ${API_token}" \
                     -sS "$Url/${Zone_ID}/dns_records?type=${record}&name=${Domain}" |
                     jq -r .result[0].id)
}

api_access() {
    local func_name=$1
    local record=$2
    local ip_adr=$3
    local output exit_code

    id_accese

    output=$(curl -X PATCH \
                  -H "Authorization: Bearer ${API_token}" \
                  -H "Content-Type: application/json" \
                  -d "{\"name\":\"$Domain\",\"type\":\"$record\",\"content\":\"$ip_adr\"}" \
                  -sS "$Url/${Zone_ID}/dns_records/${Domain_ID}")

    exit_code=$?
    if [ "${exit_code}" != 0 ]; then
        ./err_message.sh "curl" "$func_name" "${Service}[$Array_Num]:: ${output}"
    else
        echo "Access successful ${Service} : domain=${Domain} type=${record} IP=${ip_adr}"
        if [[ "${ip_adr}" != "update!" ]]; then
            ./cache/count.sh "ddns_cache" "$(date "+%Y-%m-%d %H:%M:%S")  ${Service} : domain=${Domain} type=${record} IP=${ip_adr}"
        fi
    fi
}

main() {
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
}

# 実行スクリプト
main
