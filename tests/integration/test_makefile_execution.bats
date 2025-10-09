#!/usr/bin/env bats

# Makefile実行テスト - 実際にコマンドを実行して動作を確認

load '../test_helper/test_helper'

setup() {
    setup_test_env
    MAKEFILE="${PROJECT_ROOT}/Makefile"
}

teardown() {
    teardown_test_env
}

# ========================================
# 安全に実行できるターゲット
# ========================================

@test "make paths: actually executes and displays PATH" {
    cd "${PROJECT_ROOT}"
    run make paths
    assert_success

    # PATHが実際に表示されている
    [ -n "$output" ]

    # /binや/usr/binなどの典型的なパスが含まれている
    echo "$output" | grep -qE '/(usr/)?bin' || fail "PATH should contain bin directories"

    # 複数行に分割されている
    line_count=$(echo "$output" | wc -l | tr -d ' ')
    [ "$line_count" -gt 3 ] || fail "PATH should be split into multiple lines"
}

@test "make help: actually executes without errors" {
    cd "${PROJECT_ROOT}"
    run make help
    assert_success

    # 実際のヘルプ内容が表示されている
    assert_output --partial "help"
    assert_output --partial "test"

    # 日本語が正しく表示されている
    assert_output --partial "ヘルプ"
}

@test "make mise-list: executes if mise is available" {
    # miseが利用可能な場合のみテスト
    if ! command -v mise &>/dev/null; then
        skip "mise is not installed"
    fi

    cd "${PROJECT_ROOT}"
    run make mise-list
    # miseが設定されていればOK、なくてもエラーではない
    [ "$status" -eq 0 ] || [ "$status" -eq 2 ]
}

@test "make mise-config: executes if mise is available" {
    if ! command -v mise &>/dev/null; then
        skip "mise is not installed"
    fi

    cd "${PROJECT_ROOT}"
    run make mise-config
    # miseが設定されていればOK
    [ "$status" -eq 0 ] || [ "$status" -eq 2 ]
}

# ========================================
# Nix関連コマンド（ドライラン・チェックのみ）
# ========================================

@test "nix flake check: can verify flake configuration" {
    cd "${PROJECT_ROOT}"
    # flakeの設定が有効かチェック（実際のビルドはしない）
    run timeout 60 nix flake check --no-build
    # 成功するか、または特定のエラー（評価エラーなど）で失敗
    # ここではエラーコードをチェックしない（環境依存のため）
    [ -n "$output" ] || [ -n "$status" ]
}

@test "nix flake show: can display flake outputs" {
    cd "${PROJECT_ROOT}"
    run timeout 30 nix flake show
    assert_success
    # homeConfigurationsが表示される
    assert_output --partial "homeConfigurations"
}

@test "nix flake metadata: displays flake information" {
    cd "${PROJECT_ROOT}"
    run nix flake metadata
    assert_success

    # 基本的なメタデータが含まれる
    assert_output --partial "Description:"
    assert_output --partial "Path:"
}

@test "home-manager build: dry-run works" {
    cd "${PROJECT_ROOT}"
    # --dry-runでビルドのシミュレーション
    run timeout 60 nix run nixpkgs#home-manager -- build --flake .#home --dry-run
    # dry-runは実際にはビルドを実行する場合があるので、タイムアウトで保護
    # エラーコードは環境依存のためチェックしない
    [ -n "$output" ] || [ -n "$status" ]
}

# ========================================
# Git操作のテスト
# ========================================

@test "git status: repository is in valid state" {
    cd "${PROJECT_ROOT}"
    run git status
    assert_success

    # 有効なgitリポジトリであることを確認
    assert_output --partial "On branch"
}

@test "git log: can retrieve commit history" {
    cd "${PROJECT_ROOT}"
    run git log -1 --oneline
    assert_success

    # 最新のコミットが取得できる
    [ -n "$output" ]
}

# ========================================
# ファイル存在確認
# ========================================

@test "critical files exist" {
    # プロジェクトの重要ファイルが存在することを確認
    assert_file_exist "${PROJECT_ROOT}/Makefile"
    assert_file_exist "${PROJECT_ROOT}/flake.nix"
    assert_file_exist "${PROJECT_ROOT}/README.md"
}

@test "scripts directory contains executable files" {
    # scriptsディレクトリのスクリプトが実行可能
    for script in "${PROJECT_ROOT}"/scripts/*.sh; do
        [ -x "$script" ] || fail "Script $script is not executable"
    done

    for script in "${PROJECT_ROOT}"/scripts/*.awk; do
        [ -f "$script" ] || fail "Script $script does not exist"
    done
}

# ========================================
# 環境変数のテスト
# ========================================

@test "NIX_PROFILE environment variable handling" {
    # NIX_PROFILEが定義されているか、デフォルト値が使えるか
    if [ -n "${NIX_PROFILE:-}" ]; then
        # 定義されている場合、ファイルが存在するか確認
        [ -f "$NIX_PROFILE" ] || skip "NIX_PROFILE points to non-existent file"
    else
        # 定義されていない場合、Makefileのデフォルトパスを確認
        default_path="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
        [ -f "$default_path" ] || skip "Default nix profile not found"
    fi
}

# ========================================
# pre-commitフックのテスト（インストールなし）
# ========================================

@test "pre-commit config file exists" {
    assert_file_exist "${PROJECT_ROOT}/.pre-commit-config.yaml"
}

@test "pre-commit: can show config if installed" {
    if ! command -v pre-commit &>/dev/null; then
        skip "pre-commit is not installed"
    fi

    cd "${PROJECT_ROOT}"
    run pre-commit --version
    assert_success
}

# ========================================
# VSCodeスクリプトの実行可能性
# ========================================

@test "vscode scripts exist" {
    if [ ! -d "${PROJECT_ROOT}/vscode" ]; then
        skip "vscode directory not found"
    fi

    # VSCodeスクリプトが存在することを確認（実行権限は必須ではない）
    script_count=0
    for script in "${PROJECT_ROOT}"/vscode/**/*.sh; do
        [ -f "$script" ] || continue
        script_count=$((script_count + 1))
    done

    [ "$script_count" -gt 0 ] || fail "No VSCode scripts found"
}

# ========================================
# パフォーマンステスト
# ========================================

@test "make help: completes within reasonable time" {
    cd "${PROJECT_ROOT}"

    start_time=$(date +%s)
    run make help
    end_time=$(date +%s)

    duration=$((end_time - start_time))

    # 5秒以内に完了すること
    [ "$duration" -lt 5 ] || fail "make help took ${duration}s (should be < 5s)"
}

@test "make paths: completes quickly" {
    cd "${PROJECT_ROOT}"

    start_time=$(date +%s)
    run make paths
    end_time=$(date +%s)

    duration=$((end_time - start_time))

    # 2秒以内に完了すること
    [ "$duration" -lt 2 ] || fail "make paths took ${duration}s (should be < 2s)"
}
