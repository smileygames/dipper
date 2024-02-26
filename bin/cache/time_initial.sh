#!/bin/bash
#
# ./cache/time_initial.sh
#
# キャッシュファイルのチェック処理

cache_check() {
    local cache_dir="../cache"
    local cache_update="${cache_dir}/update_cache"
    local cache_ddns="${cache_dir}/ddns_cache"
    local cache_err="${cache_dir}/err_mail"
    local cache_adr="${cache_dir}/ip_cache"

    if [[ -n ${EMAIL_ADR:-} ]]; then
        if [ "$EMAIL_UP_DDNS" != on ]; then
            rm -f "${cache_update}"
        fi
        if [ "$EMAIL_CHK_DDNS" != on ]; then
            rm -f "${cache_ddns}"
        fi
        if [ "$ERR_CHK_TIME" = 0 ]; then
            rm -f "${cache_err}"
        fi
    else
        rm -f "${cache_ddns}" "${cache_err}"
    fi

    if [ "$IP_CACHE_TIME" = 0 ]; then
        rm -f "${cache_adr}"
    fi

     # キャッシュディレクトリ内が空の場合、ディレクトリを削除
    if [ -d "${cache_dir}" ] && [ -z "$(ls -A ${cache_dir})" ]; then
        rm -r "${cache_dir}"
    fi
}

cache_check
