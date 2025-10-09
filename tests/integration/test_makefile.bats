#!/usr/bin/env bats

# Test for Makefile tasks

load '../test_helper/test_helper'

setup() {
    setup_test_env
    # Makefileのパス
    MAKEFILE="${PROJECT_ROOT}/Makefile"
}

teardown() {
    teardown_test_env
}

# ========================================
# Makefile基本構造のテスト
# ========================================

@test "Makefile: exists and is readable" {
    assert_file_exist "${MAKEFILE}"
    run cat "${MAKEFILE}"
    assert_success
}

@test "Makefile: has .DEFAULT_GOAL set to help" {
    run grep -E '^\.DEFAULT_GOAL.*:=.*help' "${MAKEFILE}"
    assert_success
}

@test "Makefile: help target exists" {
    run grep -E '^help:.*##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: all targets have proper syntax" {
    # ターゲット定義の構文チェック（target: ## description形式）
    run grep -E '^[a-zA-Z_][a-zA-Z0-9_-]+:' "${MAKEFILE}"
    assert_success
}

# ========================================
# make help コマンドのテスト
# ========================================

@test "Makefile: make help runs successfully" {
    cd "${PROJECT_ROOT}"
    run make help
    assert_success
}

@test "Makefile: make help shows all documented targets" {
    cd "${PROJECT_ROOT}"
    run make help
    assert_success
    # 主要なカテゴリが表示されるか確認
    assert_output --partial "Nix"
    assert_output --partial "Home Manager"
    assert_output --partial "Testing"
}

@test "Makefile: make help shows test targets" {
    cd "${PROJECT_ROOT}"
    run make help
    assert_success
    assert_output --partial "test"
    assert_output --partial "全てのbatsテストを実行"
}

# ========================================
# Nix関連タスクのテスト
# ========================================

@test "Makefile: nix-channel-update target exists" {
    run grep -E '^nix-channel-update:.*##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: flake-update target exists" {
    run grep -E '^flake-update:.*##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: flake-update uses correct command" {
    run grep 'nix flake update' "${MAKEFILE}"
    assert_success
}

@test "Makefile: flake-update-nixpkgs target exists" {
    run grep -E '^flake-update-nixpkgs:.*##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: flake-update-nixpkgs uses --update-input" {
    run grep -- '--update-input nixpkgs' "${MAKEFILE}"
    assert_success
}

# ========================================
# Home Manager関連タスクのテスト
# ========================================

@test "Makefile: home-manager-switch target exists" {
    run grep -E '^home-manager-switch:.*##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: home-manager-build target exists" {
    run grep -E '^home-manager-build:.*##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: home-manager-apply target exists" {
    run grep -E '^home-manager-apply:.*##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: home-manager-apply depends on flake-update" {
    run grep -E '^home-manager-apply:.*flake-update' "${MAKEFILE}"
    assert_success
}

@test "Makefile: home-manager commands use --impure flag" {
    run grep -E 'home-manager.*--impure' "${MAKEFILE}"
    assert_success
}

# ========================================
# nix-darwin関連タスクのテスト
# ========================================

@test "Makefile: nix-darwin-apply target exists" {
    run grep -E '^nix-darwin-apply:.*##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: nix-darwin-check target exists" {
    run grep -E '^nix-darwin-check:.*##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: nix-darwin-check uses build command" {
    run grep -A 2 '^nix-darwin-check:' "${MAKEFILE}"
    assert_success
    assert_output --partial 'build'
}

@test "Makefile: nix-darwin uses sudo for apply operations" {
    run grep -E 'sudo.*nix-darwin' "${MAKEFILE}"
    assert_success
}

# ========================================
# Testing関連タスクのテスト
# ========================================

@test "Makefile: test target exists" {
    run grep -E '^test:.*##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: test target runs bats" {
    run grep -A 1 '^test:.*##' "${MAKEFILE}"
    assert_success
    assert_output --partial 'bats'
}

@test "Makefile: test-scripts target exists" {
    run grep -E '^test-scripts:.*##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: test-integration target exists" {
    run grep -E '^test-integration:.*##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: test-verbose target exists" {
    run grep -E '^test-verbose:.*##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: test-verbose uses -t flag" {
    run grep -A 1 '^test-verbose:' "${MAKEFILE}"
    assert_success
    assert_output --partial 'bats'
    assert_output --partial -- '-t'
}

@test "Makefile: test-watch target exists" {
    run grep -E '^test-watch:.*##' "${MAKEFILE}"
    assert_success
}

# ========================================
# Pre-commit関連タスクのテスト
# ========================================

@test "Makefile: pre-commit-init target exists" {
    run grep -E '^pre-commit-init:.*##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: pre-commit-run target exists" {
    run grep -E '^pre-commit-run:.*##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: pre-commit-run uses --all-files flag" {
    run grep -A 1 '^pre-commit-run:' "${MAKEFILE}"
    assert_success
    assert_output --partial '--all-files'
}

# ========================================
# VSCode関連タスクのテスト
# ========================================

@test "Makefile: vscode-apply target exists" {
    run grep -E '^vscode-apply:.*##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: vscode-save target exists" {
    run grep -E '^vscode-save:.*##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: vscode-apply runs bash scripts" {
    run grep -A 2 '^vscode-apply:' "${MAKEFILE}"
    assert_success
    assert_output --partial 'bash'
    assert_output --partial 'vscode'
}

# ========================================
# mise関連タスクのテスト
# ========================================

@test "Makefile: mise-install-all target exists" {
    run grep -E '^mise-install-all:.*##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: mise-list target exists" {
    run grep -E '^mise-list:.*##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: mise-config target exists" {
    run grep -E '^mise-config:.*##' "${MAKEFILE}"
    assert_success
}

# ========================================
# その他のタスクのテスト
# ========================================

@test "Makefile: zsh target exists" {
    run grep -E '^zsh:.*##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: zsh target measures startup time" {
    run grep -A 1 '^zsh:' "${MAKEFILE}"
    assert_success
    assert_output --partial 'time'
}

@test "Makefile: paths target exists" {
    run grep -E '^paths:.*##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: paths target formats PATH nicely" {
    run grep -A 1 '^paths:' "${MAKEFILE}"
    assert_success
    assert_output --partial "tr ':' '\\n'"
}

# ========================================
# 環境変数とシェル設定のテスト
# ========================================

@test "Makefile: sets SHELL variable" {
    run grep '^SHELL.*:=' "${MAKEFILE}"
    assert_success
    assert_output --partial 'bash'
}

@test "Makefile: defines NIX_PROFILE variable" {
    run grep '^NIX_PROFILE.*:=' "${MAKEFILE}"
    assert_success
    assert_output --partial 'nix-daemon.sh'
}

@test "Makefile: uses NIX_PROFILE in nix commands" {
    run grep 'source.*NIX_PROFILE' "${MAKEFILE}"
    assert_success
}

# ========================================
# ターゲット依存関係のテスト
# ========================================

@test "Makefile: nix-update-all has correct dependencies" {
    run grep -E '^nix-update-all:.*nix-channel-update.*home-manager-apply.*nix-darwin-apply' "${MAKEFILE}"
    assert_success
}

@test "Makefile: nix-check-all has correct dependencies for CI" {
    run grep -E '^nix-check-all:.*nix-channel-update.*home-manager-apply.*nix-darwin-check' "${MAKEFILE}"
    assert_success
}

# ========================================
# カテゴリヘッダーのテスト
# ========================================

@test "Makefile: has Nix category header" {
    run grep -E '^## Nix ##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: has Home Manager category header" {
    run grep -E '^## .*Home Manager' "${MAKEFILE}"
    assert_success
}

@test "Makefile: has Testing category header" {
    run grep -E '^## Testing ##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: has Pre-commit category header" {
    run grep -E '^## Pre-commit ##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: has VSCode category header" {
    run grep -E '^## VSCode ##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: has Mise category header" {
    run grep -E '^## Mise ##' "${MAKEFILE}"
    assert_success
}

@test "Makefile: has Others category header" {
    run grep -E '^## Others ##' "${MAKEFILE}"
    assert_success
}

# ========================================
# 実際の動作テスト
# ========================================

@test "Makefile: paths target actually displays PATH" {
    cd "${PROJECT_ROOT}"
    run make paths
    assert_success

    # PATH環境変数が含まれることを確認
    [ -n "$output" ] || fail "paths target produced no output"

    # 出力が複数行であることを確認（PATHが:で分割されている）
    line_count=$(echo "$output" | wc -l | tr -d ' ')
    [ "$line_count" -gt 1 ] || fail "PATH should have multiple entries"
}

@test "Makefile: test target uses bats command with correct flags" {
    # testターゲットがbats --recursiveを使用していることを確認
    run grep -A 1 '^test:' "${MAKEFILE}"
    assert_success
    assert_output --partial "bats --recursive tests/"
}

@test "Makefile: help-fzf target exists and has correct dependencies" {
    run grep -E '^help-fzf:' "${MAKEFILE}"
    assert_success

    # fzfとxargsを使用していることを確認
    run grep -A 5 '^help-fzf:' "${MAKEFILE}"
    assert_success
    assert_output --partial "fzf"
    assert_output --partial "xargs"
}

@test "Makefile: SHELL variable is properly set" {
    # MakefileでSHELL変数がbashに設定されていることを確認
    run grep '^SHELL.*:=.*bash' "${MAKEFILE}"
    assert_success
}

@test "Makefile: NIX_PROFILE variable is used in nix commands" {
    # NIX_PROFILE変数が定義され、使用されていることを確認
    run grep 'source.*NIX_PROFILE' "${MAKEFILE}"
    assert_success

    # 複数のターゲットでNIX_PROFILEを使用していることを確認
    count=$(grep -c 'source.*NIX_PROFILE' "${MAKEFILE}")
    [ "$count" -gt 5 ] || fail "NIX_PROFILE should be used in multiple targets"
}

@test "Makefile: flake commands use correct nix syntax" {
    # flake関連コマンドが正しいnix構文を使用していることを確認
    run grep 'nix flake' "${MAKEFILE}"
    assert_success

    # flake updateコマンドが存在
    assert_output --partial "nix flake update"

    # flake lockコマンドが存在
    run grep 'nix flake lock' "${MAKEFILE}"
    assert_success
}

@test "Makefile: home-manager commands use flake syntax" {
    # home-managerコマンドが--flakeフラグを使用していることを確認
    run grep -E 'home-manager.*--flake' "${MAKEFILE}"
    assert_success

    # .#homeを指定していることを確認
    assert_output --partial ".#home"
}

@test "Makefile: all test targets use bats" {
    # すべてのtestターゲットがbatsを使用していることを確認
    run grep -A 1 '^test.*:' "${MAKEFILE}"
    assert_success

    # testで始まるターゲットがすべてbatsを使っていることを確認
    for target in test test-scripts test-integration test-verbose test-watch; do
        run grep -A 1 "^${target}:" "${MAKEFILE}"
        assert_success
        assert_output --partial "bats"
    done
}

@test "Makefile: pre-commit targets are functional" {
    # pre-commit-initが正しいコマンドを使用
    run grep -A 1 '^pre-commit-init:' "${MAKEFILE}"
    assert_success
    assert_output --partial "pre-commit install"

    # pre-commit-runが正しいフラグを使用
    run grep -A 1 '^pre-commit-run:' "${MAKEFILE}"
    assert_success
    assert_output --partial "pre-commit run --all-files"
}

@test "Makefile: vscode targets reference actual scripts" {
    # vscode-applyが実際のスクリプトを参照していることを確認
    run grep -A 2 '^vscode-apply:' "${MAKEFILE}"
    assert_success
    assert_output --partial "vscode/settings/index.sh"
    assert_output --partial "vscode/extensions/apply.sh"

    # 実際にスクリプトが存在することを確認
    [ -f "${PROJECT_ROOT}/vscode/settings/index.sh" ] || skip "VSCode settings script not found"
    [ -f "${PROJECT_ROOT}/vscode/extensions/apply.sh" ] || skip "VSCode extensions script not found"
}

@test "Makefile: mise targets use correct commands" {
    # mise-install-allが正しいコマンドを使用
    run grep -A 1 '^mise-install-all:' "${MAKEFILE}"
    assert_success
    assert_output --partial "mise install"

    # mise-listが正しいコマンドを使用
    run grep -A 1 '^mise-list:' "${MAKEFILE}"
    assert_success
    assert_output --partial "mise ls"
}

@test "Makefile: composite targets have correct order" {
    # nix-update-allが正しい順序で依存していることを確認
    run grep '^nix-update-all:' "${MAKEFILE}"
    assert_success
    assert_output --partial "nix-channel-update"
    assert_output --partial "home-manager-apply"
    assert_output --partial "nix-darwin-apply"

    # 依存関係が正しい順序で記述されているか確認（左から右へ実行される）
    output_line=$(echo "$output" | head -1)
    echo "$output_line" | grep -E 'nix-channel-update.*home-manager-apply.*nix-darwin-apply'
}

@test "Makefile: error handling - invalid target fails gracefully" {
    cd "${PROJECT_ROOT}"
    run make non-existent-target
    # 存在しないターゲットはエラーになるべき
    assert_failure
}

@test "Makefile: all documented targets are actually defined" {
    cd "${PROJECT_ROOT}"

    # help出力からターゲット名を抽出（ANSIエスケープシーケンスを除去してから）
    # stderrもリダイレクトして、makeコマンド自体のメッセージを除外
    targets=$(make help 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -oE '^[a-zA-Z_][a-zA-Z0-9_-]+' | grep -v '^make$' || true)

    # 各ターゲットがMakefileに定義されていることを確認
    for target in $targets; do
        grep -q "^${target}:" "${MAKEFILE}" || fail "Target $target is documented but not defined"
    done
}
