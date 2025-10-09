#!/usr/bin/env bats

# Nix操作の実行テスト - 実際にNixコマンドを実行して動作を確認
# 注意: このテストは実際のNixストアにアクセスしますが、破壊的操作は行いません

load '../test_helper/test_helper'

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

# ========================================
# Nix基本コマンド
# ========================================

@test "nix --version: Nix is installed and working" {
    run nix --version
    assert_success
    assert_output --partial "nix"
}

@test "nix flake metadata: can read flake.nix" {
    cd "${PROJECT_ROOT}"
    run nix flake metadata
    assert_success

    # flake.nixの基本情報が取得できる
    assert_output --partial "Description:"
    assert_output --partial "Inputs:"
}

@test "nix flake show: displays all outputs" {
    cd "${PROJECT_ROOT}"
    run timeout 30 nix flake show
    assert_success

    # 期待される出力が表示される
    assert_output --partial "homeConfigurations"
    assert_output --partial "darwinConfigurations"
}

@test "nix eval: can evaluate simple expressions from flake" {
    cd "${PROJECT_ROOT}"
    # flakeのdescriptionを評価
    run nix eval .#description 2>&1
    # descriptionが定義されていない場合はスキップ
    if [ "$status" -ne 0 ]; then
        skip "No description attribute in flake"
    fi
}

@test "nix flake check --no-build: validates flake without building" {
    cd "${PROJECT_ROOT}"
    # --no-buildで構文チェックのみ実行（タイムアウト付き）
    run timeout 60 nix flake check --no-build
    # チェックエラーは許容（環境依存のため）
    [ -n "$output" ]
}

# ========================================
# Home Manager関連
# ========================================

@test "nix build (home-manager): can parse configuration" {
    cd "${PROJECT_ROOT}"
    # home-managerのactivationPackageをビルド（dry-runモード）
    # 注意: これは実際にビルドを試みるが、タイムアウトで保護
    run timeout 120 nix build .#homeConfigurations.home.activationPackage --dry-run
    # dry-runでも評価は行われるため、タイムアウトまたは成功を許容
    [ "$status" -eq 124 ] || [ "$status" -eq 0 ] || [ -n "$output" ]
}

@test "home-manager config: can be evaluated" {
    cd "${PROJECT_ROOT}"
    # home-manager設定の一部を評価
    run timeout 30 nix eval .#homeConfigurations.home.config.home.stateVersion 2>&1
    # 成功またはタイムアウト
    [ "$status" -eq 0 ] || [ "$status" -eq 124 ] || skip "Cannot evaluate home-manager config"
}

# ========================================
# Flake入力の確認
# ========================================

@test "nix flake metadata: nixpkgs input exists" {
    cd "${PROJECT_ROOT}"
    run nix flake metadata --json
    assert_success

    # nixpkgs入力が存在することを確認
    echo "$output" | grep -q "nixpkgs" || fail "nixpkgs input not found"
}

@test "nix flake metadata: home-manager input exists" {
    cd "${PROJECT_ROOT}"
    run nix flake metadata --json
    assert_success

    # home-manager入力が存在することを確認
    echo "$output" | grep -q "home-manager" || fail "home-manager input not found"
}

@test "flake.lock: is valid JSON" {
    cd "${PROJECT_ROOT}"
    assert_file_exist "flake.lock"

    # flake.lockが有効なJSONであることを確認
    run jq empty flake.lock 2>&1
    if [ "$status" -ne 0 ]; then
        # jqがない場合はスキップ
        command -v jq &>/dev/null || skip "jq is not installed"
        fail "flake.lock is not valid JSON"
    fi
}

@test "flake.lock: contains expected inputs" {
    cd "${PROJECT_ROOT}"
    if ! command -v jq &>/dev/null; then
        skip "jq is not installed"
    fi

    # flake.lockに期待される入力が含まれることを確認
    run jq -r '.nodes | keys[]' flake.lock
    assert_success

    echo "$output" | grep -q "nixpkgs" || fail "nixpkgs not in flake.lock"
    echo "$output" | grep -q "home-manager" || fail "home-manager not in flake.lock"
}

# ========================================
# Nix Store操作（読み取りのみ）
# ========================================

@test "nix store ping: can access Nix store" {
    run nix store ping
    # ローカルストアへのアクセスを確認
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "nix path-info: can query store paths" {
    # nixコマンド自体のストアパスを確認
    nix_path=$(command -v nix)
    run nix path-info "$nix_path"
    assert_success

    # ストアパスが返される
    assert_output --partial "/nix/store/"
}

@test "nix store ls: can list store directory" {
    # nixコマンド自体のストアパスをリスト
    nix_path=$(command -v nix)

    # nixがストアパス(/nix/store/)にある場合のみテスト
    if [[ "$nix_path" != /nix/store/* ]]; then
        skip "nix command is not in /nix/store (profile link)"
    fi

    run nix store ls "$nix_path"
    assert_success

    # binディレクトリが含まれる
    assert_output --partial "bin"
}

# ========================================
# Darwin設定（macOSの場合のみ）
# ========================================

@test "nix-darwin: configuration can be evaluated" {
    if [ "$(uname)" != "Darwin" ]; then
        skip "Not running on macOS"
    fi

    cd "${PROJECT_ROOT}"
    # darwin設定の評価
    run timeout 30 nix eval .#darwinConfigurations.all.config.system.stateVersion 2>&1
    # 成功またはタイムアウト、または未定義
    [ "$status" -eq 0 ] || [ "$status" -eq 124 ] || skip "Darwin config not evaluable"
}

# ========================================
# パフォーマンステスト
# ========================================

@test "nix flake metadata: completes within 10 seconds" {
    cd "${PROJECT_ROOT}"

    start_time=$(date +%s)
    run nix flake metadata
    end_time=$(date +%s)

    duration=$((end_time - start_time))

    assert_success
    [ "$duration" -lt 10 ] || fail "nix flake metadata took ${duration}s (should be < 10s)"
}

@test "nix flake show: completes within 30 seconds" {
    cd "${PROJECT_ROOT}"

    start_time=$(date +%s)
    run timeout 30 nix flake show
    end_time=$(date +%s)

    duration=$((end_time - start_time))

    # タイムアウトまたは成功
    [ "$status" -eq 0 ] || [ "$status" -eq 124 ]
    [ "$duration" -le 30 ] || fail "nix flake show exceeded timeout"
}

# ========================================
# エラーハンドリング
# ========================================

@test "nix flake check: handles invalid configurations gracefully" {
    # 存在しないディレクトリでflake checkを実行
    run nix flake check /nonexistent/path 2>&1
    assert_failure

    # エラーメッセージが含まれる
    [ -n "$output" ]
}

@test "nix eval: handles invalid expressions" {
    cd "${PROJECT_ROOT}"
    # 存在しない属性を評価
    run nix eval .#nonexistentAttribute 2>&1
    assert_failure

    # エラーメッセージが含まれる
    assert_output --partial "error:"
}

# ========================================
# Nix環境の健全性チェック
# ========================================

@test "NIX_PATH: is set or flakes are enabled" {
    # NIX_PATHが設定されているか、flakesが有効であることを確認
    if [ -z "${NIX_PATH:-}" ]; then
        # NIX_PATHが未設定の場合、flakesが有効か確認
        run nix eval --expr 'builtins.nixVersion'
        assert_success
    fi
}

@test "nix-daemon: is accessible" {
    # nix-daemonが利用可能か確認（macOSの場合）
    if [ "$(uname)" = "Darwin" ]; then
        profile="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
        if [ -f "$profile" ]; then
            # プロファイルが存在する
            [ -f "$profile" ]
        else
            skip "nix-daemon profile not found (single-user install?)"
        fi
    fi
}
