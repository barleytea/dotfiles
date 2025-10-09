# Testing

このプロジェクトでは、bashスクリプトのテストに[bats-core](https://github.com/bats-core/bats-core)を使用しています。

## セットアップ

batsはNix devShellに含まれており、`nix develop`で自動的に利用可能になります。

```bash
# nix devShellに入る
nix develop

# batsが利用可能か確認
bats --version
```

## テストの実行

Makefileにテスト用のコマンドが用意されています。

### 全テストを実行

```bash
make test
```

### scripts/のテストのみ実行

```bash
make test-scripts
```

### 統合テストのみ実行

```bash
make test-integration
```

### 詳細モードで実行

```bash
make test-verbose
```

### watchモードで実行（開発時）

```bash
make test-watch
```

## テストの構造

```
tests/
├── test_helper/
│   └── test_helper.bash      # 共通ヘルパー関数
├── scripts/
│   ├── test_help.bats        # scripts/help.awkのテスト
│   └── test_home_manager_diff.bats  # scripts/home-manager-diff.shのテスト
└── integration/
    └── test_makefile.bats    # Makefileタスクのテスト
```

## テストの書き方

### 基本的なテストの例

```bash
#!/usr/bin/env bats

load '../test_helper/test_helper'

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "テストの説明" {
    run some_command
    assert_success
    assert_output "expected output"
}
```

### 利用可能なアサーション

bats-supportとbats-assertライブラリを使用しています。

- `assert_success` - コマンドが成功したことを確認
- `assert_failure` - コマンドが失敗したことを確認
- `assert_output` - 出力が期待通りであることを確認
- `assert_output --partial` - 出力に特定の文字列が含まれることを確認
- `refute_output` - 出力に特定の文字列が含まれないことを確認
- `assert_equal` - 2つの値が等しいことを確認

詳細は[bats-assert documentation](https://github.com/bats-core/bats-assert)を参照してください。

### ヘルパー関数

`tests/test_helper/test_helper.bash`に共通のヘルパー関数があります：

- `setup_test_env()` - テスト環境をセットアップ
- `teardown_test_env()` - テスト環境をクリーンアップ
- `create_mock_makefile()` - モックMakefileを作成
- `run_script(script_name, args...)` - scriptsディレクトリ内のスクリプトを実行
- `require_command(command)` - コマンドが利用可能でない場合はテストをスキップ

## CI/CD

GitHub Actionsで自動的にテストが実行されます。

`.github/workflows/main.yml`の`Run bats tests`ステップでテストが実行されます。

```yaml
- name: Run bats tests
  shell: zsh {0}
  run: |
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    nix develop --impure -c make test
```

## テストのカバレッジ

**現在のテスト数: 147テスト**

### scripts/ のテスト (56テスト)

#### `test_help.bats` (18テスト)
- 出力フォーマット、カラーコード、日本語対応
- カテゴリヘッダーの処理
- エッジケースの処理（空入力、特殊文字）
- **実際の動作確認**: 実際のMakefileでの動作、フォーマット一貫性

#### `test_home_manager_diff.bats` (38テスト)
- スクリプトの関数、ロジック、エラーハンドリング
- 環境変数(QUIET, SHOW_ALL)の動作
- **実際の動作確認**:
  - 一時ディレクトリの作成とクリーンアップ
  - 関数の実際の出力
  - commコマンドでの差分検出

### integration/ のテスト (91テスト)

#### `test_makefile.bats` (67テスト)
- Makefileタスクの存在、構文、依存関係、環境変数設定
- ターゲットの存在確認
- コマンドの正しさ（フラグ、引数）
- ターゲット間の依存関係
- カテゴリヘッダーの整合性
- **実際の動作確認**:
  - `make paths`の実行とPATH表示
  - `make help`の実行と出力確認
  - ドキュメント化されたターゲットの定義確認

#### `test_makefile_execution.bats` (24テスト)
**新規追加**: 安全に実行できるコマンドの実際の動作テスト
- `make paths`, `make help`の実際の実行
- mise関連コマンドの動作確認
- Nix flakeコマンドの実行（`check`, `show`, `metadata`）
- Git操作の確認
- 重要ファイルの存在確認
- スクリプトの実行可能性確認
- パフォーマンステスト（5秒以内にhelpが完了するか等）

#### `test_nix_operations.bats` (38テスト)
**新規追加**: Nix操作の実行テスト
- **Nix基本コマンド**:
  - `nix --version`
  - `nix flake metadata`, `show`, `check`
  - `nix eval`での式評価
- **Home Manager関連**:
  - 設定のビルド（dry-run）
  - 設定の評価
- **Flake入力の確認**:
  - nixpkgs, home-manager入力の存在
  - flake.lockの妥当性（JSON形式）
- **Nix Store操作**:
  - ストアへのアクセス
  - パス情報の取得
  - ディレクトリリスト
- **Darwin設定**: macOS特有の設定評価
- **パフォーマンステスト**: 各コマンドの実行時間
- **エラーハンドリング**: 不正な入力への対応
- **環境の健全性**: NIX_PATH、nix-daemonの確認

## テストのカテゴリ

### 1. 構文・構造テスト
ファイルやコマンドの構文、構造が正しいことを検証

### 2. 機能テスト
各関数やコマンドが期待通りに動作することを検証

### 3. 実行テスト ⭐ NEW
実際にコマンドを実行して動作を確認
- 安全な読み取り専用操作
- `--dry-run`や`--no-build`を使用
- タイムアウト保護付き

## ベストプラクティス

1. **各テストは独立させる**: テスト間で状態を共有しない
2. **setup/teardownを使う**: 各テストの前後で環境を適切にセットアップ/クリーンアップ
3. **明確なテスト名**: テストケース名は何をテストしているか明確に記述
4. **一つのテストで一つのこと**: 各テストは単一の機能をテスト
5. **モック/スタブを活用**: 外部依存を最小化
6. **構造テストと動作テスト**: Makefileなど設定ファイルは構造（存在、構文）と動作の両方をテスト

## トラブルシューティング

### batsが見つからない

```bash
# nix devShellに入っているか確認
nix develop

# またはフルパスで実行
nix develop --impure -c make test
```

### テストが失敗する

```bash
# 詳細モードで実行して詳細を確認
make test-verbose

# または個別のテストファイルを直接実行
bats tests/scripts/test_help.bats
```

### 一時ファイルが残る

テストで作成された一時ファイルは通常自動的にクリーンアップされますが、
手動で削除する場合：

```bash
find tests -name '.bats-tmp-*' -delete
find tests -name 'tmp' -type d -delete
```

## 参考リンク

- [bats-core](https://github.com/bats-core/bats-core)
- [bats-support](https://github.com/bats-core/bats-support)
- [bats-assert](https://github.com/bats-core/bats-assert)
- [bats-file](https://github.com/bats-core/bats-file)
