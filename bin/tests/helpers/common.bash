#!/usr/bin/env bash
# bin/tests/helpers/common.bash
#
# bats テスト共通ヘルパー
# - REPO_ROOT を決定
# - 一時ディレクトリ（STUB_DIR）を用意
# - cd bin + source 前提の実行を支援
# - ./xxx.sh 相対実行に備えて、実ファイル差し替え型のスタブを提供

setup_common() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  STUB_DIR="$(mktemp -d)"
}

teardown_common() {
  rm -rf "$STUB_DIR"
}

# -------------------------------------------------
# bin 実行前提を再現して source + コマンド実行
# -------------------------------------------------
run_in_bin_source() {
  local script="$1"
  local cmd="$2"
  run bash -c "cd '$REPO_ROOT/bin'; source '$script'; $cmd"
}

# -------------------------------------------------
# ./err_message.sh を差し替える（相対実行対策）
# -------------------------------------------------
stub_replace_err_message() {
  mkdir -p "$STUB_DIR/bin"

  cat > "$STUB_DIR/bin/err_message.sh" <<'EOS'
#!/bin/sh
# stub: do nothing
exit 0
EOS
  chmod +x "$STUB_DIR/bin/err_message.sh"

  if [ -f "$REPO_ROOT/bin/err_message.sh" ]; then
    cp -f "$REPO_ROOT/bin/err_message.sh" "$STUB_DIR/bin/err_message.sh.orig"
  fi
  cp -f "$STUB_DIR/bin/err_message.sh" "$REPO_ROOT/bin/err_message.sh"
}

restore_err_message_if_needed() {
  if [ -f "$STUB_DIR/bin/err_message.sh.orig" ]; then
    cp -f "$STUB_DIR/bin/err_message.sh.orig" "$REPO_ROOT/bin/err_message.sh"
  fi
}

# -------------------------------------------------
# 任意の実ファイルをスタブに差し替える（相対実行 ./xxx.sh 対応）
# usage: stub_replace_file "bin/mail/sending.sh" '<stub script body>'
# -------------------------------------------------
stub_replace_file() {
  local rel_path="$1"
  local body="$2"

  local target="$REPO_ROOT/$rel_path"
  local bak="$STUB_DIR/$(echo "$rel_path" | tr '/' '_').orig"

  mkdir -p "$(dirname "$target")"

  if [ -f "$target" ]; then
    cp -f "$target" "$bak"
  fi

  cat > "$target" <<EOS
#!/bin/sh
$body
EOS
  chmod +x "$target"
}

# stub_replace_file で差し替えたファイルを戻す
# usage: stub_restore_file "bin/mail/sending.sh"
stub_restore_file() {
  local rel_path="$1"
  local target="$REPO_ROOT/$rel_path"
  local bak="$STUB_DIR/$(echo "$rel_path" | tr '/' '_').orig"

  if [ -f "$bak" ]; then
    cp -f "$bak" "$target"
  fi
}

setup_minidipper_for_ip_check() {
  export PROJ_DIR="$BATS_TEST_TMPDIR/proj"
  export BIN_DIR="$PROJ_DIR/bin"
  export CALLS_DIR="$PROJ_DIR/calls"
  mkdir -p "$BIN_DIR" "$BIN_DIR/cache" "$BIN_DIR/tests/stubs" "$PROJ_DIR/cache" "$CALLS_DIR"

  # 必要スクリプトを“ミニdipper”へコピー（REPO_ROOT基準）
  cp -p "$REPO_ROOT/bin/ip_check.sh" "$BIN_DIR/"
  cp -p "$REPO_ROOT/bin/time_check.sh" "$BIN_DIR/"
  cp -p "$REPO_ROOT/bin/err_message.sh" "$BIN_DIR/"
  cp -p "$REPO_ROOT/bin/cache/ip_update.sh" "$BIN_DIR/cache/"

  # err_message.sh が呼ぶ count.sh をスタブ化（loggerの代替ログもここで吸う）
  cat > "$BIN_DIR/cache/count.sh" <<'EOF'
#!/bin/bash
mode=$1
msg=$2
calls_dir="${CALLS_DIR:-/tmp}"
echo "${mode}|${msg}" >> "${calls_dir}/count.log"
EOF
  chmod +x "$BIN_DIR/cache/count.sh"

  # dig スタブ（中身は各テストで差し替える）
  cat > "$BIN_DIR/tests/stubs/dig" <<'EOF'
#!/bin/bash
echo "UNCONFIGURED"
exit 2
EOF
  chmod +x "$BIN_DIR/tests/stubs/dig"

  # logger スタブ（syslogに出さない）
  cat > "$BIN_DIR/tests/stubs/logger" <<'EOF'
#!/bin/bash
calls_dir="${CALLS_DIR:-/tmp}"
echo "logger $*" >> "${calls_dir}/logger.log"
exit 0
EOF
  chmod +x "$BIN_DIR/tests/stubs/logger"

  # date スタブ（固定エポック秒だけ差し替え。その他は /bin/date にフォールバック）
  cat > "$BIN_DIR/tests/stubs/date" <<'EOF'
#!/bin/bash
if [[ "$1" == "+%s" && -n "${STUB_DATE_EPOCH:-}" ]]; then
  echo "${STUB_DATE_EPOCH}"
  exit 0
fi

# スタブ自身に再帰しないよう、絶対パスで実dateを呼ぶ
if [ -x /bin/date ]; then
  /bin/date "$@"
else
  /usr/bin/date "$@"
fi
EOF
  chmod +x "$BIN_DIR/tests/stubs/date"

  # PATH 先頭に stubs を追加
  export PATH="$BIN_DIR/tests/stubs:$PATH"

  cd "$BIN_DIR" || exit 1
}

stub_dig_ipv4() {
  local ipv4=$1
  cat > "tests/stubs/dig" <<EOF
#!/bin/bash
echo "\$@" >> "${CALLS_DIR}/dig.log"
# IPv4クエリ想定：whoami.cloudflare が返すTXTを模倣（sedで " を外すので無しでも可）
echo "${ipv4}"
exit 0
EOF
  chmod +x "tests/stubs/dig"
}

stub_dig_fail() {
  cat > "tests/stubs/dig" <<'EOF'
#!/bin/bash
echo "$@" >> "${CALLS_DIR}/dig.log"
exit 1
EOF
  chmod +x "tests/stubs/dig"
}

stub_date_epoch() {
  export STUB_DATE_EPOCH="$1"
}

assert_file_exists() {
  [ -f "$1" ]
}

assert_line_count_is() {
  local file=$1
  local expected=$2
  local actual
  actual=$(wc -l < "$file" | tr -d ' ')
  [ "$actual" -eq "$expected" ]
}

assert_file_contains_line() {
  local file=$1
  local line=$2
  grep -Fx -- "$line" "$file" >/dev/null
}

assert_file_contains_regex() {
  local file=$1
  local pattern=$2
  grep -E -- "$pattern" "$file" >/dev/null
}
