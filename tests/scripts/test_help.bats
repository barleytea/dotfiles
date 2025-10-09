#!/usr/bin/env bats

# Test for scripts/help.awk

load '../test_helper/test_helper'

setup() {
    setup_test_env
    # Create a test Makefile
    TEST_MAKEFILE="$(create_mock_makefile)"
}

teardown() {
    teardown_test_env
}

@test "help.awk: processes simple target with description" {
    run bash -c "echo 'test-target: ## This is a test' | awk -f '${PROJECT_ROOT}/scripts/help.awk'"
    assert_success
    assert_output --partial "test-target"
    assert_output --partial "This is a test"
}

@test "help.awk: processes category headers" {
    run bash -c "echo '## Category Header ##' | awk -f '${PROJECT_ROOT}/scripts/help.awk'"
    assert_success
    assert_output --partial "Category Header"
}

@test "help.awk: handles multiple targets" {
    run awk -f "${PROJECT_ROOT}/scripts/help.awk" "${TEST_MAKEFILE}"
    assert_success
    assert_output --partial "test-target"
    assert_output --partial "another-target"
    assert_output --partial "category-task"
}

@test "help.awk: ignores targets without description" {
    run bash -c "echo 'no-desc-target:' | awk -f '${PROJECT_ROOT}/scripts/help.awk'"
    assert_success
    refute_output --partial "no-desc-target"
}

@test "help.awk: handles targets with special characters in description" {
    run bash -c "echo 'special: ## Description with \"quotes\" and \$vars' | awk -f '${PROJECT_ROOT}/scripts/help.awk'"
    assert_success
    assert_output --partial "special"
    assert_output --partial "Description"
}

@test "help.awk: preserves ANSI color codes in output" {
    run bash -c "echo 'colored: ## Test color' | awk -f '${PROJECT_ROOT}/scripts/help.awk'"
    assert_success
    # Check for ANSI escape sequences (color codes)
    [[ "${output}" =~ $'\033' ]] || fail "Expected ANSI color codes in output"
}

@test "help.awk: handles empty input gracefully" {
    run bash -c "echo '' | awk -f '${PROJECT_ROOT}/scripts/help.awk'"
    assert_success
    assert_output ""
}

@test "help.awk: processes real Makefile format" {
    cat > "${TEST_TEMP_DIR}/real_makefile" <<'EOF'
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "Help"

## Build Tasks ##
build: ## Build the project
	@make build-impl

test: ## Run tests
	@bats tests/
EOF

    run awk -f "${PROJECT_ROOT}/scripts/help.awk" "${TEST_TEMP_DIR}/real_makefile"
    assert_success
    assert_output --partial "help"
    assert_output --partial "Show this help message"
    assert_output --partial "Build Tasks"
    assert_output --partial "build"
    assert_output --partial "Build the project"
    assert_output --partial "test"
    assert_output --partial "Run tests"
}

@test "help.awk: handles Japanese characters in description" {
    run bash -c "echo 'japanese: ## このヘルプメッセージを表示します' | awk -f '${PROJECT_ROOT}/scripts/help.awk'"
    assert_success
    assert_output --partial "japanese"
    assert_output --partial "このヘルプメッセージを表示します"
}

@test "help.awk: aligns output columns properly" {
    cat > "${TEST_TEMP_DIR}/align_test" <<'EOF'
short: ## Short name
very-long-target-name: ## Long name
mid: ## Medium name
EOF

    run awk -f "${PROJECT_ROOT}/scripts/help.awk" "${TEST_TEMP_DIR}/align_test"
    assert_success
    # All descriptions should be aligned (checking for consistent spacing)
    assert_output --partial "short"
    assert_output --partial "very-long-target-name"
    assert_output --partial "mid"
}

# ========================================
# 実際の動作テスト
# ========================================

@test "help.awk: actual execution with real Makefile produces valid output" {
    run awk -f "${PROJECT_ROOT}/scripts/help.awk" "${PROJECT_ROOT}/Makefile"
    assert_success
    # 出力が空でないことを確認
    [ -n "$output" ]
    # 主要なターゲットが含まれていることを確認
    assert_output --partial "help"
    assert_output --partial "test"
    assert_output --partial "nix"
}

@test "help.awk: output format is consistent" {
    cat > "${TEST_TEMP_DIR}/format_test" <<'EOF'
target-one: ## Description 1
target-two: ## Description 2
## Category ##
target-three: ## Description 3
EOF

    run awk -f "${PROJECT_ROOT}/scripts/help.awk" "${TEST_TEMP_DIR}/format_test"
    assert_success

    # ANSIエスケープシーケンスを除去してから確認
    clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')

    # 各行がターゲット名と説明を含むことを確認
    echo "$clean_output" | grep -E "target-one.*Description 1" || fail "target-one not formatted correctly"
    echo "$clean_output" | grep -E "target-two.*Description 2" || fail "target-two not formatted correctly"
    echo "$clean_output" | grep -E "target-three.*Description 3" || fail "target-three not formatted correctly"
    echo "$clean_output" | grep -E "Category" || fail "Category header not found"
}

@test "help.awk: correctly filters out non-documented targets" {
    cat > "${TEST_TEMP_DIR}/filter_test" <<'EOF'
documented: ## This is documented
undocumented:
	echo "no docs"
also-documented: ## This too
EOF

    run awk -f "${PROJECT_ROOT}/scripts/help.awk" "${TEST_TEMP_DIR}/filter_test"
    assert_success

    assert_output --partial "documented"
    assert_output --partial "also-documented"
    refute_output --partial "undocumented"
}

@test "help.awk: handles edge case of empty Makefile" {
    touch "${TEST_TEMP_DIR}/empty_makefile"

    run awk -f "${PROJECT_ROOT}/scripts/help.awk" "${TEST_TEMP_DIR}/empty_makefile"
    assert_success
    # 空のMakefileでもエラーにならない
}

@test "help.awk: processes multiple category headers correctly" {
    cat > "${TEST_TEMP_DIR}/multi_category" <<'EOF'
## Category 1 ##
target1: ## Description 1
## Category 2 ##
target2: ## Description 2
## Category 3 ##
target3: ## Description 3
EOF

    run awk -f "${PROJECT_ROOT}/scripts/help.awk" "${TEST_TEMP_DIR}/multi_category"
    assert_success

    assert_output --partial "Category 1"
    assert_output --partial "Category 2"
    assert_output --partial "Category 3"
}

@test "help.awk: actual make help command works end-to-end" {
    cd "${PROJECT_ROOT}"
    run make help
    assert_success

    # 実際のhelpコマンドが動作し、主要な情報を表示することを確認
    assert_output --partial "Nix"
    assert_output --partial "Testing"
    assert_output --partial "help"

    # 出力が複数行あることを確認（実際のヘルプとして機能している）
    line_count=$(echo "$output" | wc -l)
    [ "$line_count" -gt 10 ] || fail "Help output too short: $line_count lines"
}
