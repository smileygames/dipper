#!/usr/bin/env bats
# shellcheck shell=bash
# shellcheck disable=SC2030,SC2031
# cache_initial.bats
#
# 対象: bin/cache/initial.sh の cache_check()
# 方針: 今の挙動をスナップショットする（善悪は判定しない）
# 前提: cache_check はスクリプト末尾で即実行されるため、「実行=読み込み」になる

load "helpers/common.bash"

setup() {
  setup_common
  stub_replace_err_message

  stub_replace_file "bin/mail/sending.sh" '
echo "sending.sh $*" >> "'"$STUB_DIR"'/sending_calls.log"
exit 0
'
  : > "$STUB_DIR/sending_calls.log"

  mkdir -p "$REPO_ROOT/cache"
  echo "dummy" > "$REPO_ROOT/cache/err_mail"
  echo "dummy" > "$REPO_ROOT/cache/ip_cache"
}

teardown() {
  stub_restore_file "bin/mail/sending.sh"
  restore_err_message_if_needed
  teardown_common
}

run_cache_initial() {
  run bash -c "cd '$REPO_ROOT/bin'; source './cache/initial.sh'"
}

@test "cache_check: no EMAIL_ADR removes err_mail and does not call sending" {
  unset EMAIL_ADR
  export ERR_CHK_TIME=999
  export IP_CACHE_TIME=999

  run_cache_initial
  [ "$status" -eq 0 ]

  [ ! -f "$REPO_ROOT/cache/err_mail" ]
  [ -f "$REPO_ROOT/cache/ip_cache" ]
  [ ! -s "$STUB_DIR/sending_calls.log" ]
}

@test "cache_check: EMAIL_ADR + ERR_CHK_TIME=0 removes err_mail and does not call sending" {
  export EMAIL_ADR="a@example.com"
  export ERR_CHK_TIME=0
  export IP_CACHE_TIME=999

  echo "dummy" > "$REPO_ROOT/cache/err_mail"

  run_cache_initial
  [ "$status" -eq 0 ]

  [ ! -f "$REPO_ROOT/cache/err_mail" ]
  [ -f "$REPO_ROOT/cache/ip_cache" ]
  [ ! -s "$STUB_DIR/sending_calls.log" ]
}

@test "cache_check: IP_CACHE_TIME=0 removes ip_cache" {
  export EMAIL_ADR="a@example.com"
  export ERR_CHK_TIME=0
  export IP_CACHE_TIME=0

  echo "dummy" > "$REPO_ROOT/cache/ip_cache"

  run_cache_initial
  [ "$status" -eq 0 ]

  [ ! -f "$REPO_ROOT/cache/ip_cache" ]
}

@test "cache_check: EMAIL_ADR + ERR_CHK_TIME!=0 calls sending and keeps err_mail" {
  export EMAIL_ADR="a@example.com"
  export ERR_CHK_TIME=60
  export IP_CACHE_TIME=999

  echo "dummy" > "$REPO_ROOT/cache/err_mail"

  run_cache_initial
  [ "$status" -eq 0 ]

  [ -f "$REPO_ROOT/cache/err_mail" ]
  [ -s "$STUB_DIR/sending_calls.log" ]
}
