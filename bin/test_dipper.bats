#!/usr/bin/env bats

# テスト環境をセットアップするためのヘルパー関数
setup() {
  # 必要な設定ファイルやディレクトリを作成
  touch ../config/user.conf
  mkdir -p ../cache
  touch ../cache/update_cache
  touch ../cache/ddns_cache
  touch ../cache/err_mail
}

teardown() {
  # テスト後のクリーンアップ
  rm -f ../config/user.conf
  rm -rf ../cache
}

ini() {
  cat <<EOF > ../config/user.conf
IPV4=off
IPV6=off
MYDNS_ID[1]="mydnsxxxx1"
EOF
}

# cache_time_set関数のテスト
@test "cache_time_set with valid format 1d" {
  ini
  echo "UPDATE_TIME=1d" >> ../config/user.conf
  run ./dipper.sh
  [ "$status" -eq 0 ]
}

@test "cache_time_set with valid format 24h" {
  ini
  echo "UPDATE_TIME=24h" >> ../config/user.conf
  run ./dipper.sh
  [ "$status" -eq 0 ]
}

@test "cache_time_set with invalid format 2ch" {
  ini
  echo "UPDATE_TIME=2ch" >> ../config/user.conf
  run ./dipper.sh
  [ "$status" -ne 0 ]
}

# dns_service_check関数のテスト
@test "dns_service_check with no DNS services" {
  echo "IPV4=off" > ../config/user.conf
  echo "IPV6=off" >> ../config/user.conf
  run ./dipper.sh
  [ "$status" -ne 0 ]
}

# timer_select関数のテスト
@test "timer_select with IPV4 and IPV6 off" {
  ini
  run ./dipper.sh
  [ "$status" -eq 0 ]
}
# & main関数のテスト
@test "timer_select with IPV4 on and valid cache" {
  ini
  echo "IPV4=on" >> ../config/user.conf
  run timeout 3s ./dipper.sh
  [ "$status" -eq 124 ]
}
