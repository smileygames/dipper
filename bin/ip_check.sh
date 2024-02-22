#!/bin/bash
#
# ./ip_check.sh
#
# 動的アドレスモードの場合、チェック用にIPvバージョン情報とレコード情報も追加

ip_cache_check() {
    local new_ipv4=$1
    local new_ipv6=$2
    local flag_ip=0 ipv4_old="" ipv6_old=""

    ipv4_old=$(ip_cache_read "ipv4")  # キャッシュのアドレスを読み込む

    if [[ "$new_ipv4" != "$ipv4_old" ]]; then
        flag_ip=1
    fi

    ipv6_old=$(ip_cache_read "ipv6")  # キャッシュのアドレスを読み込む

    if [[ "$new_ipv6" != "$ipv6_old" ]]; then
        flag_ip=1
    fi

    if (( "$flag_ip" )); then
        echo "${my_ipv4} ${my_ipv6}"
        ./cache_ip_update.sh "$my_ipv4" "$my_ipv6"
    fi
}

ip_cache_read() {
    local ip_ver=$1
    local cache_dir="../cache"
    local cache_ip="${cache_dir}/ip_cache"
    
    # キャッシュファイルが存在するか確認
    if [ -f "$cache_ip" ]; then
        # キャッシュファイルからipアドレスを読み込む
        ip_adr=$(grep "$ip_ver:" "$cache_ip" | awk '{print $2}')

        # 読み取ったIPアドレスを出力
        echo "$ip_adr"
    fi
}

main() {
    local my_ipv4="" my_ipv6=""
    local exit_code

    if [ "$IPV4" = on ] && [ "$IPV4_DDNS" = on ]; then
        my_ipv4=$(dig -4 @resolver1.opendns.com myip.opendns.com A +short)  # 自分のアドレスを読み込む
        exit_code=$?
        if [ "${exit_code}" != 0 ]; then
            ./err_message.sh "no_value" "${FUNCNAME[0]}" "自分のIPv4アドレスを取得できなかった"
            my_ipv4=""
        fi
    fi
    if [ "$IPV6" = on ] && [ "$IPV6_DDNS" = on ]; then
        my_ipv6=$(dig -6 @resolver1.opendns.com myip.opendns.com AAAA +short)  # 自分のアドレスを読み込む
#        my_ipv6=$(ip -o a show scope global up | grep -oP '(?<=inet6 ).+(?=/64 )')  # DNSに負担をかけない方法
        exit_code=$?
        if [ "${exit_code}" != 0 ]; then
            ./err_message.sh "no_value" "${FUNCNAME[0]}" "自分のIPv6アドレスを取得できなかった"
            my_ipv6=""
        fi
    fi

    if [[ $my_ipv4 != "" ]] || [[ $my_ipv6 != "" ]]; then
        if [ "$IP_CACHE_TIME" != 0 ]; then
            ip_cache_check "$my_ipv4" "$my_ipv6"
        else
            echo "${my_ipv4} ${my_ipv6}"
        fi
    fi
}

main