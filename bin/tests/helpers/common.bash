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
