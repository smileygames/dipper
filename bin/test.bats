#!/usr/bin/env bats
# batsu test.bats

Test_File="../config/test.conf"

re_test() {
  # Test_Fileのパスと内容を定義
  cat <<EOF > "$Test_File"
#!/bin/bash
#
# DDNS User Config file

## 初期設定
#-----------------------------------------------
# IPV4 アドレス default = on
# IPV4_DDNS 固定IPアドレスの場合はoffにする。但し、IPv4=offの場合は無効になる default = on
IPV4=on
IPV4_DDNS=on

# IPV6 アドレス default = off
# IPV6_DDNS 動的IPアドレスの場合はonにする。但し、IPv6=offの場合は無効になる default = on
IPV6=on
IPV6_DDNS=on

#   s:	秒(seconds)
#   m:	分(minutes)
#   h:	時間(hours)
#   d:	日(days)
# UPDATE_TIME=1d (default) 
# アドレスを定期的に通知する間隔　最低3分までとする。それ以下にした場合、強制的に3分となる。
UPDATE_TIME=1d

# DDNS_TIME=3m (default)
# アドレスが変更されてないか定期的にチェックする間隔　最低1分までとする。それ以下にした場合、強制的に1分となる。
DDNS_TIME=3m

# IP_CACHE_TIME=0 (defaultは無効) 推奨=1h
# アドレスキャッシュをリフレッシュする間隔　最低15分までとする。それ以下にした場合、強制的に15分となる。
# 上記 DDNS_TIME より少なくするとあまり意味がない
IP_CACHE_TIME=15m
#-----------------------------------------------

## Emailに通知するための設定
#-----------------------------------------------
# DDNSで変更があった場合に通知する
EMAIL_CHK_DDNS=off
EMAIL_ADR=""

#   s:	秒(seconds)
#   m:	分(minutes)
#   h:	時間(hours)
#   d:	日(days)
# エラーメッセージをEmailで通知する用。上記EMAIL_ADRが有効の場合に通知する。
# ERR_CHK_TIME=0 (defaultは無効) 推奨=1h 最低値は1分、それ以下にした場合、強制的に1分となる。
ERR_CHK_TIME=1m
#-----------------------------------------------

## MyDNS
#-----------------------------------------------
# マルチドメインの場合、例のように Num= の数字をそろえて変更して登録してください
# 例はコメントアウトされているので、先頭の # を外してID等を変更して使用してください
# それぞれのユーザーに対して、IPv4/IPv6を選択可能、但し、上記のIPvの設定によっては無効になる場合もあり

Num=1  # Number 1個目のドメイン
MYDNS_ID[1]=
MYDNS_PASS[1]=
MYDNS_DOMAIN[1]=
MYDNS_IPV4[1]=
MYDNS_IPV6[1]=

#Num=2  # Number 2個目のドメイン
#MYDNS_ID[2]="mydnsxxxxx2"
#MYDNS_PASS[2]="Password2"
#MYDNS_DOMAIN[2]="example2.com"
#MYDNS_IPV4[2]=on
#MYDNS_IPV6[2]=off

# MyDNS Login URL
MYDNS_IPV4_URL="https://ipv4.mydns.jp/login.html"
MYDNS_IPV6_URL="https://ipv6.mydns.jp/login.html"
#-----------------------------------------------

## CloudFlare Domains
#-----------------------------------------------
# CloudFlare_IPV6[ ] default = off [on/off]
# CloudFlareのDDNSはIPv4とIPv6に対応
# IPV6及びIPV6_DDNSの設定のどちらか一方がoffの場合、CloudFlare_IPV6は無効になるので注意です。

Num=1  # Number 1個目のドメイン
CLOUDFLARE_API[1]=
CLOUDFLARE_ZONE[1]=
CLOUDFLARE_DOMAIN[1]=
CLOUDFLARE_IPV4[1]=
CLOUDFLARE_IPV6[1]=

#Num=2  # Number 2個目のドメイン
#CLOUDFLARE_API[2]="User_API_token"
#CLOUDFLARE_ZONE[2]="example2.com"
#CLOUDFLARE_DOMAIN[2]="example2.com"
#CLOUDFLARE_IPV4[2]=on
#CLOUDFLARE_IPV6[2]=off

# CloudFlare Login URL
CLOUDFLARE_URL="https://api.cloudflare.com/client/v4/zones"
#-----------------------------------------------
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
  run  ./dipper.sh
  [ "$status" -eq 1 ]
  re_test
}

@test "dns_select.sh : main関数の引数無しチェック" {
run ./dns_select.sh
[ "$status" -eq 0 ]
[ "$output" = "[] <- 引数エラーです" ]
}

@test "dns_select.sh : main関数の引数チェック - 不正な引数" {
run ./dns_select.sh invalid_argument
[ "$status" -eq 0 ]
[ "$output" = "[invalid_argument] <- 引数エラーです" ]
}

# UPDATE_TIMEの不正な形式をテスト
@test "dns_select.sh : update処理の正常終了チェック" {
  up_test "MYDNS_ID[1]" "mydnsxxxx1"
  run ./dns_select.sh update
  [ "$status" -eq 0 ]
  re_test
}

# DDNS_TIMEの不正な形式をテスト
@test "dns_select.sh : check処理の正常終了チェック" {
  up_test "CLOUDFLARE_API[1]" "User_API_token"
  run ./dns_select.sh check
  [ "$status" -eq 0 ]
  re_test
}


@test "最後にテスト用の設定ファイル削除" {
run rm -f $Test_File
[ "$status" -eq 0 ]
}

