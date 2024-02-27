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

# テスト環境をセットアップするためのヘルパー関数
setup() {
  re_test
}

teardown() {
  run rm -f $Test_File
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

@test "dipper.sh : 正常に終了される" {
  up_test "IPV4" "off"
  up_test "IPV6" "off"
  run ./dipper.sh
  [ "$status" -eq 0 ]
}

@test "dipper.sh : エラー終了される" {
  up_test "UPDATE_TIME" "invalid_time"
  up_test "DDNS_TIME" "invalid_time"
  run ./dipper.sh
  [ "$status" -eq 1 ]
}

@test "dipper.sh : IP_CACHE_TIMEの不正な形式をテスト" {
  up_test "IP_CACHE_TIME" "invalid_time"
  run ./dipper.sh
  [ "$status" -eq 1 ]
}

@test "dns_select.sh : main関数の値なし終了チェック" {
  run ./dns_select.sh
  [ "$status" -eq 1 ]
}

@test "dns_select.sh : main関数の引数無しチェック" {
  up_test "MYDNS_ID" "(mydnsxxxx1)"
  run ./dns_select.sh
  [ "$output" = "[] <- 引数エラーです" ]
}

@test "dns_select.sh : main関数の引数チェック - 不正な引数" {
  up_test "MYDNS_ID" "(mydnsxxxx1)"
  run ./dns_select.sh invalid_argument
  [ "$status" -eq 0 ]
  [ "$output" = "[invalid_argument] <- 引数エラーです" ]
}

@test "dns_select.sh : update処理の正常終了チェック" {
  up_test "MYDNS_ID" "(mydnsxxxx1)"
  run ./dns_select.sh update
  [ "$status" -eq 0 ]
}

@test "dns_select.sh : check処理の正常終了チェック" {
  up_test "CLOUDFLARE_API" "(User_API_token)"
  run ./dns_select.sh check
  [ "$status" -eq 0 ]
}

@test "time_check.sh : 引数 => update  180 -> 180" {
  run ./time_check.sh update 180
  [ "$status" -eq 0 ]
  [ "$output" = "180" ]
}

@test "time_check.sh : 引数 => update  179 -> 3m" {
  run ./time_check.sh update 179
  [ "$status" -eq 0 ]
  [ "$output" = "3m" ]
}

@test "time_check.sh : 引数 => update  0 -> 3m" {
  run ./time_check.sh update 0
  [ "$status" -eq 0 ]
  [ "$output" = "3m" ]
}

@test "time_check.sh : 引数 => check  60 -> 60" {
  run ./time_check.sh check 60
  [ "$status" -eq 0 ]
  [ "$output" = "60" ]
}

@test "time_check.sh : 引数 => check  59 -> 1m" {
  run ./time_check.sh check 59
  [ "$status" -eq 0 ]
  [ "$output" = "1m" ]
}

@test "time_check.sh : 引数 => check  0 -> 1m" {
  run ./time_check.sh check 0
  [ "$status" -eq 0 ]
  [ "$output" = "1m" ]
}

@test "time_check.sh : 引数 => error  1m -> 1m" {
  run ./time_check.sh error 1m
  [ "$status" -eq 0 ]
  [ "$output" = "1m" ]
}

@test "time_check.sh : 引数 => error  59s -> 1m" {
  run ./time_check.sh error 59s
  [ "$status" -eq 0 ]
  [ "$output" = "1m" ]
}

@test "time_check.sh : 引数 => error  0 -> 0" {
  run ./time_check.sh error 0
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "time_check.sh : 引数 => ip_time  15m -> 15m" {
  run ./time_check.sh ip_time 1m
  [ "$status" -eq 0 ]
  [ "$output" = "15m" ]
}

@test "time_check.sh : 引数 => ip_time  899 -> 15m" {
  run ./time_check.sh ip_time 59
  [ "$status" -eq 0 ]
  [ "$output" = "15m" ]
}

@test "time_check.sh : 引数 => ip_time  0 -> 0" {
  run ./time_check.sh ip_time 0
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "time_check.sh : 引数 => sec_time  0 -> 0" {
  run ./time_check.sh sec_time 0
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "time_check.sh : 引数 => sec_time  12s -> 12" {
  run ./time_check.sh sec_time 12s
  [ "$status" -eq 0 ]
  [ "$output" = "12" ]
}

@test "time_check.sh : 引数 => sec_time  3m -> 180" {
  run ./time_check.sh sec_time 3m
  [ "$status" -eq 0 ]
  [ "$output" = "180" ]
}

@test "time_check.sh : 引数 => sec_time  4h -> 14400" {
  run ./time_check.sh sec_time 4h
  [ "$status" -eq 0 ]
  [ "$output" = "14400" ]
}

@test "time_check.sh : 引数 => sec_time  5d -> 432000" {
  run ./time_check.sh sec_time 5d
  [ "$status" -eq 0 ]
  [ "$output" = "432000" ]
}

@test "time_check.sh : 想定外処理 引数 => sec_time  5k -> 5k" {
  run ./time_check.sh sec_time 5k
  [ "$status" -eq 0 ]
  [ "$output" = "5k" ]
}
