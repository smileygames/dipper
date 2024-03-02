#!/bin/bash
#
# ./ip_check.sh
#
# 動的アドレスモードの場合、チェック用にIPvバージョン情報とレコード情報も追加

Cache_Dir="../cache"
Cache_File="${Cache_Dir}/ip_cache"

ip_cache_read() {
    local ip_date=$1

    # キャッシュファイルからipアドレスを読み込んで出力
    ip_cache_date=$(grep "$ip_date:" "$Cache_File" | awk '{print $2}')
    echo "$ip_cache_date"
}

cache_reset() {
    # 現在のエポック秒を取得
    current_time=$(date +%s)

    echo "time: $current_time" > "$Cache_File"
    echo "ipv4:" >> "$Cache_File"
    echo "ipv6:" >> "$Cache_File"
}

cache_time_check() {
    local set_time_sec old_time now_time diff_time

    if [[ "$IP_CACHE_TIME" != 0 ]] && [ -f "$Cache_File" ]; then
        set_time_sec=$(./time_check.sh "sec_time" "$IP_CACHE_TIME")

        # キャッシュファイルのtimeを読み込む
        old_time=$(ip_cache_read "time")
        # 現在のエポック秒を取得
        now_time=$(date +%s)
        diff_time=$((now_time - old_time))

        # 経過時間が設定された時間より大きい場合、キャッシュを初期化
        if ((diff_time > set_time_sec)); then
            cache_reset
        fi
    fi
}

ip_cache_check() {
    local new_ipv4=$1
    local new_ipv6=$2
    local flag_ip=0 old_ipv4="" old_ipv6=""

    if [ -f "$Cache_File" ]; then
        old_ipv4=$(ip_cache_read "ipv4")  # キャッシュのipv4アドレスを読み込む
        old_ipv6=$(ip_cache_read "ipv6")  # キャッシュのipv6アドレスを読み込む
    fi

    if [[ "$new_ipv4" != "$old_ipv4" ]] || [[ "$new_ipv6" != "$old_ipv6" ]]; then
        flag_ip=1
    fi

    if (( "$flag_ip" )); then
        ./cache/ip_update.sh "$new_ipv4" "$new_ipv6"
        echo "${new_ipv4} ${new_ipv6}"
    fi
}

myip_check() {
    local my_ipv4="" my_ipv6=""
    local exit_code

    if [ "$IPV4" = on ] && [ "$IPV4_DDNS" = on ]; then
        my_ipv4=$(dig -4 @one.one.one.one whoami.cloudflare TXT CH +short)  # 自分のアドレスを読み込む
        exit_code=$?
        if [[ "${exit_code}" != 0 ]]; then
            ./err_message.sh "no_value" "${FUNCNAME[0]}" "自分のIPv4アドレスを取得できなかった"
            my_ipv4=""
        fi
    fi
    if [ "$IPV6" = on ] && [ "$IPV6_DDNS" = on ]; then
        my_ipv6=$(dig -6 @one.one.one.one whoami.cloudflare TXT CH +short)  # 自分のアドレスを読み込む
#        my_ipv6=$(ip -o a show scope global up | grep -oP '(?<=inet6 ).+(?=/64 )')  # DNSに負担をかけない方法
        exit_code=$?
        if [[ "${exit_code}" != 0 ]]; then
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

main() {
    local ip_adr="" ipv4_adr="" ipv6_adr=""

    cache_time_check
    ip_adr=$(myip_check)
    # 出力を空白で分割し、変数に割り当てる
    read -r ipv4_adr <<< "${ip_adr%% *}"  # 最初の空白までを IPv4 アドレスとして読み込む
    read -r ipv6_adr <<< "${ip_adr#* }"   # 最初の空白以降を IPv6 アドレスとして読み込む
    echo "${ipv4_adr} ${ipv6_adr}" 
}

main
