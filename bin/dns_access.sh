#!/bin/bash
#
# ./dns_access.sh
#
# shellcheck disable=SC2086

Mode=$1
Func_Name=$2
Array_Num=$3
Access_URL=$4

Out_Time=25s
Max_Time=21

access() {
    # DDNSへアクセスするがIDやパスワードがおかしい場合、対話式モードになってスタックするのでタイムアウト処理を入れている
    output=$(timeout ${Out_Time} curl --max-time ${Max_Time} -sSu ${Access_URL} 2>&1)
    exit_code=$?

    if [ "${exit_code}" != 0 ]; then
        # タイムアウトエラー
        ./err_message.sh "timeout" "${Func_Name}" "${Out_Time}: ログイン情報 curl -u ${Mode}_ID[$Array_Num]:${Mode}_PASS[$Array_Num]  URL"
    elif [[ "${output}" == *'<p>'* ]]; then
        # curlコマンドのエラーメッセージの抽出（<title>内のテキスト）
        error_title=$(echo "${output}" | grep -o '<title>[^<]*</title>' | sed 's/<[^>]*>//g')
        # curlコマンドのエラーメッセージの抽出（<p>内のテキスト）
        error_message=$(echo "${output}" | grep -o '<p>[^<]*</p>' | sed 's/<[^>]*>//g')
        # curlコマンドのエラー
        ./err_message.sh "curl" "${Func_Name}" "${Mode}_ID[$Array_Num]:${Mode}_PASS[$Array_Num]: ${error_title}: ${error_message}"
    else
        echo "Access successful"
    fi
}

# 実行スクリプト
access
