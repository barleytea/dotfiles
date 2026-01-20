# Zellij + gwq + fzf で Git Worktree を切り替える

git worktree を使って複数ブランチを並列で開発するためのワークフロー。
各 worktree ごとに zellij セッションを作成し、サクサク切り替えられる。

## 使い方

### キーバインド

zellij 内で以下のキーを押す：

1. **`Ctrl+o`** - Session モードに入る
2. **`g`** - Worktree Switcher を起動

フローティングウィンドウが開き、fzf でブランチを選択できる。

### ブランチリストの表示

fzf には以下の順番でブランチが表示される：

| マーク | 説明 |
|--------|------|
| ✨ | 新規ブランチを作成（一番上に表示） |
| 🌳 | 既存の worktree（すでに作成済み） |
| （なし） | ローカルブランチ |
| 🌐 | リモートブランチ（ローカルに未取得） |

### 新規ブランチの作成

1. `Ctrl+o g` で Worktree Switcher を起動
2. 一番上の `✨ [新規ブランチを作成]` を選択
3. 新しいブランチ名を入力
4. worktree が作成され、zellij セッションに切り替わる

### 動作の流れ

1. ブランチを選択
2. worktree が存在しなければ `gwq add` で自動作成
3. zellij セッションを作成（または既存セッションに切り替え）

セッション名は `リポジトリ名__ブランチ名` の形式になる。
例: `dotfiles__feature-new-feature`

### 関連キーバインド

| キー | 説明 |
|------|------|
| `Ctrl+o g` | Worktree Switcher（ブランチ選択 + セッション切り替え） |
| `Ctrl+o f` | Session Switcher（fzfでセッション切り替え） |
| `Ctrl+o w` | Session Manager（組み込みプラグイン） |
| `Ctrl+o d` | 現在のセッションから Detach |

## Session Switcher

`Ctrl+o s` でセッション一覧を fzf で表示し、素早く切り替えられる。

### 表示内容

| マーク | 説明 |
|--------|------|
| ✨ | 新規セッションを作成 |
| 📍 | 現在のセッション |
| 🔌 | 他のセッション |

## ユースケース

### Claude Code で並列開発

複数の機能を同時に Claude Code で開発したいとき：

1. `Ctrl+o g` で feature-A のブランチを選択 → Claude Code 起動
2. `Ctrl+o g` で feature-B のブランチを選択 → 別の Claude Code 起動
3. `Ctrl+o g` で行き来しながら両方の進捗を確認

### コードレビューしながら開発

1. main ブランチで開発中
2. `Ctrl+o g` でレビュー対象のブランチに切り替え
3. レビュー完了後、`Ctrl+o g` で main に戻る

## 関連ツール

- [gwq](https://github.com/d-kuro/gwq) - Git worktree をシンプルに管理
- [fzf](https://github.com/junegunn/fzf) - ファジーファインダー
- [zellij](https://zellij.dev/) - ターミナルマルチプレクサ

## 参考

- [tmux, gwq, fzfでworktreeをサクサク切り替えてAIコーディングを並列する](https://zenn.dev/ymat19/articles/9107170744368f)
