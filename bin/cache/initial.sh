#!/bin/bash
#
# ./cache/initial.sh
#
# キャッシュファイルのチェック処理

cache_check() {
    local cache_dir="../cache"
    local cache_err="${cache_dir}/err_mail"
    local cache_adr="${cache_dir}/ip_cache"

    if [[ -n ${EMAIL_ADR:-} ]]; then
        if [ "$ERR_CHK_TIME" = 0 ]; then
            rm -f "${cache_err}"
        fi
    else
        rm -f "${cache_err}"
    fi

    if [ "$IP_CACHE_TIME" = 0 ]; then
        rm -f "${cache_adr}"
    fi
}

cache_check
