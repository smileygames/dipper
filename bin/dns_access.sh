#!/bin/bash
#
# ./dns_access.sh
#
# shellcheck disable=SC2086

Mode=$1
Func_Name=$2
Array_Num=$3
Access_URL=$4

Max_Time=30

access() {
    # DDNSへアクセスするがIDやパスワードがおかしい場合、対話式モードになってスタックするので"-f"処理を入れている
    output=$(curl --max-time ${Max_Time} -sSfu ${Access_URL} 2>&1)
    exit_code=$?

    if [ "${exit_code}" != 0 ]; then
        # curlコマンドのエラー
        ./err_message.sh "curl" "${Func_Name}" "${Mode}_ID[$Array_Num]:${Mode}_PASS[$Array_Num]: ${output}"
    else
        echo "Access successful ${output}: ${Func_Name}: curl ${Mode}_ID[$Array_Num]:${Mode}_PASS[$Array_Num]"
    fi
}

# 実行スクリプト
access
