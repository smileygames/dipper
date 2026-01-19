cat >> bin/tests/helpers/common.bash <<'EOF'

# --- ./err_message.sh を差し替える（相対実行対策の本命） ---
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
EOF
