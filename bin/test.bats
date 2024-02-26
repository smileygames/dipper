#!/usr/bin/env bats
# bats test.bats

Test_File="../config/test.conf"

re_test() {
  # Test_Fileのパスと内容を定義
  cat <<EOF > "$Test_File"
#!/bin/bash

IPV4=on
IPV4_DDNS=on
IPV6=on
IPV6_DDNS=on

UPDATE_TIME=3m
DDNS_TIME=1m
IP_CACHE_TIME=0
ERR_CHK_TIME=0

EMAIL_UP_DDNS=off
EMAIL_CHK_DDNS=off
EMAIL_ADR=

MYDNS_ID=()
MYDNS_PASS=()
MYDNS_DOMAIN=()
MYDNS_IPV4=()
MYDNS_IPV6=()

MYDNS_IPV4_URL="https://ipv4.mydns.jp/login.html"
MYDNS_IPV6_URL="https://ipv6.mydns.jp/login.html"

CLOUDFLARE_API=()
CLOUDFLARE_ZONE=()
CLOUDFLARE_DOMAIN=()
CLOUDFLARE_IPV4=()
CLOUDFLARE_IPV6=()

CLOUDFLARE_URL="https://api.cloudflare.com/client/v4/zones"
EOF
}

# IPアドレスををキャッシュファイルに上書きする
up_test() {
  name=$1
  new_set=$2
  # キャッシュファイルが存在する場合、それを更新する
  if [ -f "$Test_File" ]; then
    sed -i "s/^$name=.*$/$name=$new_set/" "$Test_File"
  fi
}

# ---------------- テスト開始 ---------------------

@test "最初にテスト用の設定ファイル作成" {
  run re_test
  [ "$status" -eq 0 ]
}

@test "dipper.sh : 正常に終了される" {
  up_test "IPV4" "off"
  up_test "IPV6" "off"
  run ./dipper.sh
  [ "$status" -eq 0 ]
  re_test
}

@test "dipper.sh : エラー終了される" {
  up_test "UPDATE_TIME" "invalid_time"
  up_test "DDNS_TIME" "invalid_time"
  run ./dipper.sh
  [ "$status" -eq 1 ]
  re_test
}

@test "dipper.sh : IP_CACHE_TIMEの不正な形式をテスト" {
  up_test "IP_CACHE_TIME" "invalid_time"
  run ./dipper.sh
  [ "$status" -eq 1 ]
  re_test
  run ./cache/time_initial.sh
}

@test "dns_select.sh : main関数の値なし終了チェック" {
  run ./dns_select.sh
  [ "$status" -eq 1 ]
}

@test "dns_select.sh : main関数の引数無しチェック" {
  up_test "MYDNS_ID" "(mydnsxxxx1)"
  run ./dns_select.sh
  [ "$output" = "[] <- 引数エラーです" ]
  re_test
}

@test "dns_select.sh : main関数の引数チェック - 不正な引数" {
  up_test "MYDNS_ID" "(mydnsxxxx1)"
  run ./dns_select.sh invalid_argument
  [ "$status" -eq 0 ]
  [ "$output" = "[invalid_argument] <- 引数エラーです" ]
  re_test
}

@test "dns_select.sh : update処理の正常終了チェック" {
  up_test "MYDNS_ID" "(mydnsxxxx1)"
  run ./dns_select.sh update
  [ "$status" -eq 0 ]
  re_test
}

@test "dns_select.sh : check処理の正常終了チェック" {
  up_test "CLOUDFLARE_API" "(User_API_token)"
  run ./dns_select.sh check
  [ "$status" -eq 0 ]
  re_test
}


@test "最後にテスト用の設定ファイル削除" {
  run rm -f $Test_File
  [ "$status" -eq 0 ]
}

