#!/bin/bash
#
# dns_access.sh
#
# multi_accece

Mode=$1
service=$2
Array_Num=$3
My_ipv4=$4
My_ipv6=$5
ipv4_select=$6
ipv6_select=$7
ID=$8
Pass=$9
Domain=$10
IPv4_url=$11
IPv6_url=$12

# IPv4,IPv6を判断して、それぞれのURLでDDNSへアクセス
ipv_update() {
    if [ "$ipv4_select" = on ]; then
        # バックグラウンドプロセスで実行
        access "${FUNCNAME[0]}" "$i" "$ID:$Pass ${IPv4_url}" "4" "update!"
    fi
    if [ "$ipv6_select" = on ]; then
        # バックグラウンドプロセスで実行
        access "${FUNCNAME[0]}" "$i" "$ID:$Pass ${IPv6_url}" "6" "update!"
    fi
}

# アドレスをチェックし変更があった場合のみ、DDNSへアクセス
ipv_check() {
    if [[ $My_ipv4 = "" ]]; then
        ./err_message.sh "no_value" "${FUNCNAME[0]}" "自分のIPv4アドレスを取得できなかった"

    elif [ "$ipv4_select" = on ]; then
        IPv4_old=$(dig "$Domain" "A" +short)  # ドメインのアドレスを読み込む

        if [[ "$My_ipv4" != "$IPv4_old" ]]; then
            # バックグラウンドプロセスで実行
            access "${FUNCNAME[0]}" "$i" "$ID:$Pass ${IPv4_url}" "4" "$My_ipv4"
        fi
    fi

    if [[ $My_ipv6 = "" ]]; then
        ./err_message.sh "no_value" "${FUNCNAME[0]}" "自分のIPv6アドレスを取得できなかった"

    elif [ "$ipv6_select" = on ]; then
        IPv6_old=$(dig "$Domain" "AAAA" +short)  # ドメインのアドレスを読み込む

        if [[ "$My_ipv6" != "$IPv6_old" ]]; then
            # バックグラウンドプロセスで実行
            access "${FUNCNAME[0]}" "$i" "$ID:$Pass ${IPv6_url}" "6" "$My_ipv6"
        fi
    fi
}

access() {
    Func_Name=$1
    Access_URL=$2
    IP_Ver=$3
    IP_Adr=$4

    Max_Time=30

    # DDNSへアクセスするがIDやパスワードがおかしい場合、対話式モードになってスタックするので"-f"処理を入れている
    output=$(curl --max-time ${Max_Time} -sSfu ${Access_URL} 2>&1)
    local exit_code=$?

    if [ "${exit_code}" != 0 ]; then
        # curlコマンドのエラー
        ./err_message.sh "curl" "${Func_Name}" "${service}_ID[$Array_Num]:${service}_PASS[$Array_Num]: ${output}"
    else
        # echo "${output}"
        echo "Access successful ${service} : domain=${Domain} IPv${IP_Ver}=${IP_Adr}"
    fi
}

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