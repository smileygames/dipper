#!/usr/bin/env bats

# -------------------------------------------------
# 共通セットアップ
# -------------------------------------------------
setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

  # err_message.sh をスタブ化
  STUB_DIR="$(mktemp -d)"
  mkdir -p "$STUB_DIR/bin"

  cat > "$STUB_DIR/bin/err_message.sh" <<'EOF'
#!/bin/sh
# stub: do nothing
exit 0
EOF
  chmod +x "$STUB_DIR/bin/err_message.sh"

  # 実ファイルを退避して差し替え
  if [ -f "$REPO_ROOT/bin/err_message.sh" ]; then
    cp -f "$REPO_ROOT/bin/err_message.sh" "$STUB_DIR/bin/err_message.sh.orig"
  fi
  cp -f "$STUB_DIR/bin/err_message.sh" "$REPO_ROOT/bin/err_message.sh"
}

teardown() {
  # err_message.sh を元に戻す
  if [ -f "$STUB_DIR/bin/err_message.sh.orig" ]; then
    cp -f "$STUB_DIR/bin/err_message.sh.orig" "$REPO_ROOT/bin/err_message.sh"
  fi
  rm -rf "$STUB_DIR"
}

# -------------------------------------------------
# ヘルパー（bin 実行前提を再現）
# -------------------------------------------------
run_time_sec() {
  run bash -c "cd '$REPO_ROOT/bin'; source './time_check.sh'; time_sec '$1'"
}

run_sec_time_cnv() {
  run bash -c "cd '$REPO_ROOT/bin'; source './time_check.sh'; Time='$1'; sec_time_cnv; echo \"\$Time\""
}

# -------------------------------------------------
# time_sec
# -------------------------------------------------
@test "time_sec: 10s -> 10" {
  run_time_sec "10s"
  [ "$status" -eq 0 ]
  [ "$output" = "10" ]
}

@test "time_sec: 2m -> 120" {
  run_time_sec "2m"
  [ "$output" = "120" ]
}

@test "time_sec: 3h -> 10800" {
  run_time_sec "3h"
  [ "$output" = "10800" ]
}

@test "time_sec: 1d -> 86400" {
  run_time_sec "1d"
  [ "$output" = "86400" ]
}

@test "time_sec: numeric string passes through (42 -> 42)" {
  run_time_sec "42"
  [ "$output" = "42" ]
}

@test "time_sec: unknown unit passes through (1x -> 1x)" {
  run_time_sec "1x"
  [ "$output" = "1x" ]
}

@test "time_sec: empty -> empty" {
  run_time_sec ""
  [ "$output" = "" ]
}

# -------------------------------------------------
# sec_time_cnv
# -------------------------------------------------
@test "sec_time_cnv: Time=1m becomes 60" {
  run_sec_time_cnv "1m"
  [ "$output" = "60" ]
}

# -------------------------------------------------
# time_check_update (min 180 sec => 3m)
# -------------------------------------------------
@test "time_check_update: 179s -> Time becomes 3m" {
  run bash -c "cd '$REPO_ROOT/bin'; source './time_check.sh'; Time='179s'; time_check_update; echo \"\$Time\""
  [ "$output" = "3m" ]
}

@test "time_check_update: 180s stays (180s)" {
  run bash -c "cd '$REPO_ROOT/bin'; source './time_check.sh'; Time='180s'; time_check_update; echo \"\$Time\""
  [ "$output" = "180s" ]
}

@test "time_check_update: 3m stays (3m)" {
  run bash -c "cd '$REPO_ROOT/bin'; source './time_check.sh'; Time='3m'; time_check_update; echo \"\$Time\""
  [ "$output" = "3m" ]
}

# -------------------------------------------------
# time_check_ddns (min 60 sec => 1m)
# -------------------------------------------------
@test "time_check_ddns: 59s -> Time becomes 1m" {
  run bash -c "cd '$REPO_ROOT/bin'; source './time_check.sh'; Time='59s'; time_check_ddns; echo \"\$Time\""
  [ "$output" = "1m" ]
}

@test "time_check_ddns: 60s stays (60s)" {
  run bash -c "cd '$REPO_ROOT/bin'; source './time_check.sh'; Time='60s'; time_check_ddns; echo \"\$Time\""
  [ "$output" = "60s" ]
}

# -------------------------------------------------
# time_check_error (min 60 sec => 1m, but 0 allowed)
# -------------------------------------------------
@test "time_check_error: 59s -> Time becomes 1m" {
  run bash -c "cd '$REPO_ROOT/bin'; source './time_check.sh'; Time='59s'; time_check_error; echo \"\$Time\""
  [ "$output" = "1m" ]
}

@test "time_check_error: 0 stays (0)" {
  run bash -c "cd '$REPO_ROOT/bin'; source './time_check.sh'; Time='0'; time_check_error; echo \"\$Time\""
  [ "$output" = "0" ]
}

@test "time_check_error: 60s stays (60s)" {
  run bash -c "cd '$REPO_ROOT/bin'; source './time_check.sh'; Time='60s'; time_check_error; echo \"\$Time\""
  [ "$output" = "60s" ]
}

# -------------------------------------------------
# time_check_ip (min 900 sec => 15m, but 0 allowed)
# -------------------------------------------------
@test "time_check_ip: 899s -> Time becomes 15m" {
  run bash -c "cd '$REPO_ROOT/bin'; source './time_check.sh'; Time='899s'; time_check_ip; echo \"\$Time\""
  [ "$output" = "15m" ]
}

@test "time_check_ip: 900s stays (900s)" {
  run bash -c "cd '$REPO_ROOT/bin'; source './time_check.sh'; Time='900s'; time_check_ip; echo \"\$Time\""
  [ "$output" = "900s" ]
}

@test "time_check_ip: 0 stays (0)" {
  run bash -c "cd '$REPO_ROOT/bin'; source './time_check.sh'; Time='0'; time_check_ip; echo \"\$Time\""
  [ "$output" = "0" ]
}
