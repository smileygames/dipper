#!/bin/bash
#
# ./ddns_service.sh
#
# DDNSタイマー起動処理

# 引数を変数に代入
Mode=$1
# 配列の要素数を変数に代入（DDNSのサービスごと）
Mydns=${#MYDNS_ID[@]}
CloudFlare=${#CLOUDFLARE_API[@]}


# IPv4とIPv6でアクセスする
multi_update() {
     # MyDNSのDDNSのための処理
    if (( "$Mydns" )); then
        # shellcheck disable=SC1091
        . ./dns_service/mydns.sh "update"
    fi
}

# 定期更新したらメール通知チェック
ip_update() {
    multi_update

    if [[ -n ${EMAIL_ADR:-} ]] && [[ -n ${EMAIL_UP_DDNS:-} ]]; then
        ./mail/sending.sh "update_cache" "IPアドレスを更新しました <$(hostname)>" "$EMAIL_ADR"
    fi
}

# 複数のDDNSサービス用（拡張するときは処理を増やす）
multi_ddns() {
    local my_ipv4=$1
    local my_ipv6=$2

    # MyDNSのDDNSのための処理
    if (( "$Mydns" )); then
        # shellcheck disable=SC1091
        . ./dns_service/mydns.sh "check" "$my_ipv4" "$my_ipv6"
    fi
    # CloudFlareのDDNSのための処理
    if (( "$CloudFlare" )); then
        # shellcheck disable=SC1091
        . ./dns_service/cloudflare.sh "check" "$my_ipv4" "$my_ipv6"
    fi
}

ip_adr_read() {
    local ip_adr

    ip_adr=$(./ip_check.sh)
    # 出力を空白で分割し、変数に割り当てる
    read -r ipv4 <<< "${ip_adr%% *}"  # 最初の空白までを IPv4 アドレスとして読み込む
    read -r ipv6 <<< "${ip_adr#* }"   # 最初の空白以降を IPv6 アドレスとして読み込む

    multi_ddns "$ipv4" "$ipv6"

    if [[ -n ${EMAIL_ADR:-} ]] && [[ -n ${EMAIL_CHK_DDNS:-} ]]; then
        ./mail/sending.sh "ddns_cache" "IPアドレスの変更がありました <$(hostname)>" "$EMAIL_ADR"
    fi
}

main() {
    # タイマー処理
    case ${Mode} in
    "update")  # アドレス定期通知（一般的なDDNSだと定期的に通知されない場合データが破棄されてしまう）
            if (( "$Mydns" )); then
                # IP更新用の処理を設定値に基づいて実行する
                ip_update
            else
                exit 0
            fi
            ;;
    "check")   # アドレス変更時のみ通知する
            if (( "$Mydns" || "$CloudFlare" )); then
                # IPチェック用の処理を設定値に基づいて実行する
                ip_adr_read
            else
                exit 1
            fi
            ;;
        * )
            echo "[${Mode}] <- 引数エラーです"
            ;; 
    esac
}

# 実行スクリプト
main
