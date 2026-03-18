# kra Guide

kra はチケット駆動型ワークスペース管理CLIツール。
GitHub: https://github.com/tasuku43/kra

チケット（Issue/PR番号）をワークスペースと紐付け、複数の開発コンテキストを整理する。
cmuxとネイティブ統合があり、`kra ws open` でcmuxワークスペースが自動作成される。

## Installation

kra は Homebrew で管理済み（`darwin/homebrew/default.nix`）：

```nix
# darwin/homebrew/default.nix
taps = [
  "tasuku43/kra"
];
brews = [
  "kra"
];
```

nix-darwin 適用後に自動インストールされる：

```bash
make nix-darwin-apply
```

### 初期設定

```bash
# kra の初期化（~/.kra/ ディレクトリを作成）
kra init
```

## Directory Structure

```
~/.kra/
├── workspaces/          # アクティブなワークスペース
│   └── <ticket-id>/     # チケットごとのワークスペース
│       ├── .kra/        # kra メタデータ
│       └── <repos>/     # アタッチされたリポジトリ（git worktree）
└── archive/             # クローズしたワークスペース
```

## Core Commands

### ワークスペース管理

```bash
# ワークスペースを作成
kra ws create <ticket-id>

# ワークスペースを開く（cmuxワークスペース自動作成）
kra ws open <ticket-id>

# ワークスペース一覧
kra ws list

# ワークスペースをクローズ（archive/に移動）
kra ws close <ticket-id>

# クローズしたワークスペースを再オープン
kra ws reopen <ticket-id>
```

### リポジトリ管理

```bash
# ワークスペースにリポジトリをアタッチ（git worktree として追加）
kra ws add-repo <ticket-id> <repo-path>

# 例: 現在のリポジトリをワークスペースに追加
kra ws add-repo ISSUE-123 .
```

### タスク・ドキュメント管理

```bash
# タスクを追加
kra task add <ticket-id> "<task description>"

# タスク一覧
kra task list <ticket-id>

# タスクを完了
kra task done <ticket-id> <task-index>

# ドキュメントを追加
kra doc add <ticket-id> <file-path>

# ドキュメント一覧
kra doc list <ticket-id>
```

### その他

```bash
# kra バージョン確認
kra version

# ヘルプ
kra --help
kra ws --help
```

## Development Flow

### 典型的なチケット開発フロー

```
# 1. チケット番号でワークスペースを作成
kra ws create ISSUE-123

# 2. ワークスペースを開く（cmuxで自動的にワークスペース作成）
kra ws open ISSUE-123

# 3. 対象リポジトリをワークスペースにアタッチ
#    （git worktree として feature ブランチが作成される）
kra ws add-repo ISSUE-123 ~/git_repos/github.com/org/repo

# 4. cmux内でリポジトリペインに移動して開発開始
claude

# 5. 開発完了後、ワークスペースをクローズ
kra ws close ISSUE-123
```

### cmux統合

`kra ws open <ticket-id>` を実行すると、cmuxで自動的にワークスペースが作成される。
cmux側でチケットIDに対応したセッションが用意され、複数チケットの並行開発が可能。

- `/cmux-guide` スキル参照（cmuxの設定・使い方）

### Claude Codeとの統合

kraワークスペース内でClaude Codeを使う推奨フロー：

```
# 1. チケットのワークスペースを作成・開く
kra ws create ISSUE-123
kra ws open ISSUE-123

# 2. リポジトリをアタッチ（worktree でブランチが自動作成）
kra ws add-repo ISSUE-123 /path/to/repo

# 3. cmuxのリポジトリペインでClaude Codeを起動
cd ~/.kra/workspaces/ISSUE-123/<repo>
claude

# 4. Claude Codeセッション終了後、difit-cmux で差分確認
#    （Stop hookで自動トリガー、またはCtrl+Fで手動起動）

# 5. 変更をステージしてコミット
git add -p
# /generate-commit-msg でコミットメッセージ生成

# 6. PR作成後、ワークスペースをクローズ
kra ws close ISSUE-123
```

### zellij-worktreeとの違い

| 機能 | kra + cmux | zellij-worktree |
|------|-----------|-----------------|
| ターミナル | cmux (Ghostty) | Zellij |
| ワークスペース管理 | チケット単位で明示管理 | worktree 切り替えUI |
| 複数リポジトリ | ワークスペースに複数追加可 | 単一リポジトリ前提 |
| アーカイブ | archive/ に履歴保存 | worktree 削除のみ |

## Troubleshooting

### `kra: command not found`

```bash
# Homebrew のパスを確認
which kra

# brew でインストール確認
brew list | grep kra

# nix-darwin を再適用
make nix-darwin-apply
```

### `kra init` が失敗する

```bash
# ~/.kra/ ディレクトリの存在確認
ls -la ~/.kra/

# 権限確認
ls -la ~/ | grep .kra
```

### cmuxワークスペースが作成されない

cmux が Automation Mode になっているか確認：

1. cmux を開く
2. **Settings → Socket Control Mode** を確認
3. **Automation Mode** に切り替える

```bash
# cmux バイナリの確認
ls /Applications/cmux.app/Contents/Resources/bin/cmux
```

詳細は `/cmux-guide` スキルを参照。

### git worktree でエラーが発生する

```bash
# worktree の一覧確認
git worktree list

# 不要な worktree を削除
git worktree prune

# worktree のパスが正しいか確認
ls ~/.kra/workspaces/<ticket-id>/
```

## Configuration Files

kra の設定は `~/.kra/` 配下に自動生成される。
dotfiles での明示的な設定ファイル管理は現時点では不要。

## Related Skills

- `/cmux-guide` - cmux の設定・使い方、difit-cmux コマンド
- `/zellij-worktree` - Zellij を使った git worktree ワークフロー（cmux 非使用時）
