#!/usr/bin/env bash
#
# zellij-worktree-switcher.sh
# gwq + fzf + zellij でgit worktreeをサクサク切り替えるスクリプト
# 参考: https://zenn.dev/ymat19/articles/9107170744368f
#
# Usage:
#   zellij-worktree-switcher.sh          # 新しいペインで開く（デフォルト）
#   zellij-worktree-switcher.sh --pane   # 新しいペインで開く
#   zellij-worktree-switcher.sh --session # 新しいセッションで開く

set -euo pipefail

# オプション解析
OPEN_MODE="pane"  # デフォルトはペイン

while [[ $# -gt 0 ]]; do
    case $1 in
        --session|-s)
            OPEN_MODE="session"
            shift
            ;;
        --pane|-p)
            OPEN_MODE="pane"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--pane|-p|--session|-s]"
            exit 1
            ;;
    esac
done

# gitリポジトリ内にいるか確認
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not in a git repository"
    exit 1
fi

# リポジトリのルートディレクトリとリポジトリ名を取得
repo_root=$(git rev-parse --show-toplevel)
repo_name=$(basename "$repo_root")

# gwq listをJSONで取得してブランチ一覧を得る
get_worktree_branches() {
    gwq list --json 2>/dev/null | jq -r '.[].branch' || echo ""
}

# gwq listをJSONで取得してパスを得る
get_worktree_path() {
    local target_branch="$1"
    gwq list --json 2>/dev/null | jq -r --arg b "$target_branch" '.[] | select(.branch == $b) | .path'
}

# fzfに渡すブランチリストを生成
generate_branch_list() {
    # 新規ブランチ作成オプション
    echo "✨ [新規ブランチを作成]"

    # 既存worktreeのブランチ
    local worktree_branches
    worktree_branches=$(get_worktree_branches)
    if [ -n "$worktree_branches" ]; then
        echo "$worktree_branches" | while read -r b; do
            [ -n "$b" ] && echo "🌳 $b"
        done
    fi

    # ローカルブランチ（既存worktreeを除く）
    git branch --format='%(refname:short)' | while read -r b; do
        if ! echo "$worktree_branches" | grep -qx "$b"; then
            echo "$b"
        fi
    done

    # リモートブランチ（ローカルに存在しないもの）
    local local_branches
    local_branches=$(git branch --format='%(refname:short)')
    git branch -r --format='%(refname:short)' | grep -v 'HEAD' | sed 's|^origin/||' | while read -r b; do
        if ! echo "$local_branches" | grep -qx "$b" && ! echo "$worktree_branches" | grep -qx "$b"; then
            echo "🌐 $b"
        fi
    done
}

# fzfでブランチを選択
selected=$(generate_branch_list | fzf --prompt="Select branch > " --height=40% --reverse --border --ansi || true)

if [ -z "$selected" ]; then
    exit 0
fi

# 新規ブランチ作成が選択された場合
if [[ "$selected" == "✨ [新規ブランチを作成]" ]]; then
    echo -n "新しいブランチ名を入力: "
    read -r branch
    if [ -z "$branch" ]; then
        echo "ブランチ名が入力されませんでした"
        exit 1
    fi
    echo "Creating new branch and worktree: $branch"
    gwq add -b "$branch" || {
        echo "Failed to create branch: $branch"
        exit 1
    }
else
    # マークを除去してブランチ名を取得
    branch=$(echo "$selected" | sed 's/^🌳 //' | sed 's/^🌐 //')

    # worktreeが存在しなければ作成
    if ! get_worktree_branches | grep -qx "$branch"; then
        echo "Creating worktree for branch: $branch"
        gwq add "$branch" || {
            echo "Failed to create worktree. Creating new branch..."
            gwq add -b "$branch" || exit 1
        }
    fi
fi

# worktreeのパスを取得
worktree_path=$(get_worktree_path "$branch")

if [ -z "$worktree_path" ]; then
    echo "Error: Could not find worktree path for branch: $branch"
    exit 1
fi

# ブランチ名からセッション名を生成（/をハイフンに置換）
session_name="${repo_name}__${branch//\//-}"

echo "🔄 Switching to: $branch"
echo "📂 Worktree path: $worktree_path"

if [ "$OPEN_MODE" = "session" ]; then
    # セッションモード: 新しいセッションを作成or既存に切り替え
    echo "📦 Mode: New Session ($session_name)"
    zellij run --close-on-exit --name "switch-session" -- zellij attach --create "$session_name" options --default-cwd "$worktree_path"
else
    # ペインモード: 現在のセッション内に新しいペインを作成
    echo "📦 Mode: New Pane"
    zellij action new-pane --cwd "$worktree_path" --name "$branch" -- zsh
fi
