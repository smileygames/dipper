#!/bin/bash
#
# /access/dns_access.sh
#
# multi_accece

Mode=$1
Service=$2
Array_Num=$3
My_ipv4=$4
My_ipv6=$5
IPv4_Select=$6
IPv6_Select=$7
Id=$8
Pass=$9
Domain=${10}
IPv4_url=${11}
IPv6_url=${12}

# IPv4,IPv6を判断して、それぞれのURLでDDNSへアクセス
ipv_update() {
    if [ "$IPv4_Select" = on ]; then
        access "${FUNCNAME[0]}" "${IPv4_url}" "A" "update!"
    fi

    if [ "$IPv6_Select" = on ]; then
        access "${FUNCNAME[0]}" "${IPv6_url}" "AAAA" "update!"
    fi
}

# アドレスをチェックし変更があった場合のみ、DDNSへアクセス
ipv_check() {
    local ipv4_old="" ipv6_old=""

    if [[ $My_ipv4 != "" ]] && [ "$IPv4_Select" = on ]; then
        ipv4_old=$(dig "$Domain" "A" +short)  # ドメインのアドレスを読み込む

        if [[ "$My_ipv4" != "$ipv4_old" ]]; then
            access "${FUNCNAME[0]}" "${IPv4_url}" "A" "$My_ipv4"
        fi
    fi

    if [[ $My_ipv6 != "" ]] && [ "$IPv6_Select" = on ]; then
        ipv6_old=$(dig "$Domain" "AAAA" +short)  # ドメインのアドレスを読み込む

        if [[ "$My_ipv6" != "$ipv6_old" ]]; then
            access "${FUNCNAME[0]}" "${IPv6_url}" "AAAA" "$My_ipv6"
        fi
    fi
}

access() {
    local func_name=$1
    local access_url=$2
    local record=$3
    local ip_adr=$4

    local output exit_code
    local max_time=30

    # DDNSへアクセスするがIdやパスワードがおかしい場合、対話式モードになってスタックするので"-f"処理を入れている
    output=$(curl --max-time ${max_time} -sSfu "${Id}:${Pass}" "${access_url}" 2>&1)

    exit_code=$?
    if [[ "${exit_code}" != 0 ]]; then
        ./err_message.sh "curl" "${func_name}" "${Service}[$Array_Num]: ${output}"
    else
        echo "Access successful ${Service} : domain=${Domain} type=${record} IP=${ip_adr}"
        if [[ "${ip_adr}" = "update!" ]]; then
            ./cache/count.sh "update_cache" "$(date "+%Y-%m-%d %H:%M:%S")  ${Service} : domain=${Domain} type=${record} IP=${ip_adr}"
        else
            ./cache/count.sh "ddns_cache" "$(date "+%Y-%m-%d %H:%M:%S")  ${Service} : domain=${Domain} type=${record} IP=${ip_adr}"
        fi
    fi
}

main() {
    # 実行スクリプト
    case ${Mode} in
    "update")
            ipv_update
            ;;
    "check") 
            ipv_check
            ;;
        * )
            echo "[${Mode}] <- 引数エラーです"
            ;; 
    esac
}

main
