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
    if [ "$My_ipv4" = on ] && [ "$IPv4_Select" = on ]; then
        # バックグラウンドプロセスで実行
        access "${FUNCNAME[0]}" "$Id:$Pass ${IPv4_url}" "4" "update!"
    fi

    if [ "$My_ipv6" = on ] && [ "$IPv6_Select" = on ]; then
        # バックグラウンドプロセスで実行
        access "${FUNCNAME[0]}" "$Id:$Pass ${IPv6_url}" "6" "update!"
    fi
}

# アドレスをチェックし変更があった場合のみ、DDNSへアクセス
ipv_check() {
    local ipv4_old="" ipv6_old=""

    if [[ $My_ipv4 != "" ]] && [ "$IPv4_Select" = on ]; then
        ipv4_old=$(dig "$Domain" "A" +short)  # ドメインのアドレスを読み込む

        if [[ "$My_ipv4" != "$ipv4_old" ]]; then
            # バックグラウンドプロセスで実行
            access "${FUNCNAME[0]}" "$Id:$Pass ${IPv4_url}" "4" "$My_ipv4"
        fi
    fi

    if [[ $My_ipv6 != "" ]] && [ "$IPv6_Select" = on ]; then
        ipv6_old=$(dig "$Domain" "AAAA" +short)  # ドメインのアドレスを読み込む

        if [[ "$My_ipv6" != "$ipv6_old" ]]; then
            # バックグラウンドプロセスで実行
            access "${FUNCNAME[0]}" "$Id:$Pass ${IPv6_url}" "6" "$My_ipv6"
        fi
    fi
}

access() {
    local func_name=$1
    local access_url=$2
    local ip_ver=$3
    local ip_adr=$4

    local output exit_code
    local max_time=30

    # DDNSへアクセスするがIdやパスワードがおかしい場合、対話式モードになってスタックするので"-f"処理を入れている
    # またシェルチェックで${access_url}を""で囲めとエラーが出るが"${access_url}"だとcurlがURLを取得できないので無視する
    # shellcheck disable=SC2086
    output=$(curl --max-time ${max_time} -sSfu ${access_url} 2>&1)
    exit_code=$?

    if [ "${exit_code}" != 0 ]; then
        # curlコマンドのエラー
        ./err_message.sh "curl" "${func_name}" "${Service}_ID[$Array_Num]:${Service}_PASS[$Array_Num]: ${output}"
    else
        # echo "${output}"
        echo "Access successful ${Service} : domain=${Domain} IPv${ip_ver}=${ip_adr}"
        if [[ "${ip_adr}" != "update!" ]]; then
            ./cache_count.sh "ddns_mail" "${Service} : domain=${Domain} IPv${ip_ver}=${ip_adr} :time=$(date +%T)"
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
