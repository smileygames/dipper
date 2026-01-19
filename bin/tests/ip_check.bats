#!/usr/bin/env bats
# shellcheck shell=bash
# shellcheck disable=SC2030,SC2031

load 'helpers/common.bash'

setup() {
  setup_common
  setup_minidipper_for_ip_check
}

teardown() {
  teardown_common
}

@test "IP_CACHE_TIME=0: IPv4取得できたら出力するが ip_cache は作られない（現状挙動）" {
  export IPV4=on IPV4_DDNS=on IPV6=off IPV6_DDNS=on
  export IP_CACHE_TIME=0

  stub_dig_ipv4 "111.237.107.114"

  run ./ip_check.sh
  [ "$status" -eq 0 ]
  [ "$output" = "111.237.107.114 " ]

  [ ! -f ../cache/ip_cache ]

  assert_file_exists "$CALLS_DIR/dig.log"
  assert_line_count_is "$CALLS_DIR/dig.log" 1
}

@test "IP_CACHE_TIME=1h: 初回は ip_update が走り ip_cache が作成・更新される" {
  export IPV4=on IPV4_DDNS=on IPV6=off IPV6_DDNS=on
  export IP_CACHE_TIME=1h

  stub_dig_ipv4 "111.237.107.114"
  stub_date_epoch 1768802162

  run ./ip_check.sh
  [ "$status" -eq 0 ]
  [ "$output" = "111.237.107.114 " ]

  assert_file_exists ../cache/ip_cache
  assert_file_contains_line "../cache/ip_cache" "time: 1768802162"
  assert_file_contains_line "../cache/ip_cache" "ipv4: 111.237.107.114"
  assert_file_contains_line "../cache/ip_cache" "ipv6: "
}

@test "IP_CACHE_TIME=1h: cache内IPと同一なら ip_cache_check は無出力 → main は空白だけ出す（現状挙動）" {
  export IPV4=on IPV4_DDNS=on IPV6=off IPV6_DDNS=on
  export IP_CACHE_TIME=1h

  # 期限切れ判定を避けるため、now と cache time を近づける
  stub_date_epoch 1768817430

  mkdir -p ../cache
  cat > ../cache/ip_cache <<'EOF'
time: 1768817000
ipv4: 111.237.107.114
ipv6:
EOF

  stub_dig_ipv4 "111.237.107.114"

  run ./ip_check.sh
  [ "$status" -eq 0 ]

  # 「IP文字が出ていない」を固定（空白1個 or 空でもOKにする）
  [[ -z "${output//[[:space:]]/}" ]]

  # dig は 1回だけ呼ばれる（cache_resetが走らない前提）
  assert_file_exists "$CALLS_DIR/dig.log"
  assert_line_count_is "$CALLS_DIR/dig.log" 1
}

@test "IP_CACHE_TIME=15m: cache期限切れで cache_reset（dig失敗は黙殺）" {
  export IPV4=on IPV4_DDNS=on IPV6=off IPV6_DDNS=on
  export IP_CACHE_TIME=15m

  mkdir -p ../cache
  cat > ../cache/ip_cache <<'EOF'
time: 0
ipv4: 1.2.3.4
ipv6:
EOF

  stub_date_epoch 1000
  stub_dig_fail

  run ./ip_check.sh
  [ "$status" -eq 0 ]
  [[ -z "${output//[[:space:]]/}" ]]

  # cache_reset の結果
  assert_file_contains_line "../cache/ip_cache" "time: 1000"
  assert_file_contains_line "../cache/ip_cache" "ipv4:"
  assert_file_contains_line "../cache/ip_cache" "ipv6:"

  # dig は呼ばれる（ただし失敗は検知されないのが現状）
  assert_file_exists "$CALLS_DIR/dig.log"
  assert_line_count_is "$CALLS_DIR/dig.log" 1
}
