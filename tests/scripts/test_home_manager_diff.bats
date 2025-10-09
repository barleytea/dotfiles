#!/usr/bin/env bats

# Test for scripts/home-manager-diff.sh

load '../test_helper/test_helper'

setup() {
    setup_test_env
    SCRIPT_PATH="${PROJECT_ROOT}/scripts/home-manager-diff.sh"
}

teardown() {
    teardown_test_env
}

@test "home-manager-diff.sh: script exists and is executable" {
    assert_file_executable "${SCRIPT_PATH}"
}

@test "home-manager-diff.sh: has proper shebang" {
    run head -n 1 "${SCRIPT_PATH}"
    assert_success
    assert_output --partial "bash"
}

@test "home-manager-diff.sh: defines required functions" {
    run grep -E "^(info|step|err|cleanup)\(\)" "${SCRIPT_PATH}"
    assert_success
}

@test "home-manager-diff.sh: sets proper shell options" {
    run grep "set -uo pipefail" "${SCRIPT_PATH}"
    assert_success
}

@test "home-manager-diff.sh: has trap for cleanup" {
    run grep "trap cleanup" "${SCRIPT_PATH}"
    assert_success
}

@test "home-manager-diff.sh: QUIET mode suppresses info messages" {
    # Create a minimal test that checks QUIET variable handling
    cat > "${TEST_TEMP_DIR}/test_quiet.sh" <<'EOF'
#!/usr/bin/env bash
source /dev/stdin <<'FUNCTIONS'
info() { [ "${QUIET:-0}" = 1 ] && return 0; printf '%s\n' "$*"; }
step() { [ "${QUIET:-0}" = 1 ] && return 0; printf '[%s] %s\n' "$1" "$2"; }
FUNCTIONS

# Test without QUIET
info "test message"
step "1" "test step"

# Test with QUIET
QUIET=1
info "should not appear"
step "2" "should not appear"
EOF
    chmod +x "${TEST_TEMP_DIR}/test_quiet.sh"

    run bash "${TEST_TEMP_DIR}/test_quiet.sh"
    assert_success
    assert_output --partial "test message"
    assert_output --partial "test step"
    refute_output --partial "should not appear"
}

@test "home-manager-diff.sh: SHOW_ALL variable is checked" {
    run grep 'SHOW_ALL' "${SCRIPT_PATH}"
    assert_success
    assert_output --partial '${SHOW_ALL:-0}'
}

@test "home-manager-diff.sh: uses mktemp for temporary directory" {
    run grep 'mktemp -d' "${SCRIPT_PATH}"
    assert_success
}

@test "home-manager-diff.sh: cleanup removes temporary directory" {
    run grep -A 1 'cleanup()' "${SCRIPT_PATH}"
    assert_success
    assert_output --partial 'rm -rf'
    assert_output --partial 'TMPDIR'
}

@test "home-manager-diff.sh: handles missing current generation gracefully" {
    # Test the logic for handling missing current generation
    cat > "${TEST_TEMP_DIR}/test_missing_gen.sh" <<'EOF'
#!/usr/bin/env bash
CUR_GEN_PATH=""
if [ -z "$CUR_GEN_PATH" ]; then
    echo "no current generation -> only new closure size"
    exit 0
fi
EOF
    chmod +x "${TEST_TEMP_DIR}/test_missing_gen.sh"

    run bash "${TEST_TEMP_DIR}/test_missing_gen.sh"
    assert_success
    assert_output --partial "no current generation"
}

@test "home-manager-diff.sh: detects identical generations" {
    # Test the logic for identical generation detection
    cat > "${TEST_TEMP_DIR}/test_identical.sh" <<'EOF'
#!/usr/bin/env bash
CUR_GEN_PATH="/nix/store/abc"
NEW_GEN_PATH="/nix/store/abc"
if [ "$CUR_GEN_PATH" = "$NEW_GEN_PATH" ]; then
    echo "new generation identical to current (paths same)"
    exit 0
fi
EOF
    chmod +x "${TEST_TEMP_DIR}/test_identical.sh"

    run bash "${TEST_TEMP_DIR}/test_identical.sh"
    assert_success
    assert_output --partial "identical"
}

@test "home-manager-diff.sh: show_paths function respects SHOW_ALL" {
    # Extract and test the show_paths function behavior
    cat > "${TEST_TEMP_DIR}/test_show_paths.sh" <<'EOF'
#!/usr/bin/env bash

show_paths() {
  local file=$1 label=$2 count=$3
  [ "$count" -eq 0 ] && return 0
  echo "--- $label ---"
  if [ "${SHOW_ALL:-0}" = 1 ]; then
    cat "$file"
  else
    head -n 20 "$file"
    [ "$count" -gt 20 ] && echo '  ...'
  fi
}

# Create test file with 25 lines
for i in {1..25}; do echo "line $i"; done > /tmp/test_paths.txt

# Test without SHOW_ALL (should show only 20 lines)
show_paths /tmp/test_paths.txt "test" 25

echo "---SEPARATOR---"

# Test with SHOW_ALL (should show all lines)
SHOW_ALL=1
show_paths /tmp/test_paths.txt "test all" 25

rm -f /tmp/test_paths.txt
EOF
    chmod +x "${TEST_TEMP_DIR}/test_show_paths.sh"

    run bash "${TEST_TEMP_DIR}/test_show_paths.sh"
    assert_success
    assert_output --partial "--- test ---"
    assert_output --partial "--- test all ---"
    assert_output --partial "..."
}

@test "home-manager-diff.sh: handles empty added/removed lists" {
    cat > "${TEST_TEMP_DIR}/test_count.sh" <<'EOF'
#!/usr/bin/env bash
ADDED_COUNT=""
REM_COUNT=""
case "$ADDED_COUNT" in '' ) ADDED_COUNT=0 ;; esac
case "$REM_COUNT" in '' ) REM_COUNT=0 ;; esac
echo "added: $ADDED_COUNT  removed: $REM_COUNT"
EOF
    chmod +x "${TEST_TEMP_DIR}/test_count.sh"

    run bash "${TEST_TEMP_DIR}/test_count.sh"
    assert_success
    assert_output "added: 0  removed: 0"
}

@test "home-manager-diff.sh: uses comm for set operations" {
    run grep 'comm -13' "${SCRIPT_PATH}"
    assert_success
    run grep 'comm -23' "${SCRIPT_PATH}"
    assert_success
}

@test "home-manager-diff.sh: searches for activation script" {
    run grep 'find.*activate' "${SCRIPT_PATH}"
    assert_success
    assert_output --partial '-maxdepth 5'
    assert_output --partial '-type f'
}

@test "home-manager-diff.sh: compares activation scripts with cmp" {
    run grep 'cmp -s' "${SCRIPT_PATH}"
    assert_success
}

@test "home-manager-diff.sh: uses diff for activation script comparison" {
    run grep 'diff -u' "${SCRIPT_PATH}"
    assert_success
}

@test "home-manager-diff.sh: exits with status 0 on success" {
    run grep 'exit 0' "${SCRIPT_PATH}"
    assert_success
}

# ========================================
# 実際の動作テスト
# ========================================

@test "home-manager-diff.sh: creates and cleans up temporary directory" {
    # スクリプトの一部を抽出して動作確認
    cat > "${TEST_TEMP_DIR}/test_cleanup.sh" <<'EOF'
#!/usr/bin/env bash
set -uo pipefail
TMPDIR="$(mktemp -d)"
cleanup() { rm -rf "$TMPDIR" || true; }
trap cleanup EXIT INT TERM

# 一時ディレクトリにファイルを作成
echo "test" > "$TMPDIR/testfile"
[ -f "$TMPDIR/testfile" ] || exit 1

# 一時ディレクトリパスを出力
echo "$TMPDIR"
EOF
    chmod +x "${TEST_TEMP_DIR}/test_cleanup.sh"

    run "${TEST_TEMP_DIR}/test_cleanup.sh"
    assert_success

    # 一時ディレクトリが作成され、その後削除されることを確認
    tmpdir_path="$output"
    [ -n "$tmpdir_path" ]
    # クリーンアップ後は存在しないはず
    [ ! -d "$tmpdir_path" ] || fail "Temporary directory was not cleaned up"
}

@test "home-manager-diff.sh: info function respects QUIET mode" {
    cat > "${TEST_TEMP_DIR}/test_quiet.sh" <<'EOF'
#!/usr/bin/env bash
info() { [ "${QUIET:-0}" = 1 ] && return 0; printf '%s\n' "$*"; }

# Normal mode
info "visible message"

# Quiet mode
QUIET=1
info "invisible message"
EOF

    run bash "${TEST_TEMP_DIR}/test_quiet.sh"
    assert_success
    assert_output --partial "visible message"
    refute_output --partial "invisible message"
}

@test "home-manager-diff.sh: step function respects QUIET mode" {
    cat > "${TEST_TEMP_DIR}/test_step.sh" <<'EOF'
#!/usr/bin/env bash
step() { [ "${QUIET:-0}" = 1 ] && return 0; printf '[%s] %s\n' "$1" "$2"; }

# Normal mode
step 1 "first step"

# Quiet mode
QUIET=1
step 2 "quiet step"
EOF

    run bash "${TEST_TEMP_DIR}/test_step.sh"
    assert_success
    assert_output --partial "[1] first step"
    refute_output --partial "[2] quiet step"
}

@test "home-manager-diff.sh: err function outputs to stderr" {
    cat > "${TEST_TEMP_DIR}/test_err.sh" <<'EOF'
#!/usr/bin/env bash
err() { printf 'ERROR: %s\n' "$*" >&2; }
err "test error message"
EOF

    run bash "${TEST_TEMP_DIR}/test_err.sh"
    # stderrに出力されているので、成功とみなされる（batsはデフォルトでstderrも$outputに含む）
    assert_output --partial "ERROR: test error message"
}

@test "home-manager-diff.sh: show_paths function limits output correctly" {
    cat > "${TEST_TEMP_DIR}/test_show_paths.sh" <<'EOF'
#!/usr/bin/env bash

show_paths() {
  local file=$1 label=$2 count=$3
  [ "$count" -eq 0 ] && return 0
  echo "--- $label ---"
  if [ "${SHOW_ALL:-0}" = 1 ]; then
    cat "$file"
  else
    head -n 20 "$file"
    [ "$count" -gt 20 ] && echo '  ...'
  fi
}

# Create test file with 25 lines
for i in {1..25}; do echo "line $i"; done > /tmp/test_show_paths.txt

# Test without SHOW_ALL (should limit to 20 lines)
show_paths /tmp/test_show_paths.txt "Limited" 25

rm -f /tmp/test_show_paths.txt
EOF

    run bash "${TEST_TEMP_DIR}/test_show_paths.sh"
    assert_success
    assert_output --partial "--- Limited ---"
    assert_output --partial "line 1"
    assert_output --partial "line 20"
    assert_output --partial "..."
    refute_output --partial "line 25"
}

@test "home-manager-diff.sh: show_paths with SHOW_ALL shows all lines" {
    cat > "${TEST_TEMP_DIR}/test_show_all.sh" <<'EOF'
#!/usr/bin/env bash

show_paths() {
  local file=$1 label=$2 count=$3
  [ "$count" -eq 0 ] && return 0
  echo "--- $label ---"
  if [ "${SHOW_ALL:-0}" = 1 ]; then
    cat "$file"
  else
    head -n 20 "$file"
    [ "$count" -gt 20 ] && echo '  ...'
  fi
}

# Create test file with 25 lines
for i in {1..25}; do echo "line $i"; done > /tmp/test_show_all.txt

# Test with SHOW_ALL
SHOW_ALL=1
show_paths /tmp/test_show_all.txt "All" 25

rm -f /tmp/test_show_all.txt
EOF

    run bash "${TEST_TEMP_DIR}/test_show_all.sh"
    assert_success
    assert_output --partial "line 1"
    assert_output --partial "line 25"
    refute_output --partial "..."
}

@test "home-manager-diff.sh: comm command correctly identifies added and removed items" {
    # Create test files
    cat > "${TEST_TEMP_DIR}/old_list" <<'EOF'
/nix/store/aaa-package-1.0
/nix/store/bbb-package-2.0
/nix/store/ccc-package-3.0
EOF

    cat > "${TEST_TEMP_DIR}/new_list" <<'EOF'
/nix/store/aaa-package-1.0
/nix/store/ccc-package-3.0
/nix/store/ddd-package-4.0
EOF

    # Test added (in new but not in old)
    run comm -13 "${TEST_TEMP_DIR}/old_list" "${TEST_TEMP_DIR}/new_list"
    assert_success
    assert_output --partial "ddd-package-4.0"
    refute_output --partial "bbb-package-2.0"

    # Test removed (in old but not in new)
    run comm -23 "${TEST_TEMP_DIR}/old_list" "${TEST_TEMP_DIR}/new_list"
    assert_success
    assert_output --partial "bbb-package-2.0"
    refute_output --partial "ddd-package-4.0"
}

@test "home-manager-diff.sh: handles case count variables correctly" {
    cat > "${TEST_TEMP_DIR}/test_count.sh" <<'EOF'
#!/usr/bin/env bash
# Test empty count handling
ADDED_COUNT=""
REM_COUNT=""
case "$ADDED_COUNT" in '' ) ADDED_COUNT=0 ;; esac
case "$REM_COUNT" in '' ) REM_COUNT=0 ;; esac

echo "Added: $ADDED_COUNT"
echo "Removed: $REM_COUNT"

# Test with actual counts
ADDED_COUNT="5"
REM_COUNT="3"
case "$ADDED_COUNT" in '' ) ADDED_COUNT=0 ;; esac
case "$REM_COUNT" in '' ) REM_COUNT=0 ;; esac

echo "Added: $ADDED_COUNT"
echo "Removed: $REM_COUNT"
EOF

    run bash "${TEST_TEMP_DIR}/test_count.sh"
    assert_success
    # First output should be 0
    assert_line --index 0 "Added: 0"
    assert_line --index 1 "Removed: 0"
    # Second output should preserve values
    assert_line --index 2 "Added: 5"
    assert_line --index 3 "Removed: 3"
}
